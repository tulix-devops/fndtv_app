import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:fndtv/src/core/audio/radio_player_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

class ChewiePlayerPage extends StatelessWidget {
  final String title;
  final String url;

  const ChewiePlayerPage({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Center(
        child: ChewiePlayer(url: url),
      ),
    );
  }
}

class ChewiePlayer extends StatefulWidget {
  final String url;

  const ChewiePlayer({super.key, required this.url});

  @override
  State<ChewiePlayer> createState() => ChewiePlayerState();
}

class ChewiePlayerState extends State<ChewiePlayer> {
  VideoPlayerController? _controller;
  ChewieController? _chewie;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    RadioPlayerService.instance
        .stop(); // stop any background radio playback when opening a live channel
    if (widget.url.isEmpty) {
      setState(() => _failed = true);
      return;
    }
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        formatHint: VideoFormat.hls,
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _chewie = ChewieController(
          videoPlayerController: controller,
          autoPlay: true,
          looping: false,
          allowFullScreen: true,
          aspectRatio: 16 / 9,
          materialProgressColors: ChewieProgressColors(
            playedColor: const Color(0xFFA83734),
            handleColor: const Color(0xFFA83734),
            backgroundColor: Colors.grey,
            bufferedColor: Colors.white24,
          ),
        );
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: _failed
            ? const Center(
                child: Icon(Icons.videocam_off_rounded,
                    color: Colors.white54, size: 36),
              )
            : (_chewie != null
                ? Chewie(controller: _chewie!)
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )),
      ),
    );
  }
}
