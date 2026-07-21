import 'package:local_storage/local_storage.dart';

/// Persists the last-played channel + playback position so archive/DVR content
/// resumes where the viewer left off (e.g. after the box sleeps/wakes).
///
/// STB, non-live only — live streams have no meaningful resume position. Does
/// NOT auto-launch anything on boot; it only supplies a resume offset when the
/// same channel is opened again.
class StbResumeStore {
  StbResumeStore(this._storage);

  final LocalStorage _storage;

  static const String _kChannel = 'stb_resume_channel';
  static const String _kPositionMs = 'stb_resume_position_ms';

  /// Minimum offset worth resuming (ignore the first few seconds).
  static const int _minResumeMs = 3000;

  Future<void> save(String channelId, int positionMs) async {
    if (positionMs < _minResumeMs) return;
    await _storage.store<String>(_kChannel, channelId);
    await _storage.store<String>(_kPositionMs, positionMs.toString());
  }

  /// Returns the saved position for [channelId], or null if the last saved
  /// channel was different (or nothing was saved).
  Future<int?> positionFor(String channelId) async {
    final saved = await _storage.get<String>(_kChannel);
    if (saved != channelId) return null;
    final pos = await _storage.get<String>(_kPositionMs);
    final ms = int.tryParse(pos ?? '');
    return (ms != null && ms >= _minResumeMs) ? ms : null;
  }

  Future<void> clear() async {
    await _storage.delete(_kChannel);
    await _storage.delete(_kPositionMs);
  }
}
