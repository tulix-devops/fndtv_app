import 'dart:async';

import 'package:app_localization/app_localization.dart';
import 'package:app_logger/app_logger.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show PlatformViewHitTestBehavior;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/data/repositories/content/content_repository.dart';
import 'package:fndtv/src/ui/widgets/stb_screen_size/stb_screen_size.dart';
import 'package:fndtv/src/ui/widgets/stb_video_player/stb_schedule_strip.dart';
import 'package:ui_kit/ui_kit.dart';

/// Video player that renders into a REAL Android [SurfaceView] via a platform
/// view, instead of into a Flutter texture.
///
/// **Why.** media_kit/mpv, `video_player` and flutter_vlc_player all render into
/// a Flutter SurfaceTexture. On the legacy RK3328 boxes that forces mpv onto
/// `mediacodec-copy`, where every decoded frame costs a ~2.3 MB memcpy out of
/// MediaCodec plus a GL upload — paid whether or not the frame is displayed. The
/// feed is 1080i50, bob-deinterlaced by the Rockchip IEP into 50 fps, so the box
/// pays that 50x/second to carry 25 frames of information and runs ~20% short of
/// realtime. That is the slow motion. On a real SurfaceView the decoder writes
/// into a buffer SurfaceFlinger scans out directly: no copy, no upload, and a
/// dropped frame costs nothing.
///
/// **Composition mode matters.** This MUST use `initExpensiveAndroidView`, which
/// forces true hybrid composition and keeps a real SurfaceView in the native view
/// hierarchy. The plain [AndroidView] widget uses Texture Layer Hybrid
/// Composition, which renders the platform view into a SurfaceTexture — i.e.
/// exactly the path this class exists to escape.
///
/// Feature parity with the mpv player is deliberate: the schedule strip, D-pad
/// map and Back handling below mirror `StbVideoPlayer` so a viewer cannot tell
/// which engine their box happens to use.
///
/// See `StbSurfacePlayer.kt` for the engine side (MediaPlayer first, ExoPlayer
/// second, both on the same SurfaceView).
class StbSurfacePlayer extends StatefulWidget {
  const StbSurfacePlayer({
    super.key,
    required this.video,
    required this.link,
    required this.contentType,
    this.onUnplayable,
  });

  final LiveModel video;
  final String link;
  final ContentType contentType;

  /// Called when BOTH native engines failed to produce a single frame, so the
  /// caller can hand this stream to another player entirely.
  ///
  /// Deliberately NOT fired for a mid-stream failure: losing picture after
  /// playing means the decoder was fine and the stream broke, which switching
  /// engines does not fix.
  final VoidCallback? onUnplayable;

  static const String viewType = 'com.fndtv.videoplayer/surface_player';

  @override
  State<StbSurfacePlayer> createState() => _StbSurfacePlayerState();
}

class _StbSurfacePlayerState extends State<StbSurfacePlayer> {
  static const Duration _controlsTimeout = Duration(seconds: 4);
  static const Duration _positionPoll = Duration(seconds: 1);

  // ------------------------------------------------------------ EPG / strip
  // Info-only: the backend gives every program the channel's own live URL and a
  // null `dvr_url`, so there is nothing per-program to play — see
  // [StbScheduleStrip]. Up opens; Up, Down or Back closes; ←/→ move the cursor.
  static const Duration _epgIdleTimeout = Duration(seconds: 12);

  /// How long a fetched schedule is reused before going back to the network.
  static const Duration _epgMaxAge = Duration(minutes: 3);

  bool _epgOpen = false;
  int _epgIndex = 0;
  ScheduleStatus _epgStatus = ScheduleStatus.loading;
  List<LiveModel> _epgPrograms = const [];
  DateTime? _epgLoadedAt;
  Timer? _epgIdleTimer;

  /// A request is in flight. Tracked separately from [_epgStatus] because that
  /// starts out `loading`, so it cannot distinguish "never fetched" from
  /// "fetching now".
  bool _epgFetching = false;

