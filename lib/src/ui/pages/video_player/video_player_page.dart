import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/ui/widgets/widgets.dart';
import 'package:flutter/services.dart';

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({super.key, required this.video, required this.contentType});

  final LiveModel video;
  final ContentType contentType;

  static const name = 'video-player';
  static const path = 'video-player';

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  /// Captured once, before the user can rotate. [BuildContext.isTv] is derived
  /// from the MediaQuery size, so reading it again after a flip to landscape
  /// can give a different answer on a large screen.
  bool _isTv = false;
  bool _orientationApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_orientationApplied) return;
    _orientationApplied = true;
    _isTv = context.isTv;

    // Opens in portrait. Going landscape is the viewer's choice, made with the
    // rotate control in the player — the app used to force the flip the instant
    // an item was tapped.
    if (!_isTv) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  @override
  void dispose() {
    // Restore the app's baseline (see AppView._applyOrientation) instead of
    // leaving all four enabled, which let the whole app rotate afterwards
    // after a single visit to the player.
    SystemChrome.setPreferredOrientations(
      _isTv
          ? const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : const [
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ],
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String link = widget.video.sources.getPreferredVideoSource() ?? '';

    return Scaffold(
        // Black, so the letterbox around a 16:9 picture in portrait reads as
        // part of the player rather than as the app background showing through.
        backgroundColor: Colors.black,
        body: widget.contentType == ContentType.radio
            ? Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      widget.video.images.getThumbnail(),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Opacity(
                      opacity: .75,
                      child: AppVideoPlayer(
                        video: widget.video,
                        link: link,
                        isLive: widget.contentType != ContentType.dvr,
                        contentType: widget.contentType,
                      )),
                ],
              )
            : AppVideoPlayer(
                video: widget.video,
                link: link,
                isLive: widget.contentType != ContentType.dvr,
                contentType: widget.contentType,
              ));
  }
}
