import 'dart:async';

import 'package:app_localization/app_localization.dart';
import 'package:app_logger/app_logger.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:local_storage/local_storage.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
// Not exported by media_kit_video's barrel; needed to reach
// [AndroidVideoController.videoParamsSubscription] for the surface-size lock.
// Pinned to media_kit_video 1.3.1 — revisit on upgrade.
// ignore: implementation_imports
import 'package:media_kit_video/src/video_controller/android_video_controller/android_video_controller.dart'
    show AndroidVideoController;
import 'package:fndtv/src/core/services/stb_resume_store.dart';
import 'package:fndtv/src/core/services/stb_system_service.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/data/repositories/content/content_repository.dart';
import 'package:fndtv/src/ui/widgets/stb_screen_size/stb_screen_size.dart';
import 'package:fndtv/src/ui/widgets/stb_video_player/stb_decode_profile.dart';
import 'package:fndtv/src/ui/widgets/stb_video_player/stb_mpv_diag_reader.dart';
import 'package:fndtv/src/ui/widgets/stb_video_player/stb_schedule_strip.dart';
import 'package:ui_kit/ui_kit.dart';

/// Do NOT re-add a forced render-surface size on the legacy boxes.
///
/// The reasoning was sound on paper. Decode, the copy out of MediaCodec and the
/// GL upload are all fixed by the source frame, but the final textured-quad
/// draw scales with the SURFACE, and on a Mali-450 that is not free:
/// 1920x1080 x 50fps is roughly 104 Mpix/s of fill versus roughly 46 Mpix/s at
/// 1280x720. So 0.0.7+8 (versionCode 8) shipped a forced 1280x720 surface as an
/// experiment, accepting a softer picture in exchange for motion that keeps
/// time.
///
/// It made the boxes materially WORSE. QA, 2026-08-01, two Android 11 boxes:
/// live streams mostly refused to load at all (spinner, then nothing), several
/// attempts produced audio with no picture whatsoever, and behaviour differed
/// run to run and box to box.
///
/// That is the signature of the resize itself, not of the smaller size.
/// media_kit cannot resize an Android surface for us (`VideoControllerConfiguration`'s
/// width/height/scale are ignored outright by the Android controller and
/// `setSize` throws), so shrinking meant driving its internal
/// `vo=null` -> `android-surface-size`/`wid`/`vo=gpu` re-init dance by hand,
/// from an unawaited poll loop, at an arbitrary moment after the first frame.
/// Tearing the video output down and rebuilding it mid-startup on live HLS is a
/// race, and when it lost, the vo never came back: audio kept running with no
/// picture, which is exactly what QA saw. Non-determinism was the tell.
///
/// The surface LOCK in `_lockSurfaceSize` is a DIFFERENT mechanism and stays.
/// It only cancels media_kit's videoParams subscription so geometry switches
/// stop triggering that same dance; it never tears the vo down itself, and it
/// is field-proven (one surface size per open, zero mid-play decoder churn).
///
/// If GPU fill genuinely needs to come down later, do it somewhere that does
/// not require re-initialising a live vo — the honest fix remains upstream:
/// the feed is 1080i50 and needs to be normalised to progressive 1080p25 at
/// the transcoder.

