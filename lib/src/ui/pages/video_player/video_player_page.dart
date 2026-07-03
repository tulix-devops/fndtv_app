import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/ui/widgets/widgets.dart';
import 'package:flutter/services.dart';

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

    return Scaffold(
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
