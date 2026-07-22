import 'package:flutter_test/flutter_test.dart';
import 'package:fndtv/src/core/services/stb_network_service.dart';

void main() {
  group('WifiNetwork.fromMap', () {
    test('parses fields and buckets rssi into level 1-4', () {
      final n = WifiNetwork.fromMap({'ssid': 'Home', 'secured': true, 'rssi': -60});
      expect(n.ssid, 'Home');
      expect(n.secured, isTrue);
      expect(n.level, 4);
    });

    test('rssi buckets: -90->1, -80->2, -70->3, -55->4', () {
      int lvl(int rssi) => WifiNetwork.fromMap({'ssid': 's', 'secured': false, 'rssi': rssi}).level;
      expect(lvl(-90), 1);
      expect(lvl(-80), 2);
      expect(lvl(-70), 3);
      expect(lvl(-55), 4);
    });

    test('tolerates missing fields', () {
      final n = WifiNetwork.fromMap(const {});
      expect(n.ssid, '');
      expect(n.secured, isFalse);
      expect(n.level, 1);
      expect(n.security, 'open');
    });

    test('parses security type; defaults to open when absent', () {
      final wpa3 = WifiNetwork.fromMap(
        {'ssid': 'S', 'secured': true, 'rssi': -50, 'security': 'wpa3'},
      );
      expect(wpa3.security, 'wpa3');
      final legacy = WifiNetwork.fromMap({'ssid': 'S', 'secured': true, 'rssi': -50});
      expect(legacy.security, 'open');
    });
  });

  group('StbNetworkStatus.fromMaps', () {
    test('merges wifi + ethernet maps', () {
      final s = StbNetworkStatus.fromMaps(
        wifi: {'enabled': true, 'ssid': 'Home', 'ip': '192.168.1.34'},
        ethernet: {'linked': false, 'ip': null},
      );
      expect(s.wifiEnabled, isTrue);
      expect(s.ssid, 'Home');
      expect(s.wifiIp, '192.168.1.34');
      expect(s.ethernetLinked, isFalse);
      expect(s.ethernetIp, isNull);
    });

    test('null maps degrade to defaults', () {
      final s = StbNetworkStatus.fromMaps(wifi: null, ethernet: null);
      expect(s.wifiEnabled, isFalse);
      expect(s.ssid, isNull);
      expect(s.ethernetLinked, isFalse);
    });
  });
}