  // --------------------------------------------------------------- playback
  MethodChannel? _method;
  StreamSubscription<dynamic>? _eventSub;
  Timer? _controlsTimer;
  Timer? _positionTimer;

  final FocusNode _focusNode = FocusNode();

  bool _buffering = true;
  bool _playing = false;

  /// Resets on an engine swap — drives the spinner.
  bool _firstFrame = false;

  /// Never resets — records whether ANY engine produced picture, which decides
  /// error-overlay vs hand-off (see [StbSurfacePlayer.onUnplayable]).
  bool _everHadFrame = false;
  String? _error;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  bool _controlsVisible = true;

  // ─── Screen-size calibration (↓ opens; ↑ is taken by the schedule) ─────────
  //
  // The value itself lives in the shared controller and is applied ONCE at the
  // app root, so there is no scaler here — the video shrinks because the whole
  // app does. Scaling again locally would apply it twice.
  final StbScreenSizeController _screenSizeController =
      StbScreenSizeController.instance;
  bool _screenSizeOpen = false;

  /// Live channels aren't scrubbable; only the DVR/archive stream is.
  bool get _isLive => widget.contentType != ContentType.dvr;

  /// A DVR item is a single program — it carries no `seasons` of its own, so the
  /// strip is offered on live channels only.
  bool get _epgAvailable => _isLive;

  int get _epgNowIndex => scheduleNowIndex(_epgPrograms, DateTime.now());
  int get _epgFocusIndex => scheduleFocusIndex(_epgPrograms, DateTime.now());

