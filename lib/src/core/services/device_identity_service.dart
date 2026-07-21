import 'dart:io';

import 'package:app_logger/app_logger.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

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
