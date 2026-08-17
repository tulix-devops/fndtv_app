import 'package:flutter_test/flutter_test.dart';
import 'package:fndtv/src/core/services/stb_clock.dart';
import 'package:fndtv/src/core/services/stb_system_service.dart';
import 'package:local_storage/local_storage.dart';

/// Replays a scripted zone per call (last entry repeats) and counts attempts.
class _FakeSystemService implements StbSystemService {
  _FakeSystemService(this._script);

  final List<StbTimezone?> _script;
  int calls = 0;

  @override
  Future<StbTimezone?> syncTimezone() async {
    final zone = _script[calls.clamp(0, _script.length - 1)];
    calls++;
    return zone;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not needed here');
}

/// In-memory LocalStorage. `throwOnWrite` reproduces the box where Hive is not
/// open yet — the resolved offset must still be live in memory.
class _FakeStorage implements LocalStorage {
  _FakeStorage({this.throwOnWrite = false, Map<String, Object?>? seed})
      : _data = {...?seed};

  final Map<String, Object?> _data;
  final bool throwOnWrite;

  @override
  Future<T?> get<T>(String key) async => _data[key] as T?;

  @override
  Future<void> store<T>(String key, T value) async {
    if (throwOnWrite) throw StateError('box not open');
    _data[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not needed here');
}

StbTimezone _paris({bool applied = false}) => StbTimezone(
      id: 'Europe/Paris',
      offsetSeconds: 7200, // CEST, UTC+2
      applied: applied,
    );

void main() {
  StbClock build(
    List<StbTimezone?> script, {
    int attempts = 4,
  }) =>
      StbClock(
        system: _FakeSystemService(script),
        retrySchedule: List<Duration>.filled(attempts, Duration.zero),
        refreshInterval: Duration.zero, // no periodic timer in tests
        delay: (_) async {},
        enabled: true,
      );

  group('conversion', () {
    test('renders in the resolved zone, not the system one', () async {
      final clock = build([_paris()]);
      addTearDown(clock.dispose);
      await clock.start(_FakeStorage());

      // 20:30 UTC in Paris (UTC+2) is 22:30.
      final utc = DateTime.utc(2026, 8, 11, 20, 30);
      final local = clock.toBoxLocal(utc);

      expect(local.hour, 22);
      expect(local.minute, 30);
    });

    test('a negative offset goes the other way', () async {
      final clock = build([
        const StbTimezone(
            id: 'America/New_York', offsetSeconds: -14400, applied: false),
      ]);
      addTearDown(clock.dispose);
      await clock.start(_FakeStorage());

      final local = clock.toBoxLocal(DateTime.utc(2026, 8, 11, 2, 0));
      expect(local.day, 10);
      expect(local.hour, 22);
    });

    test('falls back to toLocal() before anything is resolved', () {
      final clock = build([null]);
      addTearDown(clock.dispose);

      final utc = DateTime.utc(2026, 8, 11, 20, 30);
      expect(clock.isResolved, isFalse);
      // Never worse than the behaviour it replaces.
      expect(clock.toBoxLocal(utc), utc.toLocal());
    });

    test('converts a local-typed input by its absolute instant', () async {
      final clock = build([_paris()]);
      addTearDown(clock.dispose);
      await clock.start(_FakeStorage());

      final utc = DateTime.utc(2026, 8, 11, 20, 30);
      // Same instant expressed in the machine's zone must land on the same
      // wall time — otherwise the result depends on where the box happens to
      // think it is, which is the whole bug.
      expect(clock.toBoxLocal(utc.toLocal()), clock.toBoxLocal(utc));
    });
  });

  group('resolution and retry', () {
    test('stops as soon as it resolves', () async {
      final system = _FakeSystemService([_paris()]);
      final clock = StbClock(
        system: system,
        retrySchedule: List.filled(5, Duration.zero),
        refreshInterval: Duration.zero,
        delay: (_) async {},
        enabled: true,
      );
      addTearDown(clock.dispose);

      await clock.start(_FakeStorage());

      expect(system.calls, 1);
      expect(clock.zoneId, 'Europe/Paris');
    });

    test('retries past an offline boot — the eleven-second case', () async {
      // The box got its DHCP lease AFTER the app had already asked and failed.
      final system = _FakeSystemService([null, null, _paris()]);
      final clock = StbClock(
        system: system,
        retrySchedule: List.filled(5, Duration.zero),
        refreshInterval: Duration.zero,
        delay: (_) async {},
        enabled: true,
      );
      addTearDown(clock.dispose);

      await clock.start(_FakeStorage());

      expect(system.calls, 3);
      expect(clock.isResolved, isTrue);
      expect(clock.offset, const Duration(hours: 2));
    });

    test('gives up after the schedule instead of looping forever', () async {
      final system = _FakeSystemService([null]);
      final clock = StbClock(
        system: system,
        retrySchedule: List.filled(3, Duration.zero),
        refreshInterval: Duration.zero,
        delay: (_) async {},
        enabled: true,
      );
      addTearDown(clock.dispose);

      await clock.start(_FakeStorage());

      expect(system.calls, 3);
      expect(clock.isResolved, isFalse);
    });

    test('the shipped schedule keeps trying for minutes, not seconds', () {
      final total = kStbClockRetrySchedule.fold<Duration>(
        Duration.zero,
        (sum, gap) => sum + gap,
      );
      expect(kStbClockRetrySchedule.first, Duration.zero);
      expect(total, greaterThanOrEqualTo(const Duration(minutes: 4)),
          reason: 'Wi-Fi association or a slow uplink can take minutes');
    });
  });

  group('persistence', () {
    test('persists the resolved offset', () async {
      final storage = _FakeStorage();
      final clock = build([_paris()]);
      addTearDown(clock.dispose);

      await clock.start(storage);

      expect(await storage.get<String>(kStbTimezoneIdKey), 'Europe/Paris');
      expect(await storage.get<int>(kStbTimezoneOffsetKey), 7200);
    });

    test('restores it before any network call', () async {
      final storage = _FakeStorage(seed: {
        kStbTimezoneIdKey: 'Europe/Paris',
        kStbTimezoneOffsetKey: 7200,
      });
      final system = _FakeSystemService([null]);
      final clock = StbClock(
        system: system,
        refreshInterval: Duration.zero,
        delay: (_) async {},
        enabled: true,
      );
      addTearDown(clock.dispose);

      await clock.load(storage);

      // An offline box renders correctly from the first frame.
      expect(system.calls, 0);
      expect(clock.isResolved, isTrue);
      expect(clock.toBoxLocal(DateTime.utc(2026, 8, 11, 20, 30)).hour, 22);
    });

    test('a storage write failure still leaves the offset live', () async {
      final clock = build([_paris()]);
      addTearDown(clock.dispose);

      await clock.start(_FakeStorage(throwOnWrite: true));

      expect(clock.isResolved, isTrue);
      expect(clock.offset, const Duration(hours: 2));
    });

    test('an empty store resolves nothing and stays on the fallback', () async {
      final clock = build([null]);
      addTearDown(clock.dispose);

      await clock.load(_FakeStorage());

      expect(clock.isResolved, isFalse);
      expect(clock.zoneId, isNull);
    });
  });

  group('root is not required', () {
    test('an offset that was never applied to the system still renders',
        () async {
      // The whole point: `su` refused, system zone stays wrong, app is right.
      final clock = build([_paris(applied: false)]);
      addTearDown(clock.dispose);

      await clock.start(_FakeStorage());

      expect(clock.isResolved, isTrue);
      expect(clock.toBoxLocal(DateTime.utc(2026, 8, 11, 20, 30)).hour, 22);
    });
  });
}
