import 'dart:async';

import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_storage/local_storage.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:fndtv/src/core/services/stb_resume_store.dart';
import 'package:fndtv/src/core/services/stb_system_service.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:ui_kit/ui_kit.dart';

/// Set-top-box (RK3328) video player backed by **mpv** (media_kit) instead of
/// ExoPlayer/Media3.
///
/// Media3's MediaCodec path fails to play the HLS streams on Rockchip boxes
/// even though the hardware decoder itself is capable (proven with other
/// players). libmpv initializes the hardware decoder over a different path
/// (and can fall back to software), so it plays where ExoPlayer won't.
///
/// Only used on the `stb` flavor (see [VideoPlayerPage]); mobile keeps the
/// existing `video_player`-based `AppVideoPlayer` unchanged.
///
/// D-pad: OK/center = play·pause, ←/→ = seek ±10s (archive only), Back = exit.
class StbVideoPlayer extends StatefulWidget {
  const StbVideoPlayer({
    super.key,
    required this.link,
    required this.video,
    required this.contentType,
  });

  final String link;
  final LiveModel video;
  final ContentType contentType;

  @override
  State<StbVideoPlayer> createState() => _StbVideoPlayerState();
}

class _StbVideoPlayerState extends State<StbVideoPlayer> {
  late final Player _player;
  late final VideoController _controller;
  final FocusNode _focusNode = FocusNode();

  final List<StreamSubscription<dynamic>> _subs = [];

  bool _playing = false;
  bool _buffering = true;
  String? _error;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  bool _controlsVisible = true;
  Timer? _hideTimer;

  // §6 resume: persist last channel + position (archive/DVR only) so it picks
  // up where the viewer left off (e.g. after the box sleeps/wakes). Does not
  // auto-launch anything on boot.
  StbResumeStore? _resume;
  int? _pendingResumeMs;
  bool _resumed = false;
  DateTime _lastSave = DateTime.fromMillisecondsSinceEpoch(0);

  /// Live channels aren't scrubbable; only the DVR/archive stream is.
  bool get _isLive => widget.contentType != ContentType.dvr;

  String get _channelId => widget.video.id.toString();

