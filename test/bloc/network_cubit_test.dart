import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fndtv/src/bloc/network_cubit/network_cubit.dart';
import 'package:fndtv/src/core/services/connectivity_observer.dart';
import 'package:fndtv/src/core/services/stb_network_service.dart';

class FakeNetworkService extends StbNetworkService {
  StbNetworkStatus next = StbNetworkStatus.fromMaps();
  List<WifiNetwork> scanResult = const [];
  bool connectResult = true;
  final connectCalls = <(String, String?)>[];

  @override
  Future<StbNetworkStatus> status() async => next;
  @override
  Future<List<WifiNetwork>> scan() async => scanResult;
  @override
  Future<bool> connect(String ssid, {String? password}) async {
    connectCalls.add((ssid, password));
    return connectResult;
  }

  @override
  Future<bool> setWifiEnabled(bool enabled) async => true;
}

void main() {
  NetworkCubit make(FakeNetworkService svc) => NetworkCubit(
        service: svc,
        observer: ConnectivityObserver(changes: const Stream.empty(), probe: () async => true),
        joinPollInterval: const Duration(milliseconds: 10),
        joinTimeout: const Duration(milliseconds: 50),
      );

  test('refreshStatus copies service snapshot into state', () async {
    final svc = FakeNetworkService()
      ..next = StbNetworkStatus.fromMaps(
        wifi: {'enabled': true, 'ssid': 'Home', 'ip': '10.0.0.2'},
        ethernet: {'linked': true, 'ip': '10.0.0.3'},
      );
    final cubit = make(svc);
    await cubit.refreshStatus();
    expect(cubit.state.ssid, 'Home');
    expect(cubit.state.ethernetLinked, isTrue);
    await cubit.close();
  });

  test('scan sets scanning then results', () async {
    final svc = FakeNetworkService()
      ..scanResult = const [WifiNetwork(ssid: 'A', secured: true, level: 3)];
    final cubit = make(svc);
    await cubit.scan();
    expect(cubit.state.scanning, isFalse);
    expect(cubit.state.networks.single.ssid, 'A');
    await cubit.close();
  });

  test('join success when polled status reaches target ssid', () async {
    final svc = FakeNetworkService();
    final cubit = make(svc);
    svc.next = StbNetworkStatus.fromMaps(wifi: {'enabled': true, 'ssid': 'A', 'ip': '1.2.3.4'});
    await cubit.join('A', password: 'pw');
    expect(svc.connectCalls, [('A', 'pw')]);
    expect(cubit.state.joinPhase, NetworkJoinPhase.idle);
    expect(cubit.state.ssid, 'A');
    await cubit.close();
  });

  test('join times out -> failed phase', () async {
    final svc = FakeNetworkService(); // status never reports ssid B
    final cubit = make(svc);
    await cubit.join('B', password: 'bad');
    expect(cubit.state.joinPhase, NetworkJoinPhase.failed);
    await cubit.close();
  });

  test('overlay suppression flag toggles', () async {
    final cubit = make(FakeNetworkService());
    cubit.suppressOverlay(true);
    expect(cubit.state.overlaySuppressed, isTrue);
    cubit.suppressOverlay(false);
    expect(cubit.state.overlaySuppressed, isFalse);
    await cubit.close();
  });
}
