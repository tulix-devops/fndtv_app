import 'package:flutter_test/flutter_test.dart';
import 'package:fndtv/src/ui/pages/updates/tv_updates_page.dart';

void main() {
  _statusTests();
  group('compareVersionNames', () {
    test('equal versions compare equal', () {
      expect(compareVersionNames('0.0.11', '0.0.11'), 0);
    });

    test('compares numerically, not lexicographically', () {
      // The case string equality gets wrong: "0.0.9" sorts AFTER "0.0.10".
      expect(compareVersionNames('0.0.9', '0.0.10'), lessThan(0));
      expect(compareVersionNames('0.0.10', '0.0.9'), greaterThan(0));
    });

    test('ignores a +build suffix on either side', () {
      // The box reports "0.0.11"; the server may advertise "0.0.11+12". Those
      // are the same release and must not read as an available update.
      expect(compareVersionNames('0.0.11', '0.0.11+12'), 0);
      expect(compareVersionNames('0.0.11+12', '0.0.11'), 0);
    });

    test('tolerates differing component counts', () {
      expect(compareVersionNames('1.0', '1.0.0'), 0);
      expect(compareVersionNames('1.0', '1.0.1'), lessThan(0));
    });

    test('unparseable input degrades to equal rather than nagging', () {
      // A malformed server value must not put the whole fleet into a permanent
      // "update available" state.
      expect(compareVersionNames('0.0.11', 'unknown'), greaterThan(0));
      expect(compareVersionNames('', ''), 0);
    });

    test('major and minor bumps are detected', () {
      expect(compareVersionNames('0.0.11', '0.1.0'), lessThan(0));
      expect(compareVersionNames('0.9.9', '1.0.0'), lessThan(0));
    });
  });
}

void _statusTests() {
  group('resolveUpdateStatus', () {
    test('same version, no pending attempt -> up to date', () {
      expect(
        resolveUpdateStatus(local: '0.0.11', latest: '0.0.11'),
        UpdateScreenStatus.upToDate,
      );
    });

    test('newer advertised, no pending attempt -> available', () {
      expect(
        resolveUpdateStatus(local: '0.0.11', latest: '0.0.12'),
        UpdateScreenStatus.available,
      );
    });

    test('attempted an install that did not land -> installFailed', () {
      // The case that used to look identical to "never started": Android
      // refused the APK (downgrade / cancelled) and we stayed put.
      expect(
        resolveUpdateStatus(
            local: '0.0.3', latest: '0.0.12', attempted: '0.0.12'),
        UpdateScreenStatus.installFailed,
      );
    });

    test('attempted install that DID land -> up to date, not failed', () {
      expect(
        resolveUpdateStatus(
            local: '0.0.12', latest: '0.0.12', attempted: '0.0.12'),
        UpdateScreenStatus.upToDate,
      );
    });

    test('stale attempt older than what is running is not a failure', () {
      // Box moved on by some other route (sideload); the leftover record must
      // not accuse a healthy box of a failed install.
      expect(
        resolveUpdateStatus(
            local: '0.0.12', latest: '0.0.12', attempted: '0.0.9'),
        UpdateScreenStatus.upToDate,
      );
    });

    test('empty latest (server said nothing) -> up to date, never nags', () {
      expect(
        resolveUpdateStatus(local: '0.0.11', latest: ''),
        UpdateScreenStatus.upToDate,
      );
    });
  });
}
