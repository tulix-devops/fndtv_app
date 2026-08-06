import 'dart:async';

import 'package:app_logger/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show PlatformViewHitTestBehavior;
import 'package:flutter/services.dart';
import 'package:fndtv/src/ui/widgets/stb_surface_player/stb_surface_player.dart';

/// Chrome-free video surface for the splash boot animation, backed by the same
/// native SurfaceView player as [StbSurfacePlayer].
///
/// **Why the splash needs this on the legacy boxes.** Played through
/// media_kit/mpv, the boot clip showed a full-screen GREEN picture with audio —
/// intermittently, and specifically after a cold reboot. The cause is that mpv's
/// only usable "playback started" signal is `position`, and position runs off
/// the AUDIO clock: audio begins, position advances, the branded-splash shield
/// lifts, and the video surface is still inside decoder init with nothing
/// written to its planes (Y=U=V=0 renders as solid green). On a warm start
/// audio and video come up together and it looks fine, which is exactly the
/// intermittency QA described.
///
/// The native path has no such gap: [onFirstFrame] is driven by
/// `MEDIA_INFO_VIDEO_RENDERING_START` / `onRenderedFirstFrame`, which mean a
/// frame was actually drawn. It is also the configuration the working native
/// reference app uses for this identical `bootanimation.ts`, with no green.
///
/// The widget renders NOTHING of its own — no controls, no spinner, no error UI.
/// The splash owns all of that and simply keeps its branded screen up until
/// [onFirstFrame] fires.
class StbSurfaceBootVideo extends StatefulWidget {
  const StbSurfaceBootVideo({
    super.key,
    required this.url,
    this.onFirstFrame,
    this.onEnded,
  });

  /// `asset:///assets/video/...` for a bundled clip, or a plain URL. The native
  /// side maps the asset form onto `flutter_assets/` for both engines.
  final String url;

  /// A frame has actually been drawn — safe to reveal the video.
  final VoidCallback? onFirstFrame;

  /// Playback finished, or failed in a way it cannot recover from. The splash
  /// treats both the same way: stop waiting and move on.
  final VoidCallback? onEnded;

  @override
  State<StbSurfaceBootVideo> createState() => _StbSurfaceBootVideoState();
}

class _StbSurfaceBootVideoState extends State<StbSurfaceBootVideo> {
  StreamSubscription<dynamic>? _eventSub;

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  void _onPlatformViewCreated(int id) {
    _eventSub = EventChannel('${StbSurfacePlayer.viewType}/$id/events')
        .receiveBroadcastStream()
        .listen(_onEvent, onError: (Object e) {
      logger.w('[STB-boot] event channel error: $e');
      widget.onEnded?.call();
    });
  }

  void _onEvent(dynamic raw) {
    if (raw is! Map || !mounted) return;
    final map = Map<String, dynamic>.from(raw);
    switch (map['event'] as String?) {
      case 'firstFrame':
        logger.i('[STB-boot] first frame');
        widget.onFirstFrame?.call();
      case 'completed':
        widget.onEnded?.call();
      case 'error':
        logger.w('[STB-boot] boot video error: ${map['message']}');
        widget.onEnded?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformViewLink(
      viewType: StbSurfacePlayer.viewType,
      surfaceFactory: (context, controller) => AndroidViewSurface(
        controller: controller as AndroidViewController,
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        hitTestBehavior: PlatformViewHitTestBehavior.transparent,
      ),
      onCreatePlatformView: (params) {
        final controller = PlatformViewsService.initExpensiveAndroidView(
          id: params.id,
          viewType: StbSurfacePlayer.viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: <String, dynamic>{
            'url': widget.url,
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
}
