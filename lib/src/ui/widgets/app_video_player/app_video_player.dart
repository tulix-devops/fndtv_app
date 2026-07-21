import 'dart:async';

import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/bloc/bloc.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';

import 'package:ui_kit/ui_kit.dart';
import 'package:fndtv/src/ui/widgets/app_video_player/screens/live_fullscreen.dart';
import 'package:fndtv/src/ui/widgets/app_video_player/screens/vod_fullscreen.dart';
import 'package:fndtv/src/ui/widgets/app_video_player/widgets/radio_now_playing.dart';
import 'package:video_player/video_player.dart';

part 'video_button.dart';
part 'video_controls.dart';
part 'video_seekbar.dart';
part 'volume_slider.dart';

class AppVideoPlayer extends StatefulWidget {
  const AppVideoPlayer({
    super.key,
    required this.link,
    required this.video,
    required this.isLive,
    required this.contentType,
    this.showBackButton = true,
  });

  final String link;
  final LiveModel video;
  final bool isLive;
  final ContentType contentType;
  final bool showBackButton;

  @override
  State<AppVideoPlayer> createState() => _AppVideoPlayerState();
}

class _AppVideoPlayerState extends State<AppVideoPlayer> {
  VideoPlayerController? _videoPlayerController;

  bool isLive = true;

  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    print(widget.video.sources);
    context.read<VideoPlayerCubit>().reset();
    isLive = widget.isLive;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializePlayer(widget.link);
    });
  }

  void _changeVideoType() {
    isLive = false;
    setState(() {});
  }

  void _initializePlayer(String link) {
    _isLoading.value = true;

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(link),
      formatHint: VideoFormat.hls,
    );
    _videoPlayerController = controller;
    _addPlayerEventListeners();

    controller.initialize().then((_) {
      if (!mounted || _videoPlayerController != controller) return;
      setState(() {});
      controller.setLooping(false);
      controller.setVolume(1.0);
      controller.setPlaybackSpeed(1.0);
      controller.play();
    }).catchError((Object error) {
      debugPrint('Video player initialization error: $error');
      if (!mounted || _videoPlayerController != controller) return;
      _isLoading.value = false;
      setState(() {});
    });
  }

  void _handleBuffering() {
    final bool? isBuffering = _videoPlayerController?.value.isBuffering;
    if (isBuffering != null) {
      _isLoading.value = isBuffering;
    }
  }

  void _videoPlayerListener() {
    final bool isPlaying = _videoPlayerController!.value.isPlaying;
    final bool isBuffering = _videoPlayerController!.value.isBuffering;

    // Manage loading indicator
    if (isPlaying && !isBuffering) {
      _isLoading.value = false;
    } else if (isBuffering) {
      _handleBuffering();
    }
  }

  void _addPlayerEventListeners() {
    _videoPlayerController?.addListener(_videoPlayerListener);
  }

  void _updateVideoPlayerController(String link) {
    removeListeners();
    _videoPlayerController?.dispose();
    _isLoading.value = true;
    setState(() {});
    _initializePlayer(link);
  }

  @override
  void dispose() {
    _isLoading.dispose();
    removeListeners();

    _videoPlayerController?.dispose();
    super.dispose();
  }

  void removeListeners() {
    _videoPlayerController?.removeListener(_videoPlayerListener);
  }

  @override
  Widget build(BuildContext context) {
    if (_videoPlayerController == null ||
        !_videoPlayerController!.value.isInitialized) {
      return Center(
        child: CircularProgressIndicator(color: context.uiColors.primary),
      );
    }

    // Use Chewie for inline player (Home screen)

    // Use custom controls for fullscreen player
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (res, _) async {},
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_videoPlayerController!),
          ValueListenableBuilder<bool>(
            valueListenable: _isLoading,
            builder: (context, isLoading, _) {
              return isLoading
                  ? Container(
                      color: Colors.black,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: context.uiColors.primary,
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
          _CustomPlayerControl(
            updateVideoType: _changeVideoType,
            isLive: isLive,
            controller: _videoPlayerController!,
            video: widget.video,
            updateVideoController: _updateVideoPlayerController,
            contentType: widget.contentType,
            showBackButton: widget.showBackButton,
          ),
        ],
      ),
    );
  }
}

class _CustomPlayerControl extends StatefulWidget {
  final VideoPlayerController controller;

  final LiveModel video;
  final bool isLive;
  final void Function(String link) updateVideoController;
  final void Function() updateVideoType;
  final ContentType contentType;
  final bool showBackButton;

  const _CustomPlayerControl({
    required this.controller,
    required this.video,
    required this.isLive,
    required this.updateVideoController,
    required this.updateVideoType,
    required this.contentType,
    required this.showBackButton,
  });

  @override
  State<_CustomPlayerControl> createState() => _CustomPlayerControlState();
}

class _CustomPlayerControlState extends State<_CustomPlayerControl> {
  late FocusNode _inkFocus;

  @override
  void initState() {
    super.initState();

    _inkFocus = FocusNode(
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.goBack) {
          Future.delayed(const Duration(milliseconds: 200), () {
            context.read<VideoPlayerCubit>().handleVisibility();
          });

          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
    );
    _inkFocus.requestFocus();
  }

  @override
  void dispose() {
    _inkFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoPlayerCubit, VideoPlayerState>(
      builder: (context, state) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Radio is audio-only: show a persistent "now playing" backdrop
            // (stays visible even when the controls fade out).
            if (widget.contentType == ContentType.radio)
              RadioNowPlaying(video: widget.video),
            InkWell(
              focusNode: _inkFocus,
              onTap: () => context.read<VideoPlayerCubit>().controlVisibility(),
              child: IgnorePointer(
                ignoring: !state.isVisible,
                child: AnimatedOpacity(
                  opacity: state.isVisible ? 1.0 : 0.0,
                  curve: Curves.ease,
                  duration: const Duration(milliseconds: 300),
                  child: VodFullScreen(
                    controller: widget.controller,
                    updateVideoController: widget.updateVideoController,
                    contentType: widget.contentType,
                    video: widget.video,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