  @override
  void initState() {
    super.initState();
    MediaKit.ensureInitialized();
    _player = Player();
    // Hardware acceleration is on by default; libmpv picks the mediacodec
    // hwdec on the box and degrades to software if it must.
    _controller = VideoController(_player);
    if (!_isLive && StbSystemService.isStb) {
      _resume = StbResumeStore(context.read<LocalStorage>());
      _resume!.positionFor(_channelId).then((ms) {
        if (mounted) _pendingResumeMs = ms;
      });
    }
    _subscribe();
    _open();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _scheduleHideControls();
    });
  }

  void _open() {
    _error = null;
    _player.open(Media(widget.link)); // autoplays
  }

  void _subscribe() {
    _subs.add(_player.stream.playing.listen((v) {
      if (!mounted) return;
      setState(() => _playing = v);
      // Keep the controls up while paused; resume the auto-hide once playing.
      if (v) {
        _scheduleHideControls();
      } else {
        _hideTimer?.cancel();
        _controlsVisible = true;
      }
    }));
    _subs.add(_player.stream.buffering.listen((v) {
      if (mounted) setState(() => _buffering = v);
    }));
    _subs.add(_player.stream.error.listen((e) {
      if (mounted) setState(() => _error = e);
    }));
    _subs.add(_player.stream.position.listen((p) {
      if (!mounted || _isLive) return;
      setState(() => _position = p);
      _maybeResume();
      _maybeSave(p);
    }));
    _subs.add(_player.stream.duration.listen((d) {
      if (mounted && !_isLive) setState(() => _duration = d);
    }));
  }

  /// Seeks to the saved offset once, after the media has loaded far enough.
  void _maybeResume() {
    final ms = _pendingResumeMs;
    if (_resumed || ms == null) return;
    if (_duration.inMilliseconds <= 0 || ms >= _duration.inMilliseconds) return;
    _resumed = true;
    _pendingResumeMs = null;
    _player.seek(Duration(milliseconds: ms));
  }

  /// Persists the current position at most once every 5s.
  void _maybeSave(Duration p) {
    final now = DateTime.now();
    if (now.difference(_lastSave).inSeconds < 5) return;
    _lastSave = now;
    _resume?.save(_channelId, p.inMilliseconds);
  }

  Future<void> _retry() async {
    setState(() {
      _error = null;
      _buffering = true;
    });
    await _player.open(Media(widget.link));
    _revealControls();
  }

  void _togglePlay() {
    _player.playOrPause();
    _revealControls();
  }

  void _seekBy(int seconds) {
    if (_isLive || _duration == Duration.zero) return;
    var target = _position + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (target > _duration) target = _duration;
    _player.seek(target);
    setState(() => _position = target);
    _revealControls();
  }

  void _scheduleHideControls() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _playing) setState(() => _controlsVisible = false);
    });
  }

  void _revealControls() {
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    _scheduleHideControls();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.goBack || key == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.mediaPlayPause) {
      _togglePlay();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaPlay) {
      _player.play();
      _revealControls();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaPause) {
      _player.pause();
      _revealControls();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      if (!_isLive) {
        _seekBy(-10);
        return KeyEventResult.handled;
      }
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      if (!_isLive) {
        _seekBy(10);
        return KeyEventResult.handled;
      }
    }
    _revealControls();
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    // Persist the final position so archive resumes where it left off.
    if (!_isLive && _position.inMilliseconds > 0) {
      _resume?.save(_channelId, _position.inMilliseconds);
    }
    _hideTimer?.cancel();
    _focusNode.dispose();
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showSpinner = _error == null && (!_playing || _buffering);
    final bool showControls = _controlsVisible && _error == null;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      child: GestureDetector(
        onTap: _revealControls,
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_error == null)
                Video(
                  controller: _controller,
                  controls: NoVideoControls,
                  fit: BoxFit.contain,
                ),

              if (showSpinner)
                Center(
                  child: CircularProgressIndicator(
                    color: context.uiColors.primary,
                  ),
                ),

              if (_error != null) _ErrorOverlay(onRetry: _retry),

              // Top-left: back + channel title.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _TopBar(
                  title: widget.video.title,
                  visible: showControls,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
              ),

              // Bottom: play/pause + (archive) seek bar or LIVE badge.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BottomBar(
                  visible: showControls,
                  playing: _playing,
                  isLive: _isLive,
                  position: _position,
                  duration: _duration,
                  onPlayPause: _togglePlay,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.visible,
    required this.onBack,
  });

  final String title;
  final bool visible;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      child: IgnorePointer(
        ignoring: !visible,
        child: Container(
          height: 92,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onBack,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.h5.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bottom bar (play/pause + seek / live) ────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.visible,
    required this.playing,
    required this.isLive,
    required this.position,
    required this.duration,
    required this.onPlayPause,
  });

  final bool visible;
  final bool playing;
  final bool isLive;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayPause;

  static String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.uiColors.primary;
    final double progress = (!isLive && duration.inMilliseconds > 0)
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      child: IgnorePointer(
        ignoring: !visible,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
          child: Row(
            children: [
              // Play / pause button.
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: onPlayPause,
                  icon: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              // Wrapped in a single Expanded so the child (live pill's Spacer
              // or the seek bar's Expanded) always gets bounded width.
              Expanded(
                child: isLive
                    ? _LivePill(accent: accent)
                    : Row(
                        children: [
                          Text(_fmt(position),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: Colors.white24,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(accent),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(_fmt(duration),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14)),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        const Text('LIVE',
            style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
        const Spacer(),
      ],
    );
  }
}

// ─── Error overlay ────────────────────────────────────────────────────────────

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.white54, size: 56),
          const SizedBox(height: 16),
          const Text('Playback failed',
              style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            autofocus: true,
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.uiColors.primary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
