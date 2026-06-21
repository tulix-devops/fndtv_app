import 'package:app_logger/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';

/// App-wide radio playback. A single [AudioPlayer] streams the selected radio
/// channel; tagging each source with a [MediaItem] lets `just_audio_background`
/// surface the Spotify-style media notification / lock-screen controls and keep
/// audio alive when the app is in the background.
class RadioPlayerService {
  RadioPlayerService._() {
    // Mirror player state + playback errors to the logs so we can see exactly
    // what the radio is doing while it plays.
    _player.playerStateStream.listen((state) {
      logger.d('[Radio] state: processing=${state.processingState.name} '
          'playing=${state.playing} '
          'for "${currentChannel.value?.title ?? '-'}"');
    });
    _player.playbackEventStream.listen(
      (_) {},
      onError: (Object err, StackTrace st) =>
          logger.e('[Radio] playback error: $err', stacktrace: st),
    );
  }
  static final RadioPlayerService instance = RadioPlayerService._();

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  /// The channel currently loaded into the player (null = nothing playing).
  /// Drives the in-app mini-player bar's visibility.
  final ValueNotifier<LiveModel?> currentChannel = ValueNotifier<LiveModel?>(null);

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  bool get isPlaying => _player.playing;

  /// Starts (or resumes) a channel. If the same channel is already loaded we
  /// just toggle resume; switching channels swaps the audio source.
  Future<void> play(LiveModel channel) async {
    final s = channel.sources;
    final url = s.getPreferredVideoSource() ?? '';

    // Dump everything we know about this channel before we try to play it.
    logger.i('[Radio] ▶ play request: "${channel.title}" '
        '(id=${channel.id}, type=${channel.type}, '
        'lang=${channel.details?.language ?? '-'})');
    logger.d('[Radio] source candidates → '
        'primary=${s.primary} | secondary=${s.secondary} | '
        'hls=${s.hls} | dash=${s.dash} | file=${s.file}');
    logger.i('[Radio] chosen URL → ${url.isEmpty ? '(none)' : url}');

    if (url.isEmpty) {
      logger.w('[Radio] no playable URL for "${channel.title}" — aborting');
      return;
    }

    if (currentChannel.value?.id == channel.id) {
      logger.d('[Radio] same channel already loaded → resume');
      if (!_player.playing) await _player.play();
      return;
    }

    currentChannel.value = channel;

    final art = channel.images.getBanner();
    logger.d('[Radio] artwork → ${art.isEmpty ? '(none)' : art}');
    try {
      logger.d('[Radio] setAudioSource…');
      final duration = await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(
            id: channel.id.toString(),
            // Title (bold line) = station; artist (subtitle) = brand + live tag.
            title: channel.title,
            artist: 'FNDTV Radio · Live',
            album: 'FNDTV Radio',
            artUri: art.startsWith('http') ? Uri.tryParse(art) : null,
            displayTitle: channel.title,
            displaySubtitle: 'FNDTV Radio · Live',
          ),
        ),
      );
      logger.i('[Radio] source loaded (reported duration: '
          '${duration?.toString() ?? 'live/unknown'}) → play()');
      await _player.play();
    } catch (err, st) {
      logger.e('[Radio] failed to load "${channel.title}" '
          '(url=$url): $err', stacktrace: st);
      currentChannel.value = null;
    }
  }

  /// Play/pause the currently loaded channel.
  Future<void> toggle() async {
    if (_player.playing) {
      logger.d('[Radio] ⏸ pause "${currentChannel.value?.title ?? '-'}"');
      await _player.pause();
    } else {
      logger.d('[Radio] ▶ resume "${currentChannel.value?.title ?? '-'}"');
      await _player.play();
    }
  }

  /// Whether [channel] is the one currently loaded.
  bool isCurrent(LiveModel channel) => currentChannel.value?.id == channel.id;

  /// Stop playback and dismiss the mini-player / notification.
  Future<void> stop() async {
    logger.i('[Radio] ⏹ stop "${currentChannel.value?.title ?? '-'}"');
    await _player.stop();
    currentChannel.value = null;
  }
}
