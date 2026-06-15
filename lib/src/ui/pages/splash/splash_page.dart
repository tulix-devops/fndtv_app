// ignore_for_file: use_build_context_synchronously

import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/index.dart';
import 'package:local_storage/local_storage.dart';
import 'package:fndtv/src/ui/pages/main/main_container_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  static const path = '/';
  static const name = 'splash';

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
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
    // it (edge-to-edge) over the red splash.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      _init();
    });
  }

  void _init() async {
    await context.read<LocalStorage>().init();
    await context.read<AppCubit>().init();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppCubit, AppState>(
      listenWhen: (prev, curr) =>
          prev.authStatus != curr.authStatus || prev.initializationStatus != curr.initializationStatus,
      listener: (ctx, state) {
        if (!state.isInitialized) {
          return;
        }
        ctx.pushReplacementNamed(MainContainerPage.path);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFA83734),
        body: Stack(
          children: [
            // FNDTV logo slightly above center
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
            // Progress indicator pinned at bottom
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
        ),
      ),
    );
  }
}
