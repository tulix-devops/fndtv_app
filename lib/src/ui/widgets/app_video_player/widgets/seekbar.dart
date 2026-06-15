import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/index.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:video_player/video_player.dart';

class Seekbar extends StatefulWidget {
  const Seekbar({
    super.key,
    required this.controller,
    this.updateVideoController,
    required this.isLive,
  });
  const Seekbar.live({
    super.key,
    required this.controller,
    this.updateVideoController,
  }) : isLive = true;
  const Seekbar.vod({
    super.key,
    required this.controller,
    this.updateVideoController,
  }) : isLive = false;

  final bool isLive;
  final VideoPlayerController controller;
  final void Function(String link)? updateVideoController;

  @override
  State<Seekbar> createState() => _SeekbarState();
}

class _SeekbarState extends State<Seekbar> {
  late FocusNode focusNode;
  bool isCurrent = true;
  final FocusNode buttonFocus = FocusNode();
  @override
  void initState() {
    focusNode = FocusNode()..requestFocus();
    super.initState();
  }

  @override
  void dispose() {
    focusNode.dispose();
    buttonFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isLive ? getLiveSeekbar(context) : getVodSeekbar(context);
  }

  Widget getLiveSeekbar(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: widget.controller,
      builder: (context, value, child) {
        final VideoPlayerCubit cubit = context.read<VideoPlayerCubit>();
        bool isThreeMinutesBehind = false;

        final threeMinutesBeforeEnd =
            value.duration - const Duration(minutes: 1);
        isThreeMinutesBehind = value.position < threeMinutesBeforeEnd;

        final String position = isThreeMinutesBehind
            ? value.position.formatCountdown(value.duration)
            : '00:00';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 38),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VideoSeekbar(
                updateController: widget.updateVideoController,
                controller: widget.controller,
                focusNode: focusNode,
              ),
            ],
          ),
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
              Text(
                position,
                style: TextStyles.bodyMediumBold.copyWith(
                  color: context.uiColors.onSurface,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: VideoSeekbar(
                    updateController: widget.updateVideoController,
                    focusNode: focusNode,
                    controller: widget.controller,
                  ),
                ),
              ),
              Text(
                duration,
                style: TextStyles.bodyMediumBold.copyWith(
                  color: context.uiColors.onSurface,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
