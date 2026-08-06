import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fndtv/src/bloc/network_cubit/network_cubit.dart';
import 'package:fndtv/src/core/services/connectivity_observer.dart';
import 'package:fndtv/src/core/services/stb_network_service.dart';

class FakeNetworkService extends StbNetworkService {
  StbNetworkStatus next = StbNetworkStatus.fromMaps();
  List<WifiNetwork> scanResult = const [];

  /// Successive scan results, consumed in order (to model a radio that needs a
  /// moment before it reports anything); falls back to [scanResult].
  List<List<WifiNetwork>>? scanSequence;
  bool connectResult = true;
  int scanCalls = 0;
  final wifiEnabledCalls = <bool>[];
  final connectCalls = <(String, String?)>[];
  final connectSecurity = <String?>[];

  @override
  Future<StbNetworkStatus> status() async => next;
  @override
  Future<List<WifiNetwork>> scan() async {
    scanCalls++;
    final seq = scanSequence;
    if (seq != null && seq.isNotEmpty) return seq.removeAt(0);
    return scanResult;
  }
  @override
  Future<bool> connect(String ssid, {String? password, String? security}) async {
    connectCalls.add((ssid, password));
    connectSecurity.add(security);
    return connectResult;
  }

  @override
  Future<bool> setWifiEnabled(bool enabled) async {
    wifiEnabledCalls.add(enabled);
    return true;
  }
}

/// A status() call that only resolves once [release] completes, so a test can
/// hold a refresh "in flight" while the cubit closes underneath it.
class SlowNetworkService extends StbNetworkService {
  SlowNetworkService(this.release);
  final Completer<void> release;
  StbNetworkStatus next = StbNetworkStatus.fromMaps();

  @override
  Future<StbNetworkStatus> status() async {
    await release.future;
    return next;
  }
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

  test('join forwards the security type to the service', () async {
    final svc = FakeNetworkService();
    final cubit = make(svc);
    svc.next = StbNetworkStatus.fromMaps(wifi: {'enabled': true, 'ssid': 'A', 'ip': '1.2.3.4'});
    await cubit.join('A', password: 'pw', security: 'wpa3');
    expect(svc.connectSecurity, ['wpa3']);
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

  test('closing while an online-triggered refreshStatus is in flight does not throw', () async {
    final release = Completer<void>();
    final svc = SlowNetworkService(release)
      ..next = StbNetworkStatus.fromMaps(
        wifi: {'enabled': true, 'ssid': 'Home', 'ip': '10.0.0.2'},
      );
    final changes = StreamController<List<ConnectivityResult>>();
    final observer = ConnectivityObserver(changes: changes.stream, probe: () async => true);
    final cubit = NetworkCubit(
      service: svc,
      observer: observer,
      joinPollInterval: const Duration(milliseconds: 10),
      joinTimeout: const Duration(milliseconds: 50),
    );

    // Fire a connectivity change: observer probes (true) -> onlineStream
    // emits true -> cubit's listener emits online + fires refreshStatus(),
    // which is now blocked inside SlowNetworkService.status() on `release`.
    changes.add([ConnectivityResult.wifi]);
    // Let the microtask chain (probe -> _set -> broadcast -> listener ->
    // refreshStatus -> status() -> suspends on release.future) settle.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.online, isTrue);

    // Close the cubit while the refreshStatus() call is still pending.
    final closeFuture = cubit.close();

    // Now let the pending status() resolve. Without the isClosed guard in
    // refreshStatus() this throws StateError: Cannot emit new states after
    // calling close.
    release.complete();

    await expectLater(closeFuture, completes);
    await changes.close();
  });

  // ── Bug: moving to Wi-Fi must show the available networks ────────────────

  test('switching to Wi-Fi scans, so the network list is populated', () async {
    final svc = FakeNetworkService()
      ..scanResult = const [WifiNetwork(ssid: 'A', secured: true, level: 3)];
    final cubit = make(svc);
    await cubit.setUseWifi(true);
    expect(svc.wifiEnabledCalls, [true]);
    expect(svc.scanCalls, greaterThanOrEqualTo(1));
    expect(cubit.state.networks.single.ssid, 'A');
    await cubit.close();
  });

  test('switching to wired does not scan', () async {
    final svc = FakeNetworkService();
    final cubit = make(svc);
    await cubit.setUseWifi(false);
    expect(svc.wifiEnabledCalls, [false]);
    expect(svc.scanCalls, 0);
    await cubit.close();
  });

  test('scan retries while the radio has not produced results yet', () async {
    final svc = FakeNetworkService()
      ..scanSequence = [
        const [],
        const [WifiNetwork(ssid: 'Late', secured: false, level: 2)],
      ];
    final cubit = make(svc);
    await cubit.scan(retries: 2, retryDelay: const Duration(milliseconds: 5));
    expect(svc.scanCalls, 2);
    expect(cubit.state.networks.single.ssid, 'Late');
    expect(cubit.state.scanning, isFalse);
    await cubit.close();
  });

  // ── Bug: rebooted with no cable must not stay stranded on wired ──────────

  test('ensureBootConnectivity enables Wi-Fi when no cable and radio is off',
      () async {
    final svc = FakeNetworkService()
      ..next = StbNetworkStatus.fromMaps(
        wifi: {'enabled': false},
        ethernet: {'linked': false},
      );
    final cubit = make(svc);
    expect(await cubit.ensureBootConnectivity(), isTrue);
    expect(svc.wifiEnabledCalls, [true]);
    await cubit.close();
  });

  test('ensureBootConnectivity leaves a linked wired box alone', () async {
    final svc = FakeNetworkService()
      ..next = StbNetworkStatus.fromMaps(
        wifi: {'enabled': false},
        ethernet: {'linked': true, 'ip': '10.0.0.3'},
      );
    final cubit = make(svc);
    expect(await cubit.ensureBootConnectivity(), isFalse);
    expect(svc.wifiEnabledCalls, isEmpty);
    await cubit.close();
  });

  test('ensureBootConnectivity is a no-op when Wi-Fi is already on', () async {
    final svc = FakeNetworkService()
      ..next = StbNetworkStatus.fromMaps(
        wifi: {'enabled': true, 'ssid': 'Home', 'ip': '10.0.0.2'},
        ethernet: {'linked': false},
      );
    final cubit = make(svc);
    expect(await cubit.ensureBootConnectivity(), isFalse);
    expect(svc.wifiEnabledCalls, isEmpty);
    await cubit.close();
  });
}
