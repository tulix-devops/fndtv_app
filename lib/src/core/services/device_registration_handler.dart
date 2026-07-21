import 'dart:math';

import 'package:app_logger/app_logger.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:fndtv/src/core/services/device_identity_service.dart';
import 'package:fndtv/src/data/data_sources/device/device_data_source.dart';
import 'package:fndtv/src/data/models/device/device_checkin_model.dart';
import 'package:fndtv/src/data/repositories/device/device_repository.dart';
import 'package:local_storage/local_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Reads the set-top box identity (serial number, Wi-Fi MAC, OS version) and
/// registers it with the box provisioning backend on app initialization, then
/// checks in if the box holds a provisioning-minted device token.
///
/// Designed to be called fire-and-forget from the splash screen: it never
/// throws, logs every step, and only registers once per serial (a 201 or a 409
/// "already registered" both mark it done, so it won't re-POST on later
/// launches).
class DeviceRegistrationHandler {
  DeviceRegistrationHandler({
    required DeviceIdentityService deviceIdentityService,
    required DeviceRepository deviceRepository,
    required LocalStorage localStorage,
  })  : _identity = deviceIdentityService,
        _repo = deviceRepository,
        _storage = localStorage;

  final DeviceIdentityService _identity;
  final DeviceRepository _repo;
  final LocalStorage _storage;

  static const String _registeredSerialKey = 'stb_registered_serial';

  /// Persisted unique debug MAC (see [_debugUniqueMac]).
  static const String _debugMacKey = 'stb_debug_mac';

  /// The anonymized MAC modern Android hands to apps without the privileged
  /// permission. It is the SAME for every device, so — like an empty value — it
  /// collides on the backend (which dedupes devices by MAC).
  static const String _anonymizedMac = '02:00:00:00:00:00';

  Future<void> registerOnInit() async {
    await _registerIfNeeded();
    await _checkinIfProvisioned();
  }

  /// Interim self-registration (operator-authorised). Per the Box API design,
  /// registration is a warehouse action and boxes should instead arrive with a
  /// device token — this stays until that provisioning flow exists.
  Future<void> _registerIfNeeded() async {
    try {
      final serial = await _identity.getSerialNumber();
      if (serial.isEmpty) {
        logger.w('[STB] No serial number available; skipping registration.');
        return;
      }

      // Already registered this exact serial — nothing to do.
      final registered = await _storage.get<String>(_registeredSerialKey);
      if (registered == serial) {
        logger.d('[STB] Serial already registered; skipping.');
        return;
      }

      var macWifi = await _identity.getWifiMac();
      final osVersion = await _identity.getOsVersion();

      // Emulators / debug builds can't expose a real, unique Wi-Fi MAC (privacy
      // randomization returns an empty or anonymized value). The backend dedupes
      // devices by MAC, so a shared placeholder makes every debug install after
      // the first collide (409 DEVICE_EXISTS) and never obtain a device_id —
      // which breaks update checks. Use a MAC generated once per install and
      // persisted. Release builds on real boxes keep sending the real hardware
      // MAC read natively.
      if (kDebugMode &&
          (macWifi.isEmpty || macWifi.toLowerCase() == _anonymizedMac)) {
        macWifi = await _debugUniqueMac();
        logger.w('[STB] Debug unique MAC used: $macWifi');
      }

      logger.i(
        '[STB] Registering — serial: $serial, mac: $macWifi, os: $osVersion',
      );

      final result = await _repo.registerSetTopBox(
        serialNumber: serial,
        macWifi: macWifi,
        osVersion: osVersion,
      );

      switch (result.status) {
        case DeviceRegisterResult.registered:
        case DeviceRegisterResult.alreadyRegistered:
          await _storage.store<String>(_registeredSerialKey, serial);
          if (result.deviceId != null) {
            await _storage.store<String>(kStbDeviceIdKey, result.deviceId!);
            logger.i('[STB] Device id stored: ${result.deviceId}');
          }
          logger.i('[STB] Registration done (${result.status}).');
        case DeviceRegisterResult.failed:
          logger.w('[STB] Registration failed; will retry next launch.');
      }
    } catch (e, st) {
      logger.e('[STB] Registration handler error: $e', stacktrace: st);
    }
  }

  /// Runtime heartbeat (`POST /device/checkin`) — reports installed version and
  /// identity, and surfaces pending MDM commands. Runs only when a
  /// provisioning-minted device token is present in storage; silently skipped
  /// otherwise (self-registered boxes have no token yet).
  ///
  /// Command execution/ack is not wired yet — pending commands are only
  /// logged; the backend redelivers them until acked.
  Future<void> _checkinIfProvisioned() async {
    try {
      final token = await _storage.get<String>(kStbDeviceTokenKey);
      if (token == null || token.isEmpty) {
        logger.d('[STB] No device token; skipping check-in.');
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final result = await _repo.checkin(
        deviceToken: token,
        macAddress: await _identity.getWifiMac(),
        installedAppVersion: packageInfo.version,
        deviceModel: await _identity.getDeviceModel(),
        osVersion: await _identity.getOsVersion(),
      );

      switch (result.status) {
        case DeviceCheckinStatus.success:
          final model = result.model!;
          logger.i(
            '[STB] Check-in ok — latest v${model.latestAppVersion}, '
            '${model.commands.length} pending command(s)'
            '${model.commands.isEmpty ? '' : ': ${model.commands.map((c) => c.type).join(', ')}'}',
          );
        case DeviceCheckinStatus.unauthorized:
        case DeviceCheckinStatus.unassigned:
        case DeviceCheckinStatus.suspended:
        case DeviceCheckinStatus.failed:
          logger.w('[STB] Check-in not accepted: ${result.status}.');
      }
    } catch (e, st) {
      logger.e('[STB] Check-in handler error: $e', stacktrace: st);
    }
  }

  /// Returns a unique, stable, locally-administered MAC for this install,
  /// generating it once and persisting it so it survives relaunches. Used only
  /// in debug builds where the platform can't supply a real, unique MAC.
  Future<String> _debugUniqueMac() async {
    final existing = await _storage.get<String>(_debugMacKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final rnd = Random.secure();
    // First octet 0x02 = locally-administered + unicast; remaining 5 random.
    final octets = <String>['02'];
    for (var i = 0; i < 5; i++) {
      octets.add(rnd.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    final mac = octets.join(':').toUpperCase();
    await _storage.store<String>(_debugMacKey, mac);
    return mac;
  }
}
