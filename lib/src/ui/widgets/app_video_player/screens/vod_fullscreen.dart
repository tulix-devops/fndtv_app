import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/index.dart';
import 'package:fndtv/src/ui/widgets/app_video_player/widgets/black_background.dart';

import 'package:ui_kit/ui_kit.dart';
import 'package:video_player/video_player.dart';

class VodFullScreen extends StatefulWidget {
  const VodFullScreen({
    super.key,
    required this.controller,
    required this.updateVideoController,
    required this.contentType,
  });

  final VideoPlayerController controller;
  final void Function(String link) updateVideoController;
  final ContentType contentType;

  @override
  State<VodFullScreen> createState() => _VodFullScreenState();
}

class _VodFullScreenState extends State<VodFullScreen> {
  late final FocusNode playPauseFocus;
  late final FocusNode arrowBackFocus;

  ({int selectedPage, int selectedItemIndex})? selectedLinkIndexes;

  bool isSeasonsOpen = false;

  void openDvr() {
    setState(() {
      isSeasonsOpen = true;
    });
  }

  @override
  void initState() {
    playPauseFocus = FocusNode(
      onKeyEvent: (node, event) {
        bool isInitialized = widget.controller.value.isInitialized;
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          final Duration currentPosition = widget.controller.value.position;
          context.read<VideoPlayerCubit>().handleVisibility();

          if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
              event.logicalKey == LogicalKeyboardKey.mediaRewind && isInitialized) {
            widget.controller.seekTo(
              currentPosition - const Duration(seconds: 30),
            );
            return KeyEventResult.handled;
          }
          if ((event.logicalKey == LogicalKeyboardKey.arrowRight ||
                  event.logicalKey == LogicalKeyboardKey.mediaFastForward) &&
              isInitialized) {
            widget.controller.seekTo(
              currentPosition + const Duration(seconds: 30),
            );
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.goBack) {
            arrowBackFocus.requestFocus();
            return KeyEventResult.ignored;
          }
        }
        return KeyEventResult.ignored;
      },
    );
    arrowBackFocus = FocusNode(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }
        context.read<VideoPlayerCubit>().handleVisibility();

        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          playPauseFocus.requestFocus();
          return KeyEventResult.handled;
        }

        if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.select) {
          context.pop();

          return KeyEventResult.handled;
        }
        return KeyEventResult.skipRemainingHandlers;
      },
    );
    playPauseFocus.requestFocus();
    super.initState();
  }

  @override
  void dispose() {
    arrowBackFocus.dispose();
    playPauseFocus.dispose();
    super.dispose();
  }

  String _playIcon() {
    return widget.controller.value.isPlaying ? Assets.videoPause : Assets.videoPlay;
  }

  void _togglePlayPause(BuildContext context) {
    final isPlaying = widget.controller.value.isPlaying;
    isPlaying ? widget.controller.pause() : widget.controller.play();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VideoPlayerCubit, VideoPlayerState>(
      listenWhen: (previous, current) => previous.isVisible != current.isVisible,
      listener: (context, state) {
        playPauseFocus.requestFocus();
      },
      builder: (context, state) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (state.isVisible) const BlackBackground(),
            if (!isSeasonsOpen) ...[
              Positioned(
                left: 60,
                top: 20,
                child: VideoButton(
                  onPressed: (ctx) {
                    context.pop();
                  },
                  icon: Assets.arrowLeft,
                  focusNode: arrowBackFocus,
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 2,
                      child: VideoButton(
                        onPressed: (context) {
                          _togglePlayPause(context);
                          context.read<VideoPlayerCubit>().handleVisibility();
                        },
                        icon: _playIcon(),
                        focusNode: playPauseFocus,
                      ),
                    ),
                    Flexible(flex: 7, child: getVodSeekbar(context)),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget getVodSeekbar(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: widget.controller,
      builder: (context, value, child) {
        final String duration = value.duration.formatDuration();
        final String position = value.position.formatDuration();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 38),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Text(position, style: TextStyles.bodyMediumBold.surface(context)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: VideoSeekbar(
                    controller: widget.controller,
                    updateController: widget.updateVideoController,
                  ),
                ),
              ),
              Text(duration, style: TextStyles.bodyMediumBold.surface(context)),
            ],
          ),
        );
      },
    );
  }
}
