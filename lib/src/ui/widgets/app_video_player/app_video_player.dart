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
import 'package:wakelock_plus/wakelock_plus.dart';

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

  /// Keep-screen-awake, held only while video actually plays. Nothing else
  /// keeps a TV awake here — video_player does not — so without it Fire TV's
  /// screensaver, then sleep, cut into long live viewing.
  bool _wakelockHeld = false;

  /// The keep-awake state from before this player opened, asked for before we
  /// change it (platform calls answer in order). A phone channel page holds
  /// its own wake lock while this full-screen player sits on top of it, so on
  /// leaving we restore that state rather than switching it off.
  late final Future<bool> _wakelockBefore;

  @override
  void initState() {
    super.initState();
    _wakelockBefore = WakelockPlus.enabled;
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

    // Awake while playing; a paused screen may sleep like any other.
    if (isPlaying != _wakelockHeld) {
      _wakelockHeld = isPlaying;
      WakelockPlus.toggle(enable: isPlaying);
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
    _wakelockBefore.then((on) => WakelockPlus.toggle(enable: on));
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

    // Use custom controls for fullscreen player. Back is decided by the
    // PopScope in [VodFullScreen] — a PopScope(canPop: false) here used to
    // swallow every pop, which trapped remote-only viewers in the player.
    return Stack(
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

    // No Back handling here: marking goBack handled stops Android from turning
    // it into the route pop that [VodFullScreen]'s PopScope decides on.
    _inkFocus = FocusNode(skipTraversal: true);
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
