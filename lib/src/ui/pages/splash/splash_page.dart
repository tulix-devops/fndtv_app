// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:app_logger/app_logger.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/index.dart';
import 'package:fndtv/src/bloc/network_cubit/network_cubit.dart';
import 'package:fndtv/src/core/services/kiosk_lock_controller.dart';
import 'package:fndtv/src/core/services/update_installer.dart';
import 'package:local_storage/local_storage.dart';
import 'package:app_localization/app_localization.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:fndtv/src/ui/pages/main/main_container_page.dart';
import 'package:fndtv/src/ui/widgets/stb_screen_size/stb_screen_size.dart';
import 'package:fndtv/src/ui/widgets/stb_surface_player/stb_surface_boot_video.dart';
import 'package:fndtv/src/ui/widgets/stb_video_player/stb_decode_profile.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  static const path = '/';
  static const name = 'splash';

  @override
  State<SplashPage> createState() => _SplashPageState();
}

/// Splash backdrop. Also used as the shield colour over the boot video, so it
/// must stay opaque.
const Color _splashBackground = Color(0xFF0E0F13);

class _SplashPageState extends State<SplashPage> {
  /// STB plays the branded boot animation (bootanimation.ts); other flavors keep
  /// the logo splash for a short minimum.
  static const String _bootAsset = 'asset:///assets/video/bootanimation.ts';
  static const Duration _bootMaxDuration = Duration(seconds: 15);

  /// How far into the clip the mpv path waits before revealing it — the audio
  /// clock leads the video surface, so position alone reveals too early.
  /// The legacy path does not need this: its "first frame" is a genuinely
  /// drawn frame (`MEDIA_INFO_VIDEO_RENDERING_START`).
  static const Duration _bootRevealAfter = Duration(milliseconds: 600);
  static const Duration _minSplash = Duration(milliseconds: 2500);

  Player? _bootPlayer;
  VideoController? _bootController;
  final List<StreamSubscription<dynamic>> _bootSubs = [];
  Timer? _bootTimer;

  bool _bootError = false;
  bool _bootDone = false;
  bool _initialized = false;
  bool _navigated = false;

  /// True once the boot video has actually produced picture.
  bool _bootFirstFrame = false;

  /// Legacy box (API <= 30) — plays the boot clip through the NATIVE
  /// SurfaceView player instead of mpv. Null while the API level is being read.
  ///
  /// **Why the split.** Through mpv the clip showed a full-screen green picture
  /// with audio on the Android 11 boxes — intermittently, and specifically after
  /// a cold reboot. mpv's only usable "started" signal is `position`, and
  /// position runs off the AUDIO clock: audio begins, position advances, this
  /// shield lifts, and the video surface is still in decoder init with unwritten
  /// planes (Y=U=V=0 renders as solid green). A warm start hides it because
  /// audio and video come up together. The native path reports a frame that was
  /// genuinely DRAWN, and it is what the working native reference app uses for
  /// this identical asset. Android 14 keeps mpv — it has never shown this.
  bool? _bootUsesSurface;