  @override
  void initState() {
    super.initState();
    logger.i('[STB-surface] opening ${widget.link} (${widget.contentType})');
    _scheduleHideControls();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _positionTimer?.cancel();
    _epgIdleTimer?.cancel();
    _eventSub?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onPlatformViewCreated(int id) {
    _method = MethodChannel('${StbSurfacePlayer.viewType}/$id');
    _eventSub = EventChannel('${StbSurfacePlayer.viewType}/$id/events')
        .receiveBroadcastStream()
        .listen(_onEvent, onError: (Object e) {
      logger.w('[STB-surface] event channel error: $e');
    });
    _positionTimer = Timer.periodic(_positionPoll, (_) => _pollPosition());
  }

  Future<void> _pollPosition() async {
    if (_method == null || _error != null) return;
    try {
      final ms = await _method!.invokeMethod<int>('position');
      if (!mounted || ms == null) return;
      setState(() => _position = Duration(milliseconds: ms));
    } catch (_) {
      // A dead channel is already reported through the error event.
    }
  }

  void _onEvent(dynamic raw) {
    if (raw is! Map) return;
    final map = Map<String, dynamic>.from(raw);
    if (!mounted) return;
    switch (map['event'] as String?) {
      case 'engine':
        // Engine choice is a logcat-only diagnostic now; nothing on screen.
        logger.i('[STB-surface] engine=${map['name']}');
        setState(() => _firstFrame = false);
      case 'buffering':
        setState(() => _buffering = map['value'] == true);
      case 'playing':
        setState(() => _playing = map['value'] == true);
      case 'firstFrame':
        logger.i('[STB-surface] first frame');
        _everHadFrame = true;
        setState(() {
          _firstFrame = true;
          _buffering = false;
        });
      case 'initialized':
        final ms = (map['durationMs'] as num?)?.toInt() ?? 0;
        setState(() => _duration = Duration(milliseconds: ms));
      case 'size':
        logger.i('[STB-surface] video ${map['width']}x${map['height']} '
            'displayAspect=${map['displayAspect']}');
      case 'stats':
        logger.i('[STB-surface] perf dropped=${map['droppedFrames']}');
      case 'completed':
        setState(() => _playing = false);
      case 'error':
        final message = map['message'] as String? ?? 'unknown';
        logger.w('[STB-surface] error: $message');
        if (!_everHadFrame && widget.onUnplayable != null) {
          logger.w('[STB-surface] no engine could start this stream — '
              'handing back for the mpv path');
          widget.onUnplayable!();
          return;
        }
        setState(() {
          _error = message;
          _buffering = false;
        });
    }
  }

  // ------------------------------------------------------------------- EPG

  Future<void> _loadEpg() async {
    if (_epgFetching) return;
    // Read the repository before the first await — `context` must not be
    // touched across an async gap.
    final repo = context.read<ContentRepository>();
    _epgFetching = true;

    final bool cold = _epgPrograms.isEmpty;
    if (cold) setState(() => _epgStatus = ScheduleStatus.loading);

    try {
      final res = await repo.getContentDetail(
        contentType: widget.video.typeId,
        id: widget.video.id,
      );
      final LiveModel? data = switch (res) {
        SuccessModel<LiveModel>() => res.data,
        PaginatedModel<LiveModel>() => res.data,
        _ => null,
      };
      if (!mounted) return;
      if (data == null) {
        // A failed refresh keeps the cached programs; `_epgLoadedAt` is left
        // alone so the next open retries.
        if (cold) setState(() => _epgStatus = ScheduleStatus.error);
        return;
      }
      final programs = sortedByStart(data.scheduleItems);
      setState(() {
        _epgPrograms = programs;
        _epgLoadedAt = DateTime.now();
        _epgStatus =
            programs.isEmpty ? ScheduleStatus.empty : ScheduleStatus.ready;
        // Only a cold load positions the cursor; a refresh landing mid-browse
        // must not yank it out from under the viewer.
        _epgIndex = cold
            ? _epgFocusIndex
            : _epgIndex.clamp(0, programs.isEmpty ? 0 : programs.length - 1);
      });
    } catch (e) {
      logger.w('[STB-surface] schedule load failed: $e');
      if (mounted && cold) setState(() => _epgStatus = ScheduleStatus.error);
    } finally {
      _epgFetching = false;
    }
  }

  void _openEpg() {
    final loadedAt = _epgLoadedAt;
    final stale =
        loadedAt == null || DateTime.now().difference(loadedAt) > _epgMaxAge;
    setState(() {
      _epgOpen = true;
      if (_epgPrograms.isNotEmpty) _epgIndex = _epgFocusIndex;
    });
    if (stale) {
      unawaited(_loadEpg());
    } else {
      final age = DateTime.now().difference(loadedAt).inSeconds;
      logger.d('[STB-surface] schedule served from cache (${age}s old, '
          'TTL ${_epgMaxAge.inMinutes}m)');
    }
    _controlsTimer?.cancel(); // the strip owns the screen while it is open
    _resetEpgIdleTimer();
  }

  void _closeEpg() {
    _epgIdleTimer?.cancel();
    if (_epgOpen) setState(() => _epgOpen = false);
    _revealControls();
  }

  /// Closes the strip if the remote goes quiet — a kiosk box is often left
  /// unattended, and a panel pinned over the video forever is worse than one
  /// that tidies itself away.
  void _resetEpgIdleTimer() {
    _epgIdleTimer?.cancel();
    _epgIdleTimer = Timer(_epgIdleTimeout, () {
      if (mounted && _epgOpen) _closeEpg();
    });
  }

  // ---------------------------------------------------------- screen size


  void _openScreenSize() {
    _controlsTimer?.cancel(); // the panel owns the screen while it is open
    setState(() => _screenSizeOpen = true);
  }

  Future<void> _saveScreenSize() async {
    setState(() => _screenSizeOpen = false);
    await _screenSizeController.save(_screenSizeController.value);
    _revealControls();
  }

  /// Back discards the fiddling and restores the last saved value — a viewer who
  /// has made the picture worse must always have a way out.
  void _cancelScreenSize() {
    _screenSizeController.revert();
    setState(() => _screenSizeOpen = false);
    _revealControls();
  }

  void _nudgeScreenSize({double dw = 0, double dh = 0}) {
    _screenSizeController
        .preview(_screenSizeController.value.nudgeWidth(dw).nudgeHeight(dh));
  }

  void _moveEpgCursor(int delta) {
    if (_epgPrograms.isEmpty) return;
    final next = (_epgIndex + delta).clamp(0, _epgPrograms.length - 1);
    if (next != _epgIndex) setState(() => _epgIndex = next);
    _resetEpgIdleTimer();
  }

  // -------------------------------------------------------------- transport

  void _revealControls() {
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    _scheduleHideControls();
  }

  void _scheduleHideControls() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(_controlsTimeout, () {
      if (mounted && !_epgOpen) setState(() => _controlsVisible = false);
    });
  }

