import 'package:flutter_test/flutter_test.dart';
import 'package:fndtv/src/ui/widgets/stb_surface_player/stb_surface_player.dart';

void main() {
  group('shouldHandOffToMpv', () {
    test('hands off a stream that has never drawn on this box', () {
      expect(
        shouldHandOffToMpv(
          everHadFrame: false,
          provenPlayable: false,
          hasCallback: true,
        ),
        isTrue,
      );
    });

    test('does NOT hand off after a restart of a stream that played', () {
      // The reported case: paused a film, restarted it, and it came back in
      // slow motion on the other player. `everHadFrame` is false on a fresh
      // open, so only the session record can stop the hand-off.
      expect(
        shouldHandOffToMpv(
          everHadFrame: false,
          provenPlayable: true,
          hasCallback: true,
        ),
        isFalse,
      );
    });

    test('does NOT hand off once this instance has drawn', () {
      // Mid-stream failure: the decoder was fine and the stream broke, which
      // switching engines does not fix.
      expect(
        shouldHandOffToMpv(
          everHadFrame: true,
          provenPlayable: false,
          hasCallback: true,
        ),
        isFalse,
      );
    });

    test('does nothing without a callback (mpv already in use)', () {
      expect(
        shouldHandOffToMpv(
          everHadFrame: false,
          provenPlayable: false,
          hasCallback: false,
        ),
        isFalse,
      );
    });
  });
}
