import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fndtv/src/core/services/connectivity_observer.dart';

void main() {
  test('emits offline when interface says none (no probe needed)', () async {
    final changes = StreamController<List<ConnectivityResult>>();
    final observer = ConnectivityObserver(
      changes: changes.stream,
      probe: () async => fail('probe must not run with no interface'),
    );
    final events = <bool>[];
    observer.onlineStream.listen(events.add);

    changes.add([ConnectivityResult.none]);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(events, [false]);
    expect(observer.isOnline, isFalse);
    await observer.dispose();
  });

  test('interface up + probe ok -> online; probe fail -> offline', () async {
    final changes = StreamController<List<ConnectivityResult>>();
    var probeResult = true;
    final observer = ConnectivityObserver(
      changes: changes.stream,
      probe: () async => probeResult,
    );
    final events = <bool>[];
    observer.onlineStream.listen(events.add);

    changes.add([ConnectivityResult.wifi]);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(events, [true]);

    probeResult = false;
    changes.add([ConnectivityResult.wifi]);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(events, [true, false]);
    await observer.dispose();
  });

  test('does not re-emit unchanged state', () async {
    final changes = StreamController<List<ConnectivityResult>>();
    final observer = ConnectivityObserver(
      changes: changes.stream,
      probe: () async => true,
    );
    final events = <bool>[];
    observer.onlineStream.listen(events.add);

    changes.add([ConnectivityResult.wifi]);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    changes.add([ConnectivityResult.wifi]);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(events, [true]);
    await observer.dispose();
  });
}
