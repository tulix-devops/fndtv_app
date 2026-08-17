import 'package:flutter_test/flutter_test.dart';
import 'package:fndtv/src/data/models/content/images_model.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/data/models/content/source_model.dart';
import 'package:fndtv/src/ui/widgets/stb_video_player/stb_schedule_strip.dart';

LiveModel _program(String title, {String? startsAt, String? endsAt}) =>
    LiveModel(
      id: title.hashCode,
      typeId: 1,
      type: 'live',
      title: title,
      images: const ImagesModel(poster: null, banner: null, thumbnail: null),
      sources: const SourceModel(),
      live: true,
      startsAt: startsAt,
      endsAt: endsAt,
    );

/// A program running from [startHour] to [endHour] UTC on 2026-08-11.
LiveModel _p(String title, int startHour, int endHour) => _program(
      title,
      startsAt: DateTime.utc(2026, 8, 11, startHour).toIso8601String(),
      endsAt: DateTime.utc(2026, 8, 11, endHour).toIso8601String(),
    );

DateTime _at(int hour, [int minute = 0]) =>
    DateTime.utc(2026, 8, 11, hour, minute);

void main() {
  group('scheduleFromNow', () {
    test('drops programs that already finished', () {
      final programs = [
        _p('morning', 8, 10),
        _p('midday', 10, 12),
        _p('afternoon', 12, 14),
        _p('evening', 20, 22),
      ];

      final result = scheduleFromNow(programs, _at(12, 30));

      expect(result.map((p) => p.title), ['afternoon', 'evening']);
    });

    test('keeps the program currently airing', () {
      final programs = [_p('earlier', 8, 10), _p('now', 12, 14)];

      // Mid-programme: it has not finished, so it stays and leads the strip.
      final result = scheduleFromNow(programs, _at(13));

      expect(result.map((p) => p.title), ['now']);
    });

    test('a program ending exactly now is finished', () {
      final programs = [_p('ending', 12, 13), _p('next', 13, 14)];

      final result = scheduleFromNow(programs, _at(13));

      expect(result.map((p) => p.title), ['next']);
    });

    test('keeps everything when nothing has aired yet', () {
      final programs = [_p('a', 20, 21), _p('b', 21, 22)];

      final result = scheduleFromNow(programs, _at(9));

      expect(result.map((p) => p.title), ['a', 'b']);
    });

    test('keeps entries whose end time will not parse', () {
      // The feed is not clean. Hiding a program because we could not read its
      // timestamp is worse than showing it.
      final programs = [
        _p('finished', 8, 10),
        _program('malformed', startsAt: 'nonsense', endsAt: 'nonsense'),
        _p('later', 20, 22),
      ];

      final result = scheduleFromNow(programs, _at(12));

      expect(result.map((p) => p.title), ['malformed', 'later']);
    });

    test('keeps entries with a missing end time', () {
      final programs = [
        _p('finished', 8, 10),
        _program('no end'),
      ];

      final result = scheduleFromNow(programs, _at(12));

      expect(result.map((p) => p.title), ['no end']);
    });

    group('wrong clock', () {
      test('falls back to the full list rather than emptying the strip', () {
        // A box in the field booted believing it was 7 December and only
        // corrected to 11 August once NTP ran. A clock that far ahead makes
        // every program look finished — the strip must not go blank.
        final programs = [_p('a', 8, 10), _p('b', 20, 22)];

        final result = scheduleFromNow(programs, DateTime.utc(2026, 12, 7));

        expect(result.map((p) => p.title), ['a', 'b'],
            reason: 'degrade to the old behaviour, never to an empty panel');
      });

      test('an empty feed stays empty', () {
        expect(scheduleFromNow(const [], _at(12)), isEmpty);
      });
    });

    test('preserves order and does not mutate the input', () {
      final programs = [_p('a', 8, 10), _p('b', 12, 14), _p('c', 14, 16)];
      final before = programs.map((p) => p.title).toList();

      final result = scheduleFromNow(programs, _at(13));

      expect(result.map((p) => p.title), ['b', 'c']);
      expect(programs.map((p) => p.title), before);
    });
  });

  group('cursor lands on the right card once filtered', () {
    test('the airing program is first, so the cursor opens at index 0', () {
      final programs = scheduleFromNow(
        [_p('old', 8, 10), _p('airing', 12, 14), _p('next', 14, 16)],
        _at(13),
      );

      expect(scheduleNowIndex(programs, _at(13)), 0);
      expect(scheduleFocusIndex(programs, _at(13)), 0);
    });

    test('in a gap, the cursor opens on the next program to start', () {
      // The feed has real holes, so "nothing is airing" is routine.
      final programs = scheduleFromNow(
        [_p('old', 8, 10), _p('after gap', 14, 16)],
        _at(12),
      );

      expect(scheduleNowIndex(programs, _at(12)), -1);
      expect(scheduleFocusIndex(programs, _at(12)), 0);
    });
  });
}
