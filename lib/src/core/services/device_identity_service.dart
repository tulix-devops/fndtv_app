import 'dart:io';
import 'dart:math';

import 'package:app_logger/app_logger.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:fndtv/src/data/repositories/device/device_repository.dart'
    show kStbDeviceKeyKey;
import 'package:local_storage/local_storage.dart';

/// Reads the device identity fields needed to register a set-top box:
/// hardware serial number, Wi-Fi MAC address, and OS version.
///
/// Serial and MAC come from a native platform channel (`Build.getSerial()` /
/// interface address — see `MainActivity.kt`), which is the reliable path on a
/// set-top box, with `device_info_plus` fallbacks so callers always get a
/// best-effort value.
class DeviceIdentityService {
  static const MethodChannel _channel =
      MethodChannel('com.fndtv.videoplayer/device');

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  String? _cachedSerial;
  String? _cachedMac;
  String? _cachedAndroidId;

  /// Last-resort discriminator, used only where SSAID is unavailable.
  static const String _generatedDiscriminatorKey = 'stb_generated_discriminator';

  /// Hardware serial number, or an empty string if none could be read.
  Future<String> getSerialNumber() async {
    if (_cachedSerial != null && _cachedSerial!.isNotEmpty) {
      return _cachedSerial!;
    }

    var serial = '';

    if (Platform.isAndroid) {
      try {
        final native = await _channel.invokeMethod<String?>('getSerialNumber');
        if (native != null && native.isNotEmpty) serial = native;
      } catch (e) {
        logger.w('[STB] Native serial read failed: $e');
      }
    }

    if (serial.isEmpty) {
      try {
        if (Platform.isAndroid) {
          final info = await _deviceInfo.androidInfo;
          final s = info.serialNumber;
          serial = (s.isNotEmpty && s.toLowerCase() != 'unknown') ? s : info.id;
        } else if (Platform.isIOS) {
          final info = await _deviceInfo.iosInfo;
          serial = info.identifierForVendor ?? '';
        }
      } catch (e) {
        logger.w('[STB] device_info serial fallback failed: $e');
      }
    }

    _cachedSerial = serial;
    return serial;
  }

  /// The identity this box presents to the backend, and shows on screen.
  ///
  /// `<serial>-<discriminator>`, e.g. `BT2A.260319.001-F651D372`.
  ///
  /// The factory serial is NOT unique on these boxes — batches ship with the
  /// SoC vendor's default `ro.serialno`, so several report the same string and
  /// collapse onto one record on the backend: check-ins overwrite each other,
  /// MDM commands reach the wrong box, and a single subscriber assignment
  /// covers them all. Composing an identity we control fixes that without
  /// waiting on a firmware change we do not own.
  ///
  /// The discriminator is the Android SSAID, chosen for its lifetime: scoped to
  /// our signing key, it survives an app uninstall/reinstall or "clear data"
  /// and resets only on a factory reset — verified by reinstalling and getting
  /// the same key back. A value we generated and stored would NOT survive that:
  /// Hive lives in app data, so a QA sideload would mint a new identity and
  /// orphan the box's record. The random fallback applies only where SSAID is
  /// unavailable, and is the one path a reinstall can change.
  ///
  /// Lives here rather than on the registration handler so the identity screen
  /// can show the same value without waiting for a provision to have run — it
  /// is computed on demand and cached, not a side effect of registering.
  Future<String> resolveDeviceKey(LocalStorage storage) async {
    try {
      final cached = await storage.get<String>(kStbDeviceKeyKey);
      if (cached != null && cached.isNotEmpty) return cached;
    } catch (e) {
      // Storage not ready yet (first frame). Fall through and recompute — the
      // inputs are stable, so this yields the same string either way.
      logger.w('[STB] Device key cache unreadable: $e');
    }

    final serial = await getSerialNumber();
    var discriminator = await getAndroidId();
    if (discriminator.isEmpty) {
      logger.w('[STB] No android_id — falling back to a generated id, which '
          'does NOT survive a reinstall.');
      discriminator = await _generatedDiscriminator(storage);
    }

    final suffix = discriminator
        .replaceAll(RegExp(r'[^0-9a-zA-Z]'), '')
        .toUpperCase()
        .padRight(8, '0')
        .substring(0, 8);
    final key = serial.isEmpty ? suffix : '$serial-$suffix';

    try {
      await storage.store<String>(kStbDeviceKeyKey, key);
    } catch (_) {
      // Cache is an optimisation, not the source of truth.
    }
    logger.i('[STB] Device key: $key');
    return key;
  }

  Future<String> _generatedDiscriminator(LocalStorage storage) async {
    try {
      final existing = await storage.get<String>(_generatedDiscriminatorKey);
      if (existing != null && existing.isNotEmpty) return existing;
    } catch (_) {}

    final rnd = Random.secure();
    final value = List.generate(
      8,
      (_) => rnd.nextInt(16).toRadixString(16),
    ).join().toUpperCase();
    try {
      await storage.store<String>(_generatedDiscriminatorKey, value);
    } catch (_) {}
    return value;
  }

  /// Android SSAID, or empty if unavailable.
  ///
  /// The discriminator for boxes that share a factory serial. Survives an app
  /// reinstall or "clear data" and resets only on a factory reset, which is why
  /// it is preferred over anything we could generate and store ourselves.
  Future<String> getAndroidId() async {
    if (_cachedAndroidId != null && _cachedAndroidId!.isNotEmpty) {
      return _cachedAndroidId!;
    }

    var id = '';
    if (Platform.isAndroid) {
      try {
        final native = await _channel.invokeMethod<String?>('getAndroidId');
        if (native != null && native.isNotEmpty) id = native;
      } catch (e) {
        logger.w('[STB] Native android_id read failed: $e');
      }
    }

    _cachedAndroidId = id;
    return id;
  }

  /// Wi-Fi MAC address (upper-case, colon-separated), or empty if unavailable.
  Future<String> getWifiMac() async {
    if (_cachedMac != null && _cachedMac!.isNotEmpty) return _cachedMac!;

    var mac = '';
    if (Platform.isAndroid) {
      try {
        final native = await _channel.invokeMethod<String?>('getWifiMac');
        if (native != null && native.isNotEmpty) mac = native;
      } catch (e) {
        logger.w('[STB] Native MAC read failed: $e');
      }
    }

    _cachedMac = mac;
    return mac;
  }

  /// Marketing device model, e.g. `X88 Pro 14`, or empty if unavailable.
  Future<String> getDeviceModel() async {
    try {
      if (Platform.isAndroid) {
        return (await _deviceInfo.androidInfo).model;
      } else if (Platform.isIOS) {
        return (await _deviceInfo.iosInfo).utsname.machine;
      }
    } catch (e) {
      logger.w('[STB] Device model read failed: $e');
    }
    return '';
  }

  /// OS version string, e.g. `Android 13`.
  Future<String> getOsVersion() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return 'Android ${info.version.release}';
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return 'iOS ${info.systemVersion}';
      }
    } catch (e) {
      logger.w('[STB] OS version read failed: $e');
    }
    return '';
  }
}
