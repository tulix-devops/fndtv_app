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
  final FocusNode orientationFocus = FocusNode(skipTraversal: true);

  /// Captured once, while still portrait.
  ///
  /// [BuildContext.isTv] is derived from the MediaQuery size, and on a 420dpi
  /// phone the landscape logical size (923x411, diagonal 1011) clears both its
  /// thresholds — so reading it during build makes the device "become a TV" the
  /// moment it rotates, which hid the rotate control and stranded the viewer in
  /// landscape with no way back.
  bool _isTv = false;
  bool _isTvCaptured = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Guarded: this fires again on every rotation, which is precisely when the
    // answer would change.
    if (_isTvCaptured) return;
    _isTvCaptured = true;
    _isTv = context.isTv;
  }

  @override
  void dispose() {
    arrowBackFocus.dispose();
    playPauseFocus.dispose();
    orientationFocus.dispose();
    super.dispose();
  }

  /// Flips between portrait and landscape on demand.
  ///
  /// The player opens portrait now, so this is how a viewer opts into
  /// landscape. Each tap locks the orientation it selects rather than handing
  /// control back to the accelerometer, so the control is predictable: tap to
  /// go wide, tap again to come back. [VideoPlayerPage] restores the app's
  /// portrait baseline when the page is popped.
  void _toggleOrientation(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    SystemChrome.setPreferredOrientations(
      isPortrait
          ? const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : const [
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ],
    );
  }

  String _playIcon() {
    return widget.controller.value.isPlaying ? Assets.videoPause : Assets.videoPlay;
  }

  void _togglePlayPause(BuildContext context) {
    final isPlaying = widget.controller.value.isPlaying;
    isPlaying ? widget.controller.pause() : widget.controller.play();
    setState(() {});
  }

  /// Read every build, unlike [_isTv]: the notch/status-bar insets genuinely
  /// differ between portrait and landscape, so these must follow rotation.
  EdgeInsets get _safeInsets => MediaQuery.of(context).padding;

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
              // 60/20 is TV overscan margin. On a phone it reads as an
              // arbitrary indent, and top:20 tucks the arrow up under the
              // status bar — so inset from the safe area instead, with the
              // left edge lined up with the control row below.
              Positioned(
                left: _isTv ? 60 : _safeInsets.left + 10,
                top: _isTv ? 20 : _safeInsets.top + 8,
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
                    // Not on TV: there is no orientation to change there, and
                    // no pointer to tap it with.
                    if (!_isTv)
                      Flexible(
                        flex: 2,
                        child: VideoButton(
                          onPressed: _toggleOrientation,
                          icon: Assets.videoFullScreen,
                          focusNode: orientationFocus,
                        ),
                      ),
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
