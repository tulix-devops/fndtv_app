import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
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
  @override
  void initState() {
    super.initState();
    print('hello');

    print(widget.video);
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

  @override
  Widget build(BuildContext context) {
    String link = widget.video.sources.getPreferredVideoSource() ?? '';
    print('this is the link $link');

    // The `stb` flavor (RK3328 boxes) plays through libVLC — ExoPlayer/Media3's
    // MediaCodec path fails there. All other builds keep the existing
    // video_player-based AppVideoPlayer unchanged. Radio stays on AppVideoPlayer
    // everywhere (audio-only; it renders its own "now playing" backdrop).
    final bool useVlc =
        appFlavor == 'stb' && widget.contentType != ContentType.radio;

    return Scaffold(
      backgroundColor: Colors.black,
      body: useVlc
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
