import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fndtv/src/core/services/stb_kiosk_guard.dart';
import 'package:fndtv/src/core/services/stb_system_service.dart';

/// Replays a scripted outcome per pass (the last entry repeats) and counts how
/// many passes were asked for.
class _FakeSystemService implements StbSystemService {
  _FakeSystemService(this._script);

  final List<StbKioskStatus> _script;
  int calls = 0;

  @override
  Future<StbKioskStatus> runStartupMaintenance({
    List<String> unwantedApps = kStbUnwantedApps,
    List<String> disabledComponents = kStbDisabledComponents,
    List<String> disabledPackages = kStbDisabledPackages,
  }) async {
    final status = _script[calls.clamp(0, _script.length - 1)];
    calls++;
    return status;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not needed here');
}

StbKioskStatus _status({
  required bool ready,
  required bool durable,
  bool root = true,
  List<String> candidates = const [],
}) =>
    StbKioskStatus(
      ready: ready,
      durable: durable,
      root: root,
      deviceOwner: false,
      launcher: ready ? 'com.fndtv.videoplayer' : 'com.smartbox.launcher',
      homeCandidates: candidates,
      summary: const {},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ({StbKioskGuard guard, _FakeSystemService system}) build(
    List<StbKioskStatus> script, {
    int attempts = 4,
  }) {
    final system = _FakeSystemService(script);
    final guard = StbKioskGuard(
      system: system,
      schedule: List<Duration>.filled(attempts, Duration.zero),
      resumeCooldown: Duration.zero,
      delay: (_) async {},
      enabled: true,
    );
    addTearDown(guard.dispose);
    return (guard: guard, system: system);
  }

  group('boot sequence', () {
    test('a healthy box is pinned on the first pass and left alone', () async {
      final t = build([_status(ready: true, durable: true)]);

      await t.guard.start();

      expect(t.system.calls, 1, reason: 'no retries once the box is settled');
      expect(t.guard.status.ready, isTrue);
      expect(t.guard.status.durable, isTrue);
    });

    test('retries until root arrives — the slow-boot case', () async {
      // Passes 1-2 find no root (we start before the su daemon has granted),
      // pass 3 succeeds. The old code did one pass and gave up until reboot.
      final t = build([
        _status(ready: false, durable: false, root: false),
        _status(ready: false, durable: false, root: false),
        _status(ready: true, durable: true),
      ]);

      await t.guard.start();

      expect(t.system.calls, 3);
      expect(t.guard.status.ready, isTrue);
    });

    test('keeps retrying while HOME is held but revertible', () async {
      // `ready` alone is the state that silently comes back on a later boot,
      // so it must NOT end the schedule.
      final t = build(
        [
          _status(
            ready: true,
            durable: false,
            candidates: ['com.smartbox.launcher'],
          ),
        ],
        attempts: 4,
      );

      await t.guard.start();

      expect(t.system.calls, 4, reason: 'ready-but-not-durable is not done');
      expect(t.guard.status.ready, isTrue);
      expect(t.guard.status.durable, isFalse);
    });

    test('gives up after the schedule rather than looping forever', () async {
      final t = build(
        [_status(ready: false, durable: false, root: false)],
        attempts: 3,
      );

      await t.guard.start();

      expect(t.system.calls, 3);
      expect(t.guard.status.ready, isFalse);
    });

    test('does nothing off the stb flavor', () async {
      final system = _FakeSystemService([_status(ready: true, durable: true)]);
      final guard = StbKioskGuard(
        system: system,
        schedule: const [Duration.zero],
        delay: (_) async {},
        enabled: false,
      );
      addTearDown(guard.dispose);

      await guard.start();

      expect(system.calls, 0);
    });
  });

  group('re-assert on resume', () {
    test('runs a pass when the box is not settled', () async {
      final t = build(
        [
          _status(ready: false, durable: false),
        ],
        attempts: 1,
      );
      await t.guard.start();
      expect(t.system.calls, 1);

      // Coming back into FNDTV — typically the user having just answered the
      // "Use ___ as Home" chooser, which is when the preference is settable.
      t.guard.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(t.system.calls, 2);
    });

    test('stays quiet once the box is settled', () async {
      final t = build([_status(ready: true, durable: true)], attempts: 1);
      await t.guard.start();
      expect(t.system.calls, 1);

      t.guard.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(t.system.calls, 1);
    });

    test('ignores lifecycle states other than resumed', () async {
      final t = build([_status(ready: false, durable: false)], attempts: 1);
      await t.guard.start();
      expect(t.system.calls, 1);

      t.guard.didChangeAppLifecycleState(AppLifecycleState.paused);
      t.guard.didChangeAppLifecycleState(AppLifecycleState.inactive);
      await Future<void>.delayed(Duration.zero);

      expect(t.system.calls, 1);
    });

    test('no pass runs after dispose', () async {
      final t = build([_status(ready: false, durable: false)], attempts: 1);
      await t.guard.start();
      final before = t.system.calls;

      t.guard.dispose();
      t.guard.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(t.system.calls, before);
    });
  });

  group('StbKioskStatus.fromSummary', () {
    test('reads the verified outcome, not the attempted one', () {
      final status = StbKioskStatus.fromSummary(const {
        'root': true,
        'deviceOwner': false,
        'launcherSet': true, // the command ran…
        'kioskReady': false, // …and it still did not take
        'kioskDurable': false,
        'launcherAfter': 'com.smartbox.launcher',
        'homeCandidatesAfter': ['com.smartbox.launcher'],
      });

      expect(status.ready, isFalse);
      expect(status.durable, isFalse);
      expect(status.launcher, 'com.smartbox.launcher');
      expect(status.homeCandidates, ['com.smartbox.launcher']);
    });

    test('held but revertible is ready and NOT durable', () {
      final status = StbKioskStatus.fromSummary(const {
        'kioskReady': true,
        'kioskDurable': false,
        'launcherAfter': 'com.fndtv.videoplayer',
        'homeCandidatesAfter': ['com.google.android.tvlauncher'],
      });

      expect(status.ready, isTrue);
      expect(status.durable, isFalse);
    });

    test('a missing summary degrades to "nothing is held"', () {
      final status = StbKioskStatus.fromSummary(const {});
      expect(status.ready, isFalse);
      expect(status.durable, isFalse);
      expect(status.homeCandidates, isEmpty);
    });
  });

  group('app lists', () {
    test('covers both YouTube package ids shipped on these boxes', () {
      expect(kStbUnwantedApps, contains('com.google.android.youtube.tv'));
      expect(kStbUnwantedApps, contains('com.google.android.youtube'));
    });

    test('never lists our own package', () {
      expect(kStbUnwantedApps, isNot(contains('com.fndtv.videoplayer')));
      expect(kStbDisabledPackages, isNot(contains('com.fndtv.videoplayer')));
    });

    test('lists no package whose removal would brick the box', () {
      const protectedPkgs = {
        'android',
        'com.android.systemui',
        'com.android.settings',
        'com.android.tv.settings',
      };
      expect(
        kStbUnwantedApps.toSet().intersection(protectedPkgs),
        isEmpty,
        reason: 'com.android.settings hosts FallbackHome',
      );
      expect(
        kStbDisabledPackages.toSet().intersection(protectedPkgs),
        isEmpty,
      );
    });

    test('the shipped schedule spreads passes across the first minute', () {
      final total = kStbKioskSchedule.fold<Duration>(
        Duration.zero,
        (sum, gap) => sum + gap,
      );
      expect(kStbKioskSchedule.first, Duration.zero,
          reason: 'a healthy box must not wait to be pinned');
      expect(total, greaterThanOrEqualTo(const Duration(seconds: 30)),
          reason: 'su can take most of a minute to grant on a cold boot');
    });
  });
}
