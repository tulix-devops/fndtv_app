import 'package:flutter_test/flutter_test.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/ui/widgets/stb_video_player/stb_schedule_strip.dart';

/// Minimal EPG entry. `LiveModel.fromJson` defaults every field we don't set,
/// so the tests stay about times rather than model plumbing.
LiveModel program(String title, String startsAt, String endsAt) {
  return LiveModel.fromJson({
    'title': title,
    'startsAt': startsAt,
    'endsAt': endsAt,
  });
}

void main() {
  // Fixed UTC instants so the tests don't depend on the machine's timezone;
  // the production code converts feed timestamps with .toLocal(), and both
  // sides of every comparison shift together.
  DateTime at(String iso) => DateTime.parse(iso);

  group('scheduleNowIndex', () {
    final programs = [
      program('a', '2026-07-30T10:00:00+00:00', '2026-07-30T11:00:00+00:00'),
      program('b', '2026-07-30T11:00:00+00:00', '2026-07-30T12:00:00+00:00'),
      // 71-minute hole, mirroring the real feed on 2026-07-30.
      program('c', '2026-07-30T13:11:00+00:00', '2026-07-30T14:00:00+00:00'),
    ];

    test('finds the program covering the instant', () {
      expect(scheduleNowIndex(programs, at('2026-07-30T11:30:00Z')), 1);
    });

    test('start is inclusive, end is exclusive', () {
      expect(scheduleNowIndex(programs, at('2026-07-30T11:00:00Z')), 1);
      expect(scheduleNowIndex(programs, at('2026-07-30T12:00:00Z')), -1);
    });

    test('returns -1 inside a gap', () {
      expect(scheduleNowIndex(programs, at('2026-07-30T12:30:00Z')), -1);
    });

    test('returns -1 before and after the window', () {
      expect(scheduleNowIndex(programs, at('2026-07-30T09:00:00Z')), -1);
      expect(scheduleNowIndex(programs, at('2026-07-30T23:00:00Z')), -1);
    });

    test('skips entries with missing or malformed timestamps', () {
      final dirty = [
        program('no times', '', ''),
        program('junk', 'not-a-date', 'also-not'),
        program(
            'good', '2026-07-30T10:00:00+00:00', '2026-07-30T11:00:00+00:00'),
      ];
      expect(scheduleNowIndex(dirty, at('2026-07-30T10:30:00Z')), 2);
    });

    test('empty list yields -1', () {
      expect(scheduleNowIndex(const [], at('2026-07-30T10:30:00Z')), -1);
    });
  });

  group('scheduleFocusIndex', () {
    final programs = [
      program('a', '2026-07-30T10:00:00+00:00', '2026-07-30T11:00:00+00:00'),
      program('b', '2026-07-30T11:00:00+00:00', '2026-07-30T12:00:00+00:00'),
      program('c', '2026-07-30T13:11:00+00:00', '2026-07-30T14:00:00+00:00'),
    ];

    test('prefers whatever is airing', () {
      expect(scheduleFocusIndex(programs, at('2026-07-30T11:30:00Z')), 1);
    });

    test('falls forward to the next program when inside a gap', () {
      // The regression this exists for: index 0 here would strand the viewer
      // most of a day behind on a rolling 24h feed.
      expect(scheduleFocusIndex(programs, at('2026-07-30T12:30:00Z')), 2);
    });

    test('before the window starts, points at the first program', () {
      expect(scheduleFocusIndex(programs, at('2026-07-30T08:00:00Z')), 0);
    });

    test('after the window ends, points at the last program', () {
      expect(scheduleFocusIndex(programs, at('2026-07-30T23:00:00Z')), 2);
    });

    test('empty list yields 0 rather than throwing', () {
      expect(scheduleFocusIndex(const [], at('2026-07-30T11:30:00Z')), 0);
    });
  });

  group('sortedByStart', () {
    test('orders chronologically and leaves the input untouched', () {
      final unsorted = [
        program(
            'late', '2026-07-30T14:00:00+00:00', '2026-07-30T15:00:00+00:00'),
        program(
            'early', '2026-07-30T09:00:00+00:00', '2026-07-30T10:00:00+00:00'),
        program(
            'mid', '2026-07-30T11:00:00+00:00', '2026-07-30T12:00:00+00:00'),
      ];
      final sorted = sortedByStart(unsorted);

      expect(sorted.map((p) => p.title), ['early', 'mid', 'late']);
      expect(unsorted.map((p) => p.title), ['late', 'early', 'mid']);
    });
  });

  group('StbScheduleStrip.offsetFor', () {
    // Card 240 + gap 14 = stride 254, with a 24px inset on each end of the
    // list's contents.
    const viewport = 1000.0;

    test('clamps to zero for the first cards', () {
      expect(StbScheduleStrip.offsetFor(0, viewport, 40), 0);
    });

    test('centres a card in the middle of the list', () {
      // 24 + 10 * 254 - (1000 - 240) / 2 = 24 + 2540 - 380 = 2184
      expect(StbScheduleStrip.offsetFor(10, viewport, 40), 2184);
    });

    test('never scrolls past the end', () {
      // Content = 48 + 40 * 254 - 14 = 10194; max offset = 10194 - 1000 = 9194.
      expect(StbScheduleStrip.offsetFor(39, viewport, 40), 9194);
    });

    test('stays at zero when everything fits on screen', () {
      expect(StbScheduleStrip.offsetFor(2, viewport, 3), 0);
    });
  });
}
