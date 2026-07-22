import 'package:flutter_test/flutter_test.dart';
import 'package:fndtv/src/core/audio/radio_metadata.dart';

void main() {
  group('RadioMetadata.parse', () {
    test('splits "Artist - Title" on the first separator', () {
      final m = RadioMetadata.parse('Édith Piaf - La Vie en rose');
      expect(m, isNotNull);
      expect(m!.artist, 'Édith Piaf');
      expect(m.title, 'La Vie en rose');
      expect(m.display, 'Édith Piaf — La Vie en rose');
    });

    test('bare title has no artist', () {
      final m = RadioMetadata.parse('News Bulletin');
      expect(m!.artist, isNull);
      expect(m.title, 'News Bulletin');
      expect(m.display, 'News Bulletin');
    });

    test('extra dashes: split only on the first " - "', () {
      final m = RadioMetadata.parse('Artist - Song - Remix');
      expect(m!.artist, 'Artist');
      expect(m.title, 'Song - Remix');
    });

    test('trims surrounding whitespace', () {
      final m = RadioMetadata.parse('  Daft Punk  -  One More Time  ');
      expect(m!.artist, 'Daft Punk');
      expect(m.title, 'One More Time');
    });

    test('empty / whitespace / null / lone separator return null', () {
      expect(RadioMetadata.parse(''), isNull);
      expect(RadioMetadata.parse('   '), isNull);
      expect(RadioMetadata.parse(null), isNull);
      expect(RadioMetadata.parse(' - '), isNull);
    });

    test('empty artist side falls back to a title-only entry', () {
      final m = RadioMetadata.parse(' - Just A Title');
      expect(m!.artist, isNull);
      expect(m.title, 'Just A Title');
    });

    test('equality by value', () {
      expect(
        RadioMetadata.parse('A - B'),
        RadioMetadata.parse('A - B'),
      );
      expect(
        RadioMetadata.parse('A - B'),
        isNot(RadioMetadata.parse('A - C')),
      );
    });
  });
}
