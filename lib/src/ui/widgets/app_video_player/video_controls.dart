part of 'app_video_player.dart';

class VideoControls extends StatefulWidget {
  const VideoControls({super.key, required this.controller});
  final VideoPlayerController controller;

  @override
  State<VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<VideoControls> {
  late final FocusNode seekBack;
  late final FocusNode play;
  late final FocusNode seekForward;

  late final List<FocusNode> focusList;

  void _seek(BuildContext context, {bool shouldSeekForward = true}) {
    final Duration currentPosition = widget.controller.value.position;

    final int newDuration = (shouldSeekForward ? 1 : -1) * 10;

    final Duration newPosition = Duration(
      seconds: newDuration + currentPosition.inSeconds,
    );

    widget.controller.seekTo(newPosition);

    context.read<VideoPlayerCubit>().handleVisibility();
  }

  String _playIcon() {
    return widget.controller.value.isPlaying
        ? Assets.videoPause
        : Assets.videoPlay;
  }

  void _togglePlayPause(BuildContext context) {
    final isPlaying = widget.controller.value.isPlaying;
    isPlaying ? widget.controller.pause() : widget.controller.play();
    context.read<VideoPlayerCubit>().setIsPlaying(!isPlaying);
    setState(() {});
  }

  @override
  void initState() {
    seekBack = FocusNode(
      onKeyEvent: (node, event) {
        return _handleKeyboard(event, (
          focusLeft: seekForward,
          focusRight: play,
        ));
      },
    );
    seekForward = FocusNode(
      onKeyEvent: (node, event) {
        return _handleKeyboard(event, (focusLeft: play, focusRight: seekBack));
      },
    );
    play = FocusNode(
      onKeyEvent: (node, event) {
        return _handleKeyboard(event, (
          focusLeft: seekBack,
          focusRight: seekForward,
        ));
      },
    );
    focusList = [seekBack, play, seekForward];
    super.initState();
  }

  KeyEventResult _handleKeyboard(
    KeyEvent event,
    ({FocusNode focusLeft, FocusNode focusRight}) focuses,
  ) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      focuses.focusLeft.requestFocus();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      FocusScope.of(context).focusInDirection(TraversalDirection.up);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      focuses.focusRight.requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    for (final node in focusList) {
      node.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Iterable<({String icon, Function(BuildContext context) onTap})> list =
        [
          (
            icon: Assets.videoBackward,
            onTap:
                (BuildContext context) =>
                    _seek(context, shouldSeekForward: false),
          ),
          (
            icon: _playIcon(),
            onTap: (BuildContext context) => _togglePlayPause(context),
          ),
          (
            icon: Assets.videoForward,
            onTap: (BuildContext context) => _seek(context),
          ),
        ];

    return Row(
      children: [
        for (final (index, item) in list.indexed) ...[
          VideoButton(
            focusNode: focusList[index],
            icon: item.icon,
            onPressed: (BuildContext context) => item.onTap(context),
          ),
        ],
      ],
    );
  }
}
