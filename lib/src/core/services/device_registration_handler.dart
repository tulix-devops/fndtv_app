import 'dart:math';

import 'package:app_logger/app_logger.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:fndtv/src/core/services/device_identity_service.dart';
import 'package:fndtv/src/data/data_sources/device/device_data_source.dart';
import 'package:fndtv/src/data/models/device/device_checkin_model.dart';
import 'package:fndtv/src/data/repositories/device/device_repository.dart';
import 'package:local_storage/local_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Self-provisions the set-top box (`POST /api/provision`) on app init — the box
/// posts its hardware identity with the scoped API key and receives its
/// per-device token, which is stored and then used to check in.
///
/// Designed to be called fire-and-forget from the splash screen: it never
/// throws, logs every step, and only provisions once (skips when a device token
/// is already stored — provisioning is idempotent anyway).
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

  /// Persisted unique debug MAC (see [_debugUniqueMac]).
  static const String _debugMacKey = 'stb_debug_mac';

  /// The anonymized MAC modern Android hands to apps without the privileged
  /// permission. It is the SAME for every device, so — like an empty value — it
  /// collides on the backend (which dedupes devices by MAC).
  static const String _anonymizedMac = '02:00:00:00:00:00';

  Future<void> registerOnInit() async {
    await _provisionIfNeeded();
    await _checkinIfProvisioned();
  }

  /// Self-provisions the box via `POST /api/provision` (scoped API key) and
  /// stores the returned device token + id. Skips when a token is already
  /// present. Idempotent server-side, so a retry after a partial failure is
  /// safe.
  Future<void> _provisionIfNeeded() async {
    try {
      // Already have a device token — provisioned; nothing to do.
      final existingToken = await _storage.get<String>(kStbDeviceTokenKey);
      if (existingToken != null && existingToken.isNotEmpty) {
        logger.d('[STB] Device token present; skipping provisioning.');
        return;
      }

      final serial = await _identity.getSerialNumber();
      if (serial.isEmpty) {
        logger.w('[STB] No serial number available; skipping provisioning.');
        return;
      }

      var macWifi = await _identity.getWifiMac();
      final osVersion = await _identity.getOsVersion();
      final model = await _identity.getDeviceModel();

      // Emulators / debug builds can't expose a real, unique Wi-Fi MAC (privacy
      // randomization returns an empty or anonymized value). Provisioning
      // dedupes by hardware, so a shared placeholder collides. Use a MAC
      // generated once per install and persisted. Release builds on real boxes
      // send the real hardware MAC read natively.
      if (kDebugMode &&
          (macWifi.isEmpty || macWifi.toLowerCase() == _anonymizedMac)) {
        macWifi = await _debugUniqueMac();
        logger.w('[STB] Debug unique MAC used: $macWifi');
      }

      logger.i(
        '[STB] Provisioning — serial: $serial, mac: $macWifi, model: $model, '
        'os: $osVersion',
      );

      final result = await _repo.provisionDevice(
        serialNumber: serial,
        macWifi: macWifi,
        model: model,
        osVersion: osVersion,
      );

      switch (result.status) {
        case ProvisionStatus.provisioned:
          final token = result.deviceToken;
          if (token != null && token.isNotEmpty) {
            await _storage.store<String>(kStbDeviceTokenKey, token);
            logger.i('[STB] Device token stored — check-in enabled.');
          } else {
            logger.w('[STB] Provisioned but no device_token in the response — '
                'verify the 201 field names against the backend.');
          }
          if (result.deviceId != null) {
            await _storage.store<String>(kStbDeviceIdKey, result.deviceId!);
            logger.i('[STB] Device id stored: ${result.deviceId}');
          }
        case ProvisionStatus.unauthorized:
        case ProvisionStatus.forbidden:
        case ProvisionStatus.failed:
          logger.w('[STB] Provisioning not completed (${result.status}); '
              'will retry next launch.');
      }
    } catch (e, st) {
      logger.e('[STB] Provisioning handler error: $e', stacktrace: st);
    }
  }

  /// Runtime heartbeat (`POST /device/checkin`) — reports installed version and
  /// identity, and surfaces pending MDM commands. Runs only when a
  /// provisioning-minted device token is present in storage; silently skipped
  /// otherwise (an un-provisioned box has no token yet).
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
          // Token rejected — drop it so the box re-provisions next launch.
          await _storage.store<String>(kStbDeviceTokenKey, '');
          logger.w('[STB] Check-in token rejected — cleared; will re-provision.');
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
