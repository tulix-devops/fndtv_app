import 'dart:async';

import 'package:app_logger/app_logger.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/ui/widgets/stb_surface_player/stb_surface_player.dart';
import 'package:fndtv/src/ui/widgets/stb_video_player/stb_decode_profile.dart';
import 'package:fndtv/src/ui/widgets/stb_video_player/stb_video_player.dart';
import 'package:fndtv/src/ui/widgets/widgets.dart';
import 'package:flutter/services.dart'; // exports `appFlavor`

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage(
      {super.key, required this.video, required this.contentType});

  final LiveModel video;
  final ContentType contentType;

  static const name = 'video-player';
  static const path = 'video-player';

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  /// null = still probing the API level. Everything else is decided from it, so
  /// the page shows black for the one frame that read takes rather than starting
  /// on the wrong engine and swapping underneath the viewer.
  bool? _useSurfacePlayer;

  @override
  void initState() {
    super.initState();
    logger.i('[player] opening ${widget.video} (${widget.contentType})');
    unawaited(_resolveEngine());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.isTv) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  Future<void> _resolveEngine() async {
    final sdk = await readAndroidSdkInt();
    if (!mounted) return;
    setState(() => _useSurfacePlayer = sdk <= kStbSurfacePlayerMaxSdk);
    logger.i('[player] API $sdk — '
        '${_useSurfacePlayer! ? 'native SurfaceView' : 'mpv'} engine');
  }

  @override
  Widget build(BuildContext context) {
    String link = widget.video.sources.getPreferredVideoSource() ?? '';
    logger.i('[player] source: $link');

    // Engine choice on the `stb` flavor. Radio always stays on AppVideoPlayer
    // (audio-only; it renders its own "now playing" backdrop).
    final bool stbVideo =
        appFlavor == 'stb' && widget.contentType != ContentType.radio;

    if (stbVideo && _useSurfacePlayer == null) {
      // API probe still in flight.
      return const Scaffold(
        backgroundColor: Colors.black,
        body: SizedBox.expand(),
      );
    }

    // Legacy boxes (API <= 30) render into a real SurfaceView; API >= 31 stays
    // on mpv, which already decodes zero-copy there via `mediacodec_embed` and
    // plays correctly — no reason to move a working box.
    //
    // ExoPlayer's earlier failure here is NOT a reason to skip this. That
    // attempt (0.0.15+16, capture Rockchip-X88pro10…2026-07-31_175254.logcat)
    // drove Media3 into a Flutter SurfaceTexture: ACodec fell back from
    // DynamicANWBuffer to preset ANW buffers, then asked for 30 output buffers
    // against a component capped at 23 and gave up. That count is the component
    // minimum PLUS what the CONSUMER holds undequeued, and a GL consumer holds
    // far more than a SurfaceView feeding SurfaceFlinger — so the surface, not
    // the engine, is the variable this changes. If the decoder still refuses,
    // the native side falls back to android.media.MediaPlayer by itself and
    // reports which engine won (on screen and in logcat).
    if (stbVideo && _useSurfacePlayer == true) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: StbSurfacePlayer(
          video: widget.video,
          link: link,
          contentType: widget.contentType,
          // Neither native engine could start this stream (the interlaced
          // Europe feeds are the known case). mpv has always played them on
          // these boxes, so drop to it rather than leaving a dead channel.
          // One-way: we never switch back for this page.
          onUnplayable: () {
            if (!mounted || _useSurfacePlayer != true) return;
            logger.w('[player] surface engines exhausted — falling back to mpv');
            setState(() => _useSurfacePlayer = false);
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: stbVideo
          ? StbVideoPlayer(
              video: widget.video,
              link: link,
              contentType: widget.contentType,
            )
          : AppVideoPlayer(
              video: widget.video,
              link: link,
              isLive: widget.contentType != ContentType.dvr,
              contentType: widget.contentType,
            ),
    );
  }
}
