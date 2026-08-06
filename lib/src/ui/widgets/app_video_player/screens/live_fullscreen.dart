import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:fndtv/src/index.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/ui/widgets/app_video_player/widgets/black_background.dart';
import 'package:fndtv/src/ui/pages/dvr/dvr_page.dart';
import 'package:video_player/video_player.dart';

class LiveFullscreen extends StatefulWidget {
  const LiveFullscreen({
    super.key,
    required this.controller,
    required this.updateVideoController,
    required this.changeVideoType,
    required this.video,
    this.showBackButton = true,
  });

  final VideoPlayerController controller;
  final void Function() changeVideoType;
  final void Function(String link) updateVideoController;
  final LiveModel video;
  final bool showBackButton;

  @override
  State<LiveFullscreen> createState() => _LiveFullscreenState();
}

class _LiveFullscreenState extends State<LiveFullscreen> {
  bool isDvrOpen = false;

  final FocusNode arrowBackFocus = FocusNode();
  final FocusNode dvrFocus = FocusNode();
  late FocusNode playPauseFocus;

  /// Captured once, while still portrait. [BuildContext.isTv] is size-derived
  /// and flips to true when a 420dpi phone rotates to landscape (923x411,
  /// diagonal 1011 clears both its thresholds), so it must not be read during
  /// build. Same guard as VodFullScreen.
  bool _isTv = false;
  bool _isTvCaptured = false;

  /// Read every build, unlike [_isTv]: these genuinely differ per orientation.
  EdgeInsets get _safeInsets => MediaQuery.of(context).padding;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isTvCaptured) return;
    _isTvCaptured = true;
    _isTv = context.isTv;
  }

  @override
  void initState() {
    super.initState();
    playPauseFocus = FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          context.read<VideoPlayerCubit>().handleVisibility();
          // if (event.logicalKey == LogicalKeyboardKey.goBack) {
          //   return KeyEventResult.handled;
          // }
        }
        return KeyEventResult.ignored;
      },
    )..requestFocus();

    widget.controller.addListener(_onVideoUpdate);
  }

  @override
  void dispose() {
    playPauseFocus.dispose();
    widget.controller.removeListener(_onVideoUpdate);
    super.dispose();
  }

  void _onVideoUpdate() => setState(() {});

  void _togglePlayPause() {
    final isPlaying = widget.controller.value.isPlaying;
    isPlaying ? widget.controller.pause() : widget.controller.play();
    context.read<VideoPlayerCubit>().handleVisibility();
    setState(() {});
  }

  void _closeDvr() {
    setState(() {
      isDvrOpen = false;
    });
    playPauseFocus.requestFocus();
  }

  void _openDvr() {
    setState(() {
      isDvrOpen = true;
    });
    context.read<VideoPlayerCubit>().changeVisibility(true);
  }

  Widget _buildDvrOverlay() {
    return DvrPage(
      dvrUrl: widget.video.dvrUrl,
      isOverlay: true,
      onClose: _closeDvr,
    );
  }

  Widget _buildControls() {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    return Stack(
      children: [
        if (context.read<VideoPlayerCubit>().state.isVisible) const BlackBackground(),
        // 60/20 is TV overscan margin; on a phone it indents oddly and tucks
        // the controls under the status bar. Matches VodFullScreen.
        if (widget.showBackButton)
          Positioned(
            left: _isTv ? 60 : _safeInsets.left + 10,
            top: _isTv ? 20 : _safeInsets.top + 8,
            child: VideoButton(
              onPressed: (_) => context.pop(),
              icon: Assets.arrowLeft,
              focusNode: arrowBackFocus,
            ),
          ),
        if (widget.video.hasDvr)
          Positioned(
            right: _isTv ? 60 : _safeInsets.right + 10,
            top: _isTv ? 20 : _safeInsets.top + 8,
            child: Focus(
              focusNode: dvrFocus,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.select) {
                    _openDvr();
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: Builder(
                builder: (context) {
                  final hasFocus = Focus.of(context).hasFocus;
                  return InkWell(
                    onTap: _openDvr,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: hasFocus ? context.uiColors.primary : Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: hasFocus ? context.uiColors.onSurface : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.dvr,
                            color: context.uiColors.onSurface,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'DVR',
                            style: TextStyles.bodyLarge.copyWith(
                              color: context.uiColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        Positioned(
          left: 60,
          right: 60,
          bottom: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: VideoButton(
                  onPressed: (_) => _togglePlayPause(),
                  icon: widget.controller.value.isPlaying ? Assets.videoPause : Assets.videoPlay,
                  focusNode: playPauseFocus,
                ),
              ),
              if (widget.showBackButton)
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  child: Text(
                    'LIVE',
                    style: TextStyles.bodyLarge.surface(context),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return BlocListener<VideoPlayerCubit, VideoPlayerState>(
      listenWhen: (prev, curr) => prev.isVisible != curr.isVisible,
      listener: (_, __) => playPauseFocus.requestFocus(),
      child: Stack(
        children: [
          if (isDvrOpen) _buildDvrOverlay() else _buildControls(),
        ],
      ),
    );
  }
}
