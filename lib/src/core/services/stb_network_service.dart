import 'package:app_logger/app_logger.dart';
import 'package:flutter/services.dart';
import 'package:fndtv/src/core/services/stb_system_service.dart' show StbSystemService;

/// A Wi-Fi network found by a scan. [level] is 1 (weak) – 4 (strong).
class WifiNetwork {
  final String ssid;
  final bool secured;
  final int level;

  const WifiNetwork({required this.ssid, required this.secured, required this.level});

  factory WifiNetwork.fromMap(Map<Object?, Object?> map) {
    final rssi = (map['rssi'] as int?) ?? -100;
    return WifiNetwork(
      ssid: (map['ssid'] as String?) ?? '',
      secured: (map['secured'] as bool?) ?? false,
      level: _bucket(rssi),
    );
  }

  static int _bucket(int rssi) {
    if (rssi >= -60) return 4;
    if (rssi >= -73) return 3;
    if (rssi >= -85) return 2;
    return 1;
  }
}

/// Snapshot of the box's link state (both interfaces).
class StbNetworkStatus {
  final bool wifiEnabled;
  final String? ssid;
  final String? wifiIp;
  final bool ethernetLinked;
  final String? ethernetIp;

  const StbNetworkStatus({
    required this.wifiEnabled,
    required this.ssid,
    required this.wifiIp,
    required this.ethernetLinked,
    required this.ethernetIp,
  });

  factory StbNetworkStatus.fromMaps({
    Map<Object?, Object?>? wifi,
    Map<Object?, Object?>? ethernet,
  }) =>
      StbNetworkStatus(
        wifiEnabled: (wifi?['enabled'] as bool?) ?? false,
        ssid: wifi?['ssid'] as String?,
        wifiIp: wifi?['ip'] as String?,
        ethernetLinked: (ethernet?['linked'] as bool?) ?? false,
        ethernetIp: ethernet?['ip'] as String?,
      );
}

/// Dart face of the StbBridge network methods. Fail-soft like
/// [StbSystemService]: every call is stb-gated, logs failures, never throws.
/// Methods are non-final so tests can fake by overriding.
class StbNetworkService {
  static const MethodChannel _channel = MethodChannel('com.fndtv.videoplayer/stb');

  Future<StbNetworkStatus> status() async {
    if (!StbSystemService.isStb) return StbNetworkStatus.fromMaps();
    try {
      final wifi = await _channel.invokeMethod<Map<Object?, Object?>>('wifiStatus');
      final eth = await _channel.invokeMethod<Map<Object?, Object?>>('ethernetStatus');
      return StbNetworkStatus.fromMaps(wifi: wifi, ethernet: eth);
    } catch (e) {
      logger.w('[STB] network status failed: $e');
      return StbNetworkStatus.fromMaps();
    }
  }

  Future<List<WifiNetwork>> scan() async {
    if (!StbSystemService.isStb) return const [];
    try {
      final res = await _channel.invokeMethod<List<Object?>>('scanWifi');
      return res
              ?.whereType<Map<Object?, Object?>>()
              .map(WifiNetwork.fromMap)
              .where((n) => n.ssid.isNotEmpty)
              .toList() ??
          const [];
    } catch (e) {
      logger.w('[STB] scanWifi failed: $e');
      return const [];
    }
  }

  /// Initiates a join; the outcome is observed by polling [status].
  Future<bool> connect(String ssid, {String? password}) async {
    if (!StbSystemService.isStb) return false;
    try {
      return await _channel.invokeMethod<bool>(
            'connectWifi',
            {'ssid': ssid, 'password': password},
          ) ??
          false;
    } catch (e) {
      logger.w('[STB] connectWifi failed: $e');
      return false;
    }
  }

  Future<bool> setWifiEnabled(bool enabled) async {
    if (!StbSystemService.isStb) return false;
    try {
      return await _channel.invokeMethod<bool>('setWifiEnabled', {'enabled': enabled}) ?? false;
    } catch (e) {
      logger.w('[STB] setWifiEnabled failed: $e');
      return false;
    }
  }
}