/// Set-top-box video player backed by **mpv** (media_kit) instead of
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
/// D-pad: OK/center = play·pause, ←/→ = seek ±10s (archive only), ↑ = open the
/// schedule strip (live channels), Back = exit. While the strip is open it takes
/// over the D-pad: ←/→ move its cursor and ↑/↓/Back all dismiss it.
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

  /// Null until [_bootstrap] has read the API level and picked a decode path —
  /// see [pickStbDecodeProfile]. The spinner covers that gap.
  VideoController? _controller;
  final FocusNode _focusNode = FocusNode();

  final List<StreamSubscription<dynamic>> _subs = [];

  bool _playing = false;
  bool _buffering = true;
  String? _error;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  bool _controlsVisible = true;
  Timer? _hideTimer;

  // ─── Screen-size calibration (↓ opens; ↑ is taken by the schedule) ─────────
  //
  // The value lives in the shared controller and is applied ONCE at the app
  // root, so there is no scaler here — the video shrinks because the whole app
  // does. Scaling again locally would apply it twice.
  final StbScreenSizeController _screenSizeController =
      StbScreenSizeController.instance;
  bool _screenSizeOpen = false;

  // ─── Stall watchdog ────────────────────────────────────────────────────────
  //
  // `Player.stream.error` is NOT a "playback died" signal: media_kit forwards
  // every mpv log line at level `error` from the file/ffmpeg/vd/ad/cplayer/
  // stream prefixes. On a live HLS feed those fire routinely and recover on
  // their own — a segment that 404s while the playlist rolls, a TCP reset, a
  // partially-downloaded frame. Latching the error overlay on the first one is
  // what put QA on a permanent "Playback failed" screen while the box was
  // still decoding happily (box logcat, X88 Pro 14: `c2.rk.avc.decoder` ran
  // clean for the whole capture, no codec error, no restart).
  //
  // So fatality is decided by PROGRESS, not by mpv's log: if the position stops
  // advancing for [_stallTimeout] we reopen the stream, and only after
  // [_maxRecoveryAttempts] failed reopens do we show the overlay.
  static const Duration _stallTimeout = Duration(seconds: 15);
  static const Duration _watchdogTick = Duration(seconds: 3);
  static const int _maxRecoveryAttempts = 3;

  Timer? _watchdog;
  DateTime _lastProgress = DateTime.now();
  Duration _lastSeenPosition = Duration.zero;
  int _recoveryAttempts = 0;

  int _watchdogTicks = 0;

  /// Startup forensics for the field log: when the last `open()` was issued and
  /// whether any position progress has been seen since. The "first progress"
  /// line is the one number that separates "pipeline never started" from
  /// "started and then died" in a QA logcat.
  DateTime? _openedAt;
  bool _progressSinceOpen = false;

  // ─── Why there is no app-side fix for the slow motion ──────────────────────
  //
  // Measured, then explained, 2026-07-31:
  //
  // * The feed is 1080i50 — INTERLACED, 50 fields/s, anamorphic 1440x1080.
  //   Confirmed by parsing the live segment's H.264 SPS: profile 77 level 41,
  //   `frame_mbs_only_flag = 0`, VUI time_scale=50 / num_units_in_tick=1
  //   (= 25 frames/s). The Rockchip decoder bob-deinterlaces it through the
  //   IEP into 50 PROGRESSIVE frames/s, which is what mpv reports as
  //   container-fps=50 while the playlist honestly advertises 25.
  //
  // * The box therefore copies and uploads 50 frames/s to carry 25 frames of
  //   information, and lands ~20% short of realtime: avsync grew 6.04→49.76s
  //   over four minutes, dead linear, on every channel and every open.
  //
  // * `vd-lavc-skipframe=nonref` was tried (0.0.17+18) and changed NOTHING —
  //   the 18:41 log is numerically identical to the 18:19 one. Two reasons,
  //   either sufficient: skipframe is a libavcodec option and decoding here
  //   happens inside Android MediaCodec; and decode was never the bottleneck
  //   (the VPU does 1080p60) — the cost is the per-frame copy out of the codec
  //   plus the GL upload.
  //
  // * mpv cannot shed that cost. Its VO framedrop runs AFTER the frame has
  //   been copied out, so thousands of drops save only the upload/render and
  //   the drift accumulates anyway. There is no mpv setting that makes
  //   MediaCodec emit fewer frames.
  //
  // The fix is upstream: deliver PROGRESSIVE 1080p25 instead of 1080i50. That
  // halves the frames the box must move and removes the IEP deinterlace step.
  // Do not add another frame-skipping knob here expecting a different result.

  /// [_logDecodeSetup] runs once per player, on the first frame.
  bool _decodeLogged = false;

  /// Which decode path this box runs — kept so the shield and diagnostics can
  /// branch on `lowPower` after bootstrap.
  StbDecodeProfile? _profile;

  /// Black shield over the video from (re)open until the pipeline proves alive.
  ///
  /// On the legacy boxes the decoder-(re)init window is where the vo presents
  /// planes nothing has written yet — QA's whole-screen green. Every `open()`
  /// re-arms this; the first position advance clears it. Position moving is a
  /// proxy for "frames flow" (audio could advance alone in the pathological
  /// case), so this covers the init window, not a permanently broken draw path
  /// — that is what removing `gpu-dumb-mode` is for.
  bool _blankUntilFirstFrame = false;

  /// How long the shield is held AFTER the first position advance. Position is
  /// driven by the audio clock, so "position moved" is not "video is clean" —
  /// see the clear site in `_subscribe`. Short enough not to read as a delay,
  /// long enough to cover surface/crop settling.
  static const Duration _shieldSettle = Duration(milliseconds: 600);

  /// Companion shield for mid-play video-parameter switches.
  ///
  /// The 2026-07-31 X88pro10 logcat showed the real green generator: the
  /// channel's short interstitials alternate between square-pixel 1080p and
  /// anamorphic (display 2560x1080) encodes, and EVERY boundary tears down and
  /// rebuilds the ANativeWindow, EGL context and OMX decoder — eight times in
  /// one 33-second ad run, each presenting unwritten planes. Those reinits
  /// never go through [_open], so [_blankUntilFirstFrame] cannot cover them —
  /// and its clear-on-position-advance would lift instantly anyway, because
  /// audio keeps the position moving right through a video reinit. This flag
  /// is armed by the `videoParams` stream on a *change* of geometry and
  /// cleared by a fixed timer instead.
  bool _paramShieldActive = false;
  Timer? _paramShieldTimer;
  VideoParams? _lastVideoParams;

  // The on-screen QA diagnostics chip (three ↓ presses) was REMOVED for
  // production at the client's request. Everything it showed still goes to
  // logcat every 30s from `_logPerf` — decoder in use, real rendered fps,
  // A/V drift and drop counts — so field diagnosis is unchanged, it just needs
  // `adb logcat` instead of a photo of the TV.

  /// Async property reader on a second mpv client handle — the ONLY sanctioned
  /// way to read mpv properties while playback is live. Sync `getProperty`
  /// blocks the UI isolate for up to `network-timeout` when the core wedges;
  /// that produced QA's input-dispatcher warning on the box and a full ANR on
  /// the emulator. See [StbMpvDiagReader].
  StbMpvDiagReader? _mpvReader;
  Timer? _mpvDrainTimer;

  /// Most recent mpv error line — diagnostics only, and the message we show if
  /// the stream really is dead.
  String? _lastErrorText;

  // §6 resume: persist last channel + position (archive/DVR only) so it picks
  // up where the viewer left off (e.g. after the box sleeps/wakes). Does not
  // auto-launch anything on boot.
  StbResumeStore? _resume;
  int? _pendingResumeMs;
  bool _resumed = false;
  DateTime _lastSave = DateTime.fromMillisecondsSinceEpoch(0);

  // ─── Schedule (EPG) strip ──────────────────────────────────────────────────
  //
  // Info-only: the backend gives every program the channel's own live URL and a
  // null `dvr_url`, so there is nothing per-program to play — see
  // [StbScheduleStrip]. Up opens; Up, Down or Back closes; ←/→ move the cursor.
  //
  // Named `_epg*` rather than `_schedule*` so it doesn't read as a sibling of
  // [_scheduleHideControls], which is about the auto-hide timer.
  static const Duration _epgIdleTimeout = Duration(seconds: 12);

  /// How long a fetched schedule is reused before the panel goes back to the
  /// network. Reopening inside this window is instant — no request, no spinner —
  /// which is most of the time on a box where the strip gets opened repeatedly.
  /// Past it, the next open refreshes so late schedule edits land. (The NOW
  /// highlight does not depend on this; it is recomputed on every build.)
  static const Duration _epgMaxAge = Duration(minutes: 3);

  bool _epgOpen = false;
  int _epgIndex = 0;
  ScheduleStatus _epgStatus = ScheduleStatus.loading;
  List<LiveModel> _epgPrograms = const [];
  DateTime? _epgLoadedAt;
  Timer? _epgIdleTimer;

  /// A request is in flight. Tracked separately from [_epgStatus] because that
  /// starts out `loading` (the strip's resting state before anything is asked
  /// for), so it can't distinguish "never fetched" from "fetching now".
  bool _epgFetching = false;

  /// Live channels aren't scrubbable; only the DVR/archive stream is.
  bool get _isLive => widget.contentType != ContentType.dvr;

  /// A DVR item is a single program — it carries no `seasons` of its own, so the
  /// strip is offered on live channels only.
  bool get _epgAvailable => _isLive;

  String get _channelId => widget.video.id.toString();

  @override
  void initState() {
    super.initState();
    MediaKit.ensureInitialized();
    _player = Player();
    if (!_isLive && StbSystemService.isStb) {
      _resume = StbResumeStore(context.read<LocalStorage>());
      _resume!.positionFor(_channelId).then((ms) {
        if (mounted) _pendingResumeMs = ms;
      });
    }
    _subscribe();
    unawaited(_bootstrap());
    _startWatchdog();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _scheduleHideControls();
    });
  }

  Future<void> _bootstrap() async {
    final profile = await pickStbDecodeProfile();
    logger.i('[STB] video decoder: hwdec=${profile.hwdec} vo=${profile.vo} '
        '(${profile.reason})');
    final controller = VideoController(
      _player,
      configuration: VideoControllerConfiguration(
        hwdec: profile.hwdec,
        vo: profile.vo,
      ),
    );
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _controller = controller;
    });

    // Legacy boxes: freeze the video surface at its first-attach size.
    if (profile.lowPower) unawaited(_lockSurfaceSize(controller));
    await applyStbMpvTuning(_player, profile);

    // BISECT (2026-08-01): on the legacy boxes the diagnostics client is NOT
    // attached at startup. QA's timeline says the X88pro10 last played on
    // 0.0.7+8 and has failed to start on every build since; the second mpv
    // client (added 0.0.9+10) is the one remaining mpv-level delta against
    // that known-good build, so it is out of the startup path until cleared.
    // The ↓↓↓ chip still works — it attaches the reader lazily on first use,
    // which doubles as the experiment: if playback dies the moment the chip
    // opens, the reader is guilty.
    if (!profile.lowPower) {
      await _attachMpvReader();
    } else {
      logger.i('[STB] diag reader deferred (legacy box) — '
          'attaches after first frame');
    }

    await _open();
  }

  /// Freezes the video surface at its first-attach size on the legacy boxes,
  /// by cancelling media_kit's videoParams→resize subscription after the
  /// initial attach.
  ///
  /// Why (QA request 2026-08-01, backed by the Jul-31 X88pro10 logcat): the
  /// feed's interstitials alternate square-pixel 16:9 and anamorphic 21:9
  /// geometry (display 1920x1080 ↔ 2560x1080). media_kit reacts to every
  /// `videoParams` change by resizing the ANativeWindow, running a
  /// `vo=null` → `android-surface-size`/`wid`/`vo=gpu` re-init dance, and then
  /// calling `seek(Duration.zero)` — a stream reload on live HLS. On the box
  /// that meant 8 resizes / 16 OMX decoder creations / EGL churn in one
  /// 33-second ad run. With the subscription cancelled the surface keeps its
  /// first size and NONE of that fires; mpv's gpu vo letterboxes 21:9 content
  /// inside the fixed surface correctly on its own. Only a genuine
  /// coded-resolution change still reinitialises the decoder — unavoidable,
  /// and far cheaper without the surface/EGL/seek pile-on.
  ///
  /// The first sizing MUST be allowed through — the vo cannot attach to a
  /// surface that was never sized — so this waits for a real [rect] before
  /// cancelling, and leaves auto-resize alone if playback never attaches.
  ///
  /// Modern boxes are untouched: `mediacodec_embed` scales by stretching to
  /// the surface, so a fixed 16:9 surface would distort anamorphic segments
  /// there, and Codec2 reinits are quick anyway.
  Future<void> _lockSurfaceSize(VideoController controller) async {
    // The platform controller exists once the texture is created.
    AndroidVideoController? android;
    for (var i = 0; i < 100 && mounted; i++) {
      final platform = controller.notifier.value;
      if (platform is AndroidVideoController) {
        android = platform;
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (android == null) {
      logger.w('[STB] surface lock skipped — no Android video controller');
      return;
    }
    // First attach done when the rect carries a real size.
    for (var i = 0; i < 300 && mounted; i++) {
      final rect = controller.rect.value;
      if (rect != null && rect.width > 1 && rect.height > 1) break;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    final rect = controller.rect.value;
    if (!mounted || rect == null || rect.width <= 1 || rect.height <= 1) {
      logger.w('[STB] surface lock skipped — playback never attached');
      return;
    }
    await android.videoParamsSubscription?.cancel();
    android.videoParamsSubscription = null;
    logger.i('[STB] surface locked at '
        '${rect.width.toInt()}x${rect.height.toInt()} — geometry switches no '
        'longer rebuild surface/EGL or reseek the live stream');
  }

  /// Creates the async property reader and its drain timer. Safe to call more
  /// than once; later calls are no-ops.
  Future<void> _attachMpvReader() async {
    if (_mpvReader != null) return;
    _mpvReader = StbMpvDiagReader.create(await _player.handle);
    if (_mpvReader != null) {
      _mpvDrainTimer = Timer.periodic(
        const Duration(milliseconds: 300),
        (_) => _mpvReader?.drain(),
      );
      logger.i('[STB] diag reader attached');
    }
  }

  Future<void> _open() {
    _error = null;
    _noteProgress();
    _openedAt = DateTime.now();
    _progressSinceOpen = false;
    logger.i('[STB] open() — ${widget.link}');
    // EVERY box, not just the legacy ones.
    //
    // It was legacy-only while the known artifact was the green flash. Android
    // 14 has its own: a line flickering along the BOTTOM edge for the first
    // moments of every stream (QA, both A14 boxes; never on A11). That is the
    // 8 rows of coded padding showing through — the feed is coded 1440x1088
    // with crop bottom 2, and for 4:2:0 interlaced the crop unit is 4px, so
    // 1088 - 8 = the 1080 that should be displayed. On the zero-copy
    // `mediacodec_embed` path the decoder writes the whole coded surface and
    // the crop is applied downstream, so until that settles the padding rows
    // are on screen. A11 never showed it because `mediacodec-copy` has mpv
    // apply the crop itself before the frame is ever drawn.
    if (mounted) {
      setState(() => _blankUntilFirstFrame = true);
    }
    return _player.open(Media(widget.link)); // autoplays
  }

  /// Marks the pipeline as alive, resetting the stall clock.
  void _noteProgress() {
    _lastProgress = DateTime.now();
  }

  void _subscribe() {
    _subs.add(_player.stream.playing.listen((v) {
      if (!mounted) return;
      // First frame through: report what the decode path actually resolved to.
      if (v && !_decodeLogged) {
        _decodeLogged = true;
        unawaited(_logDecodeSetup());
      }
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
      // Recorded, not acted on — see the stall-watchdog note above. The
      // watchdog decides whether playback actually died.
      _lastErrorText = e;
      logger.w('[STB] mpv error (non-fatal unless playback stalls): $e');
    }));
    _subs.add(_player.stream.position.listen((p) {
      if (!mounted) return;
      // Position moving = frames flowing, whatever mpv logged. Track this for
      // live channels too, even though live has no seek bar to update.
      if (p != _lastSeenPosition) {
        _lastSeenPosition = p;
        _noteProgress();
        _recoveryAttempts = 0;
        if (!_progressSinceOpen) {
          _progressSinceOpen = true;
          final opened = _openedAt;
          final ms = opened == null
              ? '?'
              : DateTime.now().difference(opened).inMilliseconds.toString();
          logger.i('[STB] first progress ${ms}ms after open()');
          // Playback is demonstrably alive — NOW the diagnostics client may
          // join (startup stays reader-free, the bisect-proven sequence).
          // From here the 30s perf heartbeat carries the slow-motion numbers
          // into every field logcat with no button presses needed.
          if (_mpvReader == null) unawaited(_attachMpvReader());
        }
        // Pipeline is alive — drop the black shield over the init window, but
        // not on this very tick. Position runs off the AUDIO clock, so it
        // advances before the video surface has settled; lifting immediately
        // is what let the bottom padding rows flash through on Android 14.
        // One short settle window covers the first frames.
        if (_blankUntilFirstFrame) {
          Future<void>.delayed(_shieldSettle).then((_) {
            if (mounted && _blankUntilFirstFrame) {
              setState(() => _blankUntilFirstFrame = false);
            }
          });
        }
      }
      if (_isLive) return;
      setState(() => _position = p);
      _maybeResume();
      _maybeSave(p);
    }));
    _subs.add(_player.stream.duration.listen((d) {
      if (mounted && !_isLive) setState(() => _duration = d);
    }));
    _subs.add(_player.stream.videoParams.listen(_onVideoParams));
  }

  /// Arms [_paramShieldActive] across mid-play geometry switches — see the
  /// field's doc for why these are the green-flash windows on the legacy boxes.
  void _onVideoParams(VideoParams params) {
    final previous = _lastVideoParams;
    _lastVideoParams = params;
    if (_profile?.lowPower != true || !mounted) return;
    // Startup emits a burst of transitions from/through empty params (the
    // Jul-31 field log: nullxnull -> nullxnull, -> 1920x1080, -> nullxnull…).
    // That window belongs to [_open]'s shield; only a change AWAY FROM real
    // geometry means a mid-play reinit.
    // "Real" means DISPLAY geometry was known — coded-only (disp null) states
    // are still startup negotiation, per the 17:33 field log where disp
    // flapped null↔1920x1080 three times in the first 3 seconds.
    final previousReal =
        previous != null && previous.dw != null && previous.dh != null;
    if (!previousReal) return;
    final changed = params.w != previous.w ||
        params.h != previous.h ||
        params.dw != previous.dw ||
        params.dh != previous.dh;
    if (!changed) return;

    // Log coded AND display size: a coded switch (1440<->1920) can hide
    // behind an unchanged 1920x1080 display size, which read as the baffling
    // "1920x1080 -> 1920x1080 switch" in the field log.
    logger.i('[STB] video params switch '
        'coded ${previous.w}x${previous.h} disp ${previous.dw}x${previous.dh}'
        ' -> coded ${params.w}x${params.h} disp ${params.dw}x${params.dh}'
        ' — shielding reinit window');
    setState(() => _paramShieldActive = true);
    _paramShieldTimer?.cancel();
    // Long enough for the OMX teardown+rebuild on this box; a following
    // boundary (ad runs come in bursts) simply re-arms it.
    _paramShieldTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted && _paramShieldActive) {
        setState(() => _paramShieldActive = false);
      }
    });
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

  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(_watchdogTick, (_) {
      _checkForStall();
      // Every 10th tick ≈ 30s: the perf heartbeat. One line with the numbers
      // that decide the slow-motion question, in every field logcat.
      if (++_watchdogTicks % 10 == 0) unawaited(_logPerf());
    });
  }

  /// Reads an mpv property without ever touching the core lock from the UI
  /// isolate, or null when it is unset/unknown/unanswered. All runtime reads
  /// go through here; the pre-open read-backs in [applyStbMpvTuning] are the one
  /// sanctioned exception (core idle, decoder not created, reads genuinely
  /// fast).
  Future<String?> _diagProp(String name) async {
    final value = await _mpvReader?.read(name);
    return (value == null || value.isEmpty) ? null : value;
  }

  /// One-shot: what mpv actually settled on, logged once the first frame is
  /// through.
  ///
  /// Every round of tuning on these boxes so far has been guesswork about which
  /// decoder really ran. This makes a field logcat answer it outright — in
  /// particular whether the hardware decoder is live at all, since a silent
  /// fallback to software is the one failure that would look exactly like the
  /// slow-motion symptom we are chasing.
  Future<void> _logDecodeSetup() async {
    // media_kit flips `playing` before libmpv has the video track open, and on
    // legacy boxes the reader itself only attaches after first progress — so
    // poll until both exist rather than guessing a delay. On a slow box the
    // gap is longer, which is exactly where the answer matters most.
    String? hwdec;
    for (var attempt = 0; attempt < 15; attempt++) {
      if (_mpvReader != null) {
        hwdec = await _diagProp('hwdec-current');
        if (await _diagProp('video-params/w') != null) break;
      }
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return;
    }
    if (_mpvReader == null) {
      // Never fabricate a verdict from null reads — the Jul-31 field log
      // showed the false "hardware decode is NOT active" alarm that produces.
      logger.i('[STB] decode diagnostics unavailable — reader never attached');
      return;
    }

    final parts = <String>['hwdec-current=${hwdec ?? 'unknown'}'];
    var paramsKnown = false;
    for (final name in const [
      'video-codec',
      'video-params/w',
      'video-params/h',
      'container-fps',
    ]) {
      final value = await _diagProp(name);
      if (value != null) {
        parts.add('$name=$value');
        if (name == 'video-params/w') paramsKnown = true;
      }
    }
    logger.i('[STB] decode in use — ${parts.join(' ')}');

    // Alarm only on a DEFINITIVE verdict: mpv said "no", or reads demonstrably
    // work (params resolved) while hwdec stays empty. A bare null can just be
    // an unanswered read and must not cry wolf.
    if (hwdec == 'no' || (hwdec == null && paramsKnown)) {
      logger.e(
        '[STB] hardware decode is NOT active (hwdec-current=${hwdec ?? 'null'}) '
        '— 1080p25 H.264 in software will not reach realtime on this box, and '
        'that alone would explain slow-motion playback.',
      );
    }
  }

  /// The 30s perf heartbeat: real rendered rate vs the container's, A/V drift
  /// (the literal slow-motion number), cumulative drops and the live hwdec.
  /// One log line per beat — the whole slow-motion diagnosis, hands-free.
  Future<void> _logPerf() async {
    // Without the reader every read is null; silence beats fabricated zeros.
    if (_mpvReader == null) return;
    final values = await Future.wait([
      _diagProp('estimated-vf-fps'),
      _diagProp('container-fps'),
      _diagProp('avsync'),
      _diagProp('frame-drop-count'),
      _diagProp('decoder-frame-drop-count'),
      _diagProp('hwdec-current'),
    ]);
    if (!mounted) return;
    logger.i('[STB] perf — vf-fps=${_fmtNum(values[0])}'
        ' of ${_fmtNum(values[1], dp: 0)}'
        ' avsync=${_fmtNum(values[2], dp: 2)}s'
        ' drops vo=${values[3] ?? '—'} dec=${values[4] ?? '—'}'
        ' hwdec=${values[5] ?? '—'}');
  }

  static String _fmtNum(String? raw, {int dp = 1}) {
    final v = double.tryParse(raw ?? '');
    return v == null ? '—' : v.toStringAsFixed(dp);
  }

  /// Reopens a stream that has genuinely stopped advancing, and gives up (shows
  /// the overlay) only after [_maxRecoveryAttempts] reopens fail to revive it.
  void _checkForStall() {
    if (!mounted || _error != null) return;
    if (DateTime.now().difference(_lastProgress) < _stallTimeout) return;

    if (_recoveryAttempts >= _maxRecoveryAttempts) {
      logger.e(
        '[STB] playback dead after $_maxRecoveryAttempts reopens '
        '(last mpv error: $_lastErrorText)',
      );
      setState(() => _error = _lastErrorText ?? 'playback stalled');
      // Attach the network verdict to the overlay so a QA photo of the
      // failure carries it. The Jul-31 X88pro10 death showed the signature
      // this exists for: position frozen with `last mpv error: null` — mpv
      // starving silently. This one probe separates "origin unreachable from
      // this box" from "origin fine, pipeline broken".
      unawaited(_probeStreamHealth('at failure').then((verdict) {
        if (mounted && _error != null) {
          setState(() => _error = '$_error · $verdict');
        }
      }));
      return;
    }

    _recoveryAttempts++;
    if (_recoveryAttempts == 1) {
      // One early data point too, while the stall is fresh.
      unawaited(_probeStreamHealth('first reopen'));
    }
    logger.w(
      '[STB] no progress for ${_stallTimeout.inSeconds}s — reopening '
      '($_recoveryAttempts/$_maxRecoveryAttempts, '
      'last mpv error: $_lastErrorText)',
    );
    // _open restarts the stall clock (full window to recover) and re-arms the
    // first-frame shield so the reinit window doesn't flash green.
    unawaited(_open());
  }

  /// GETs the playlist URL outside mpv entirely (plain http, own sockets) and
  /// reports one line: reachable-with-bytes, HTTP error, or timeout/refused.
  /// A playlist is a few hundred bytes, so a GET is as cheap as a HEAD and
  /// some origins reject HEAD. Never throws.
  Future<String> _probeStreamHealth(String context) async {
    final stopwatch = Stopwatch()..start();
    String verdict;
    try {
      final response = await http
          .get(Uri.parse(widget.link))
          .timeout(const Duration(seconds: 6));
      verdict = 'probe: HTTP ${response.statusCode}, '
          '${response.bodyBytes.length}B in ${stopwatch.elapsedMilliseconds}ms';
    } on TimeoutException {
      verdict = 'probe: TIMEOUT after ${stopwatch.elapsedMilliseconds}ms';
    } catch (e) {
      verdict =
          'probe: FAILED after ${stopwatch.elapsedMilliseconds}ms (${e.runtimeType})';
    }
    logger.i('[STB] stream $context — $verdict');
    return verdict;
  }

  Future<void> _retry() async {
    setState(() {
      _error = null;
      _buffering = true;
    });
    _recoveryAttempts = 0;
    await _open();
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

  // ─── Schedule (EPG) ────────────────────────────────────────────────────────

  /// Index of the program airing right now, or -1. Recomputed on every build so
  /// the NOW badge stays correct as the hour rolls over, without refetching.
  int get _epgNowIndex => scheduleNowIndex(_epgPrograms, DateTime.now());

  int get _epgFocusIndex => scheduleFocusIndex(_epgPrograms, DateTime.now());

  Future<void> _loadEpg() async {
    if (_epgFetching) return;
    // Read the repository before the first await — `context` must not be
    // touched across an async gap.
    final repo = context.read<ContentRepository>();
    _epgFetching = true;

    // A cold load has nothing to show, so it gets the spinner. A refresh past
    // [_epgMaxAge] keeps the cached list on screen and swaps it when the new one
    // lands — reopening the strip should never flash empty just because the
    // cache went stale a moment ago.
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
        // A failed refresh keeps the cached programs: slightly stale listings
        // beat an error screen when we already have something to show.
        // `_epgLoadedAt` is left alone so the next open retries.
        if (cold) setState(() => _epgStatus = ScheduleStatus.error);
        return;
      }
      // From now onward only — the feed's window reaches back over the past
      // day, and the strip is a "what's on / what's next" panel, not history.
      final programs =
          scheduleFromNow(sortedByStart(data.scheduleItems), DateTime.now());
      setState(() {
        _epgPrograms = programs;
        _epgLoadedAt = DateTime.now();
        _epgStatus =
            programs.isEmpty ? ScheduleStatus.empty : ScheduleStatus.ready;
        // Only a cold load positions the cursor. A refresh landing mid-browse
        // must not yank it out from under the viewer — just keep it in range.
        _epgIndex = cold
            ? _epgFocusIndex
            : _epgIndex.clamp(0, programs.isEmpty ? 0 : programs.length - 1);
      });
    } catch (e) {
      logger.w('[STB] schedule load failed: $e');
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
      // Reopening jumps back to the present rather than resuming wherever the
      // cursor was left minutes ago.
      if (_epgPrograms.isNotEmpty) _epgIndex = _epgFocusIndex;
    });
    if (stale) {
      unawaited(_loadEpg());
    } else {
      final age = DateTime.now().difference(loadedAt).inSeconds;
      logger.d('[STB] schedule served from cache (${age}s old, '
          'TTL ${_epgMaxAge.inMinutes}m)');
    }
    _hideTimer?.cancel(); // the strip owns the screen while it is open
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

  // ─── Screen size ──────────────────────────────────────────────────────────

  void _openScreenSize() {
    _hideTimer?.cancel(); // the panel owns the screen while it is open
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

    // While the schedule strip is up it owns the D-pad: ←/→ move the cursor and
    // BOTH ↑ and ↓ dismiss it. Up is the key that opened it, so pressing it
    // again to get rid of it is the reflex; leaving Up inert made the strip feel
    // stuck. OK does nothing — the strip is informational, see
    // [StbScheduleStrip]. Back is deliberately absent here; the [PopScope] in
    // `build` handles it (see the note there).
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
      // Anything else (including OK) just keeps the panel awake.
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

    // Escape only — a desktop/keyboard convenience. The remote's Back arrives as
    // a platform pop, not as a key event, and popping here as well would fire
    // twice: once from us, once from the framework.
    if (key == LogicalKeyboardKey.escape) {
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
    _watchdog?.cancel();
    _epgIdleTimer?.cancel();
    _paramShieldTimer?.cancel();
    // Reader before player: detaching our client first means core teardown
    // never waits on us and no read can ever touch a dead core.
    _mpvDrainTimer?.cancel();
    _mpvReader?.dispose();
    _focusNode.dispose();
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final bool showSpinner =
        _error == null && (controller == null || !_playing || _buffering);
    // The strip covers the lower third, so the bottom bar steps aside while it
    // is open. The title stays up — it's the context for what you're browsing.
    final bool showControls = _controlsVisible && _error == null;
    final bool showTopBar = showControls || _epgOpen;

    // Back is handled here and ONLY here.
    //
    // Android routes the remote's Back to the framework as a pop request. The
    // original code also popped from [_onKey] on `goBack`, which meant a single
    // press could pop twice — observed on the Google TV emulator as Back leaving
    // the player *and* the home screen, dropping the viewer out of the app. With
    // the strip open the same double-fire closed it and popped the player in one
    // press. One authority for Back removes both.
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
          child: Container(
            color: Colors.black,
            alignment: Alignment.center,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_error == null && controller != null)
                  Video(
                    controller: controller,
                    controls: NoVideoControls,
                    fit: BoxFit.contain,
                  ),

                // Legacy-path shields: black over the video while a decoder
                // (re)init window is live — channel (re)opens until frames
                // flow, and mid-play geometry switches — so neither can flash
                // green.
                if ((_blankUntilFirstFrame || _paramShieldActive) &&
                    _error == null)
                  const Positioned.fill(
                    child: ColoredBox(color: Colors.black),
                  ),

                if (showSpinner)
                  Center(
                    child: CircularProgressIndicator(
                      color: context.uiColors.primary,
                    ),
                  ),

                // Top-left: back + channel title.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _TopBar(
                    title: widget.video.title,
                    visible: showTopBar,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                ),

                // Bottom: play/pause + (archive) seek bar or LIVE badge.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _BottomBar(
                    visible: showControls && !_epgOpen,
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
                // only thing that matters, and the strip is tall enough to bury
                // it otherwise. The overlay is transparent apart from its own
                // content, so the schedule still reads through around it.
                if (_error != null)
                  _ErrorOverlay(onRetry: _retry, detail: _error),

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
    this.scheduleHint,
  });

  final bool visible;
  final bool playing;
  final bool isLive;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayPause;

  /// Label for the "▲ Schedule" affordance. Null hides it — nothing else
  /// advertises that Up opens the EPG, and on a remote an undiscoverable key is
  /// the same as no feature at all.
  final String? scheduleHint;

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
              if (scheduleHint != null) ...[
                const SizedBox(width: 18),
                _ScheduleHint(label: scheduleHint!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// "▲ Schedule" — the only cue that Up opens the EPG strip.
class _ScheduleHint extends StatelessWidget {
  const _ScheduleHint({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.keyboard_arrow_up_rounded,
              color: Colors.white70, size: 20),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
  const _ErrorOverlay({required this.onRetry, this.detail});
  final VoidCallback onRetry;

  /// Raw mpv error line. Shown small and dim so QA can quote it in a bug
  /// report — without it, every "playback error" screenshot looks identical
  /// and tells us nothing about which layer failed.
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