  /// Show the boot video only once real frames exist, never merely once a
  /// controller has been built — the decoder-init window must not be on screen.
  ///
  /// Once it finishes (or errors, or times out) the surface goes black, and if
  /// app init hasn't finished we'd sit on that dead frame with no feedback —
  /// which reads as "the app hung". Falling back to the branded splash keeps the
  /// logo + spinner up until we navigate.
  bool get _showBootVideo =>
      StbSystemService.isStb &&
      _bootFirstFrame &&
      !_bootError &&
      !_bootDone &&
      (_bootUsesSurface == true || _bootController != null);

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    // Keep the system status bar (device time/battery) visible, drawing behind
    // it (edge-to-edge) over the splash.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    if (StbSystemService.isStb) {
      unawaited(_startBootAnimation());
    } else {
      // No animation off the box — just hold the logo splash briefly.
      _bootTimer = Timer(_minSplash, _finishBoot);
    }

    _init();
  }

  Future<void> _startBootAnimation() async {
    // Safety cap first — never let a stuck video (or a slow probe below) hold
    // the box on the splash.
    _bootTimer = Timer(_bootMaxDuration, _finishBoot);
    try {
      // Legacy boxes render the clip natively — see [_bootUsesSurface]. Nothing
      // more to set up here; StbSurfaceBootVideo owns it from `build`.
      final sdk = await readAndroidSdkInt();
      if (!mounted || _bootDone) return;
      if (sdk <= kStbSurfacePlayerMaxSdk) {
        logger.i('[STB] boot animation via native SurfaceView (API $sdk)');
        setState(() => _bootUsesSurface = true);
        return;
      }
      setState(() => _bootUsesSurface = false);

      MediaKit.ensureInitialized();

      // The boot clip needs the SAME decode path as the channel player — the
      // legacy OMX hardware needs `mediacodec-copy` + `vo=gpu` and the low-power
      // render props for every video we decode, not just the player page's.
      final profile = await pickStbDecodeProfile();
      if (!mounted || _bootDone) return;

      final player = Player();
      final controller = VideoController(
        player,
        configuration: VideoControllerConfiguration(
          hwdec: profile.hwdec,
          vo: profile.vo,
        ),
      );
      _bootPlayer = player;

      // Position is the only "playback started" signal media_kit exposes
      // (`playing` flips before the track even opens) — but it runs off the
      // AUDIO clock, so it moves while the video surface is still settling.
      // Revealing on the very first tick is what let a line flicker along the
      // bottom edge of the boot video on the Android 14 boxes: those 8 rows are
      // the coded padding (1088 coded vs 1080 displayed) showing before the
      // crop applies. Waiting out a short threshold covers it.
      _bootSubs.add(player.stream.position.listen((p) {
        if (p >= _bootRevealAfter && !_bootFirstFrame && mounted) {
          setState(() => _bootFirstFrame = true);
        }
      }));
      _bootSubs.add(player.stream.completed.listen((done) {
        if (done) _finishBoot();
      }));
      _bootSubs.add(player.stream.error.listen((_) {
        if (mounted) setState(() => _bootError = true);
        _finishBoot();
      }));

      // Local asset, so the network props are inert; the read-back logging
      // belongs to the channel player, not to a 15-second splash.
      await applyStbMpvTuning(player, profile, network: false, verify: false);
      if (!mounted || _bootDone) return;

      setState(() => _bootController = controller);
      unawaited(player.open(Media(_bootAsset))); // autoplays, no loop
    } catch (e) {
      logger.w('[STB] boot animation failed to start: $e');
      _bootError = true;
      _finishBoot();
    }
  }

  void _finishBoot() {
    if (_bootDone) return;
    _bootDone = true;
    _bootTimer?.cancel();
    if (mounted) {
      setState(() {});
      // Hand the hardware decoder back NOW rather than at page teardown: these
      // boxes have very few OMX instances and the channel player needs one the
      // moment the user opens a stream. Deferred to after this frame so the
      // rebuild above has already dropped the [Video] widget, and because this
      // can be reached from inside the player's own completion callback.
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _releaseBootPlayer());
    } else {
      _releaseBootPlayer();
    }
    _maybeNavigate();
  }

  /// Tears down the boot player and its subscriptions. Idempotent.
  void _releaseBootPlayer() {
    for (final s in _bootSubs) {
      s.cancel();
    }
    _bootSubs.clear();
    final player = _bootPlayer;
    _bootPlayer = null;
    _bootController = null;
    if (player != null) unawaited(player.dispose());
  }

  void _init() async {
    final storage = context.read<LocalStorage>();
    await storage.init();
    // Overscan calibration is read once here and then drives the whole app from
    // MaterialApp.builder — do it before the first real route is shown, or the
    // UI would visibly jump from 100% to the saved value.
    await StbScreenSizeController.instance.load(storage);
    // Storage is ready — load the persisted UI locale (French by default).
    context.read<LocalizationCubit>().getLocale();

    // Register this set-top box by its serial number. Fire-and-forget: it must
    // never block or fail app startup.
    unawaited(context.read<DeviceRegistrationHandler>().registerOnInit());

    // STB only: detect the timezone from IP geolocation and apply it via root,
    // log device/network diagnostics, and run kiosk startup maintenance
    // (device-owner, launcher takeover, unwanted-app removal, disabled apps).
    // Fire-and-forget; all no-op on the normal flavor / without root.
    if (StbSystemService.isStb) {
      final stb = StbSystemService();
      unawaited(stb.syncTimezone());
      unawaited(stb.logDiagnostics());
      unawaited(stb.runStartupMaintenance());

      // Storage is initialized above, so it's safe to restore the persisted
      // kiosk-lock state now and begin the MDM check-in poll loop (which
      // surfaces + executes any commands queued from the admin console).
      unawaited(context.read<KioskLockController>().restore());
      context.read<DeviceRegistrationHandler>().startCommandPolling();

      // No cable AND Wi-Fi radio off = stranded: Android persists the radio
      // state across reboots, so a box last left in "wired" mode comes up
      // still waiting on a cable that isn't there. Re-enable Wi-Fi so it can
      // re-associate with a saved network.
      unawaited(context.read<NetworkCubit>().ensureBootConnectivity());

      // Reclaim space from a previously downloaded update APK — after a
      // successful update the box has relaunched into the new build, so the
      // leftover file is dead weight. Safe at startup: no install in flight.
      unawaited(UpdateInstaller().cleanupDownloadedApk());
    }

    await context.read<AppCubit>().init();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// Navigate to the app only once BOTH init has finished and the boot
  /// animation has ended (completed / errored / timed out).
  void _maybeNavigate() {
    if (_navigated || !_initialized || !_bootDone || !mounted) return;
    _navigated = true;
    context.pushReplacementNamed(MainContainerPage.path);
  }

  @override
  void dispose() {
    _bootTimer?.cancel();
    _releaseBootPlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppCubit, AppState>(
      listenWhen: (prev, curr) =>
          prev.authStatus != curr.authStatus ||
          prev.initializationStatus != curr.initializationStatus,
      listener: (ctx, state) {
        if (!state.isInitialized) return;
        _initialized = true;
        _maybeNavigate();
      },
      child: Scaffold(
        backgroundColor: _splashBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Legacy boxes: the native surface must be MOUNTED to play at all,
            // so it sits here from the start and the branded splash covers it
            // until a frame has genuinely been drawn.
            if (_bootUsesSurface == true && !_bootDone && !_bootError)
              StbSurfaceBootVideo(
                url: _bootAsset,
                onFirstFrame: () {
                  if (mounted && !_bootFirstFrame) {
                    setState(() => _bootFirstFrame = true);
                  }
                },
                onEnded: _finishBoot,
              ),

            // Modern boxes keep the mpv path, which has never shown the green.
            if (_bootUsesSurface == false && _showBootVideo)
              _BootAnimation(controller: _bootController!),

            // The shield. Opaque on purpose: it must hide the video surface
            // during decoder init, which is the window that renders green.
            if (!_showBootVideo)
              const ColoredBox(
                color: _splashBackground,
                child: _BrandedSplash(),
              ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen boot animation video (STB).
class _BootAnimation extends StatelessWidget {
  const _BootAnimation({required this.controller});

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: SizedBox.expand(
        child: Video(
          controller: controller,
          controls: NoVideoControls,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// Logo + progress splash (non-STB, and STB fallback if the video fails).
class _BrandedSplash extends StatelessWidget {
  const _BrandedSplash();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: const Alignment(0, -0.12),
          child: SizedBox(
            width: 240,
            height: 240,
            child: Image.asset(
              'assets/img/main_logo_transparent.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
        ),
      ],
    );
  }
}
