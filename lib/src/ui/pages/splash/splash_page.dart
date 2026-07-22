// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/index.dart';
import 'package:fndtv/src/core/services/kiosk_lock_controller.dart';
import 'package:fndtv/src/core/services/update_installer.dart';
import 'package:local_storage/local_storage.dart';
import 'package:app_localization/app_localization.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:fndtv/src/ui/pages/main/main_container_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  static const path = '/';
  static const name = 'splash';

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  /// STB plays the branded boot animation (bootanimation.ts) via mpv; other
  /// flavors keep the logo splash for a short minimum.
  static const String _bootAsset = 'asset:///assets/video/bootanimation.ts';
  static const Duration _bootMaxDuration = Duration(seconds: 15);
  static const Duration _minSplash = Duration(milliseconds: 2500);

  Player? _bootPlayer;
  VideoController? _bootController;
  final List<StreamSubscription<dynamic>> _bootSubs = [];
  Timer? _bootTimer;

  bool _bootError = false;
  bool _bootDone = false;
  bool _initialized = false;
  bool _navigated = false;

  bool get _showBootVideo =>
      StbSystemService.isStb && _bootController != null && !_bootError;

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
      _startBootAnimation();
    } else {
      // No animation off the box — just hold the logo splash briefly.
      _bootTimer = Timer(_minSplash, _finishBoot);
    }

    _init();
  }

  void _startBootAnimation() {
    try {
      MediaKit.ensureInitialized();
      final player = Player();
      final controller = VideoController(player);
      _bootPlayer = player;
      _bootController = controller;

      _bootSubs.add(player.stream.completed.listen((done) {
        if (done) _finishBoot();
      }));
      _bootSubs.add(player.stream.error.listen((_) {
        if (mounted) setState(() => _bootError = true);
        _finishBoot();
      }));

      // Safety cap — never let a stuck video hold the box on the splash.
      _bootTimer = Timer(_bootMaxDuration, _finishBoot);

      player.open(Media(_bootAsset)); // autoplays, no loop
    } catch (_) {
      _bootError = true;
      _finishBoot();
    }
  }

  void _finishBoot() {
    if (_bootDone) return;
    _bootDone = true;
    if (mounted) setState(() {});
    _maybeNavigate();
  }

  void _init() async {
    await context.read<LocalStorage>().init();
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
    for (final s in _bootSubs) {
      s.cancel();
    }
    _bootPlayer?.dispose();
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
        backgroundColor: const Color(0xFF0E0F13),
        body: _showBootVideo
            ? _BootAnimation(controller: _bootController!)
            : const _BrandedSplash(),
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