  Future<void> _togglePlay() async {
    _revealControls();
    await _method?.invokeMethod<void>(_playing ? 'pause' : 'play');
  }

  Future<void> _seekBy(Duration delta) async {
    if (_isLive) return;
    _revealControls();
    final target = _position + delta;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (_duration > Duration.zero && target > _duration ? _duration : target);
    await _method?.invokeMethod<void>(
      'seekTo',
      {'positionMs': clamped.inMilliseconds},
    );
    if (mounted) setState(() => _position = clamped);
  }

  Future<void> _retry() async {
    setState(() {
      _error = null;
      _buffering = true;
      _firstFrame = false;
    });
    await _method?.invokeMethod<void>(
      'open',
      {'url': widget.link, 'autoplay': true},
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    // The screen-size panel takes the whole D-pad while it is open: ←/→ resize
    // width, ↑/↓ resize height, OK saves. Back is handled by the [PopScope].
    if (_screenSizeOpen) {
      switch (key) {
        case LogicalKeyboardKey.arrowLeft:
          _nudgeScreenSize(dw: -StbScreenSize.step);
        case LogicalKeyboardKey.arrowRight:
          _nudgeScreenSize(dw: StbScreenSize.step);
        case LogicalKeyboardKey.arrowUp:
          _nudgeScreenSize(dh: StbScreenSize.step);
        case LogicalKeyboardKey.arrowDown:
          _nudgeScreenSize(dh: -StbScreenSize.step);
        case LogicalKeyboardKey.select:
        case LogicalKeyboardKey.enter:
        case LogicalKeyboardKey.space:
          unawaited(_saveScreenSize());
        case LogicalKeyboardKey.escape:
          _cancelScreenSize();
      }
      return KeyEventResult.handled;
    }

    // While the strip is up it owns the D-pad: ←/→ move the cursor and BOTH ↑
    // and ↓ dismiss it. Back is deliberately absent — the [PopScope] in `build`
    // is the sole authority (see the note there).
    if (_epgOpen) {
      if (key == LogicalKeyboardKey.escape ||
          key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.arrowUp) {
        _closeEpg();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowLeft) {
        _moveEpgCursor(-1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowRight) {
        _moveEpgCursor(1);
        return KeyEventResult.handled;
      }
      _resetEpgIdleTimer();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp && _epgAvailable) {
      _openEpg();
      return KeyEventResult.handled;
    }

    // ↓ opens the picture calibration. ↑ is the schedule, so this is the
    // natural pair — and ↓ was otherwise doing nothing but revealing controls.
    if (key == LogicalKeyboardKey.arrowDown) {
      _openScreenSize();
      return KeyEventResult.handled;
    }

    switch (key) {
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.mediaPlayPause:
        unawaited(_togglePlay());
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        unawaited(_seekBy(const Duration(seconds: -10)));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        unawaited(_seekBy(const Duration(seconds: 10)));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        // Keyboard convenience only. The remote's Back arrives as a platform
        // pop, not a key event; popping here too would fire twice.
        Navigator.of(context).maybePop();
        return KeyEventResult.handled;
      default:
        _revealControls();
        return KeyEventResult.ignored;
    }
  }

  /// True hybrid composition — see the class doc for why this cannot be a plain
  /// [AndroidView].
  Widget _buildSurface() {
    return PlatformViewLink(
      viewType: StbSurfacePlayer.viewType,
      surfaceFactory: (context, controller) => AndroidViewSurface(
        controller: controller as AndroidViewController,
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
      ),
      onCreatePlatformView: (params) {
        final controller = PlatformViewsService.initExpensiveAndroidView(
          id: params.id,
          viewType: StbSurfacePlayer.viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: <String, dynamic>{
            'url': widget.link,
            'autoplay': true,
          },
          creationParamsCodec: const StandardMessageCodec(),
          onFocus: () => params.onFocusChanged(true),
        )
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..addOnPlatformViewCreatedListener(_onPlatformViewCreated)
          ..create();
        return controller;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final showSpinner = _error == null && (!_firstFrame || _buffering);
    final showControls = _controlsVisible && _error == null;
    final showTopBar = showControls || _epgOpen || _error != null;

    // Back is handled here and ONLY here. Android routes the remote's Back to
    // the framework as a pop request; popping from [_onKey] as well meant one
    // press could pop twice, dropping the viewer out of the app entirely.
    return PopScope(
      canPop: !_epgOpen && !_screenSizeOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_screenSizeOpen) {
          _cancelScreenSize();
        } else {
          _closeEpg();
        }
      },
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: _onKey,
        child: GestureDetector(
          onTap: _revealControls,
          child: ColoredBox(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_error == null)
                  _buildSurface(),

                if (showSpinner)
                  Center(
                    child: CircularProgressIndicator(
                      color: context.uiColors.primary,
                    ),
                  ),

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _SurfaceTopBar(
                    title: widget.video.title,
                    visible: showTopBar,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                ),

                if (showControls && !_epgOpen)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _SurfaceBottomBar(
                      playing: _playing,
                      isLive: _isLive,
                      position: _position,
                      duration: _duration,
                      onPlayPause: _togglePlay,
                      scheduleHint:
                          _epgAvailable ? context.l.sectionSchedule : null,
                    ),
                  ),

                // Bottom third: the EPG strip, over the video and the controls.
                if (_epgAvailable)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: StbScheduleStrip(
                      visible: _epgOpen,
                      status: _epgStatus,
                      programs: _epgPrograms,
                      selectedIndex: _epgIndex,
                      nowIndex: _epgNowIndex,
                      onRetry: _loadEpg,
                    ),
                  ),

                // Last, so it outranks the strip: a dead stream makes Retry the
                // only thing that matters.
                if (_error != null)
                  _SurfaceErrorOverlay(onRetry: _retry, detail: _error),

                // Topmost: calibration must sit above everything, including the
                // strip and the error overlay.
                StbScreenSizeOverlay(
                  size: _screenSizeController.value,
                  savedSize: _screenSizeController.saved,
                  visible: _screenSizeOpen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SurfaceTopBar extends StatelessWidget {
  const _SurfaceTopBar({
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
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !visible,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurfaceBottomBar extends StatelessWidget {
  const _SurfaceBottomBar({
    required this.playing,
    required this.isLive,
    required this.position,
    required this.duration,
    required this.onPlayPause,
    this.scheduleHint,
  });

  final bool playing;
  final bool isLive;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayPause;

  /// "Schedule" label shown beside a ↑ glyph, so the strip is discoverable.
  final String? scheduleHint;

  static String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPlayPause,
            icon: Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 12),
          if (isLive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: context.uiColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            Text(
              '${_fmt(position)} / ${_fmt(duration)}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          const Spacer(),
          if (scheduleHint != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.keyboard_arrow_up_rounded,
                    color: Colors.white70, size: 22),
                const SizedBox(width: 4),
                Text(
                  scheduleHint!,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SurfaceErrorOverlay extends StatelessWidget {
  const _SurfaceErrorOverlay({required this.onRetry, this.detail});

  final VoidCallback onRetry;
  final String? detail;

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
          if (detail != null && detail!.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: 640,
              child: Text(
                detail!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          ],
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
