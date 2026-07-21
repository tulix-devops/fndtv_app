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

  test('dispose while a probe is pending does not throw and suppresses late emission', () async {
    final changes = StreamController<List<ConnectivityResult>>();
    final completer = Completer<bool>();
    final observer = ConnectivityObserver(
      changes: changes.stream,
      probe: () => completer.future,
    );
    final events = <bool>[];
    observer.onlineStream.listen(events.add);

    changes.add([ConnectivityResult.wifi]);
    // Let the change reach the probe call so it's genuinely in-flight.
    await Future<void>.delayed(const Duration(milliseconds: 10));

    await observer.dispose();

    // Completing the in-flight probe after dispose must not throw
    // ("Cannot add event after closing") and must not emit anything.
    completer.complete(true);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(events, isEmpty);
  });

  test('out-of-order probes: a stale slower probe cannot clobber a newer result', () async {
    final changes = StreamController<List<ConnectivityResult>>();
    final completers = <Completer<bool>>[];
    final observer = ConnectivityObserver(
      changes: changes.stream,
      probe: () {
        final c = Completer<bool>();
        completers.add(c);
        return c.future;
      },
    );
    final events = <bool>[];
    observer.onlineStream.listen(events.add);

    // Two change events fire back-to-back; both probes are in flight.
    changes.add([ConnectivityResult.wifi]); // event 1 (stale) -> probe #0
    changes.add([ConnectivityResult.wifi]); // event 2 (newest) -> probe #1
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(completers.length, 2);

    // The NEWER event's probe resolves first, reporting offline.
    completers[1].complete(false);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(observer.isOnline, isFalse);

    // The STALE (first) event's probe resolves later, reporting online.
    // It must be ignored — the newer offline result must stick.
    completers[0].complete(true);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(observer.isOnline, isFalse);
    expect(events, [false]);
    await observer.dispose();
  });
}
