import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:fndtv/src/bloc/epg_cubit/epg_cubit.dart';
import 'package:fndtv/src/data/models/content/tv_schedule_model.dart';
import 'package:fndtv/src/index.dart';
import 'package:fndtv/src/ui/widgets/app_video_player/widgets/black_background.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:commons/commons.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class MobilePlayerContainer extends StatefulWidget {
  const MobilePlayerContainer({
    super.key,
    required this.live,
    this.dvrSource,
    this.isPodcast = false,
  });

  final TvScheduleModel? live;
  final bool isPodcast;
  final TvScheduleModel? dvrSource;

  @override
  State<MobilePlayerContainer> createState() => _MobilePlayerContainerState();
}

class _MobilePlayerContainerState extends State<MobilePlayerContainer> {
  late VideoPlayerController controller;
  bool _isInitializing = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _disposeController() {
    controller.pause();
    controller.dispose();
  }

  @override
  void didUpdateWidget(MobilePlayerContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.live?.link != widget.live?.link ||
        oldWidget.dvrSource?.link != widget.dvrSource?.link) {
      _disposeController();
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isInitializing = true;
      _isInitialized = false;
    });

    final sourceLink = widget.dvrSource?.link ?? widget.live!.link;
    
    controller = VideoPlayerController.networkUrl(Uri.parse(sourceLink));
    
    try {
      await controller.initialize();
      controller.setLooping(false);
      controller.play(); // Auto play
      
      setState(() {
        _isInitialized = true;
        _isInitializing = false;
      });
    } catch (e) {
      print('Error initializing video player: $e');
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isInitialized
        ? Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
              // Custom controls overlay
              CustomPlayerControl(
                controller: controller,
                video: widget.live!,
                isPodcast: widget.isPodcast,
              ),
              // Loading indicator when buffering
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  return value.isBuffering
                      ? const Center(child: AppLoadingIndicator(size: 50))
                      : const SizedBox.shrink();
                },
              ),
            ],
          )
        : Center(
            child: Container(
              width: double.infinity,
              height: 220,
              color: context.uiColors.surface,
              child: const AppLoadingIndicator(size: 60),
            ),
          );
  }
}

class CustomPlayerControl extends StatefulWidget {
  final VideoPlayerController controller;

  const CustomPlayerControl({
    super.key,
    required this.controller,
    this.isPodcast = false,
    required this.video,
  });

  final TvScheduleModel? video;
  final bool isPodcast;

  @override
  State<CustomPlayerControl> createState() => _CustomPlayerControlState();
}

class _CustomPlayerControlState extends State<CustomPlayerControl> {
  late FocusNode _inkFocus;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();

    _inkFocus = FocusNode(skipTraversal: true);
    _inkFocus.requestFocus();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _inkFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.video == null
        ? const AspectRatio(
            aspectRatio: 16 / 9,
            child: AppLoadingIndicator(size: 65),
          )
        : BlocBuilder<VideoPlayerCubit, VideoPlayerState>(
            buildWhen: (previous, current) => previous != current,
            builder: (context, state) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  InkWell(
                    focusNode: _inkFocus,
                    onTap: () =>
                        context.read<VideoPlayerCubit>().controlVisibility(),
                    child: IgnorePointer(
                      ignoring: !state.isVisible,
                      child: AnimatedOpacity(
                        opacity: state.isVisible ? 1.0 : 0.0,
                        curve: Curves.ease,
                        duration: const Duration(milliseconds: 300),
                        child: PlayerContorls(
                          controller: widget.controller,
                          isPodcast: widget.isPodcast,
                          video: widget.video!,
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

class PlayerContorls extends StatefulWidget {
  const PlayerContorls({
    super.key,
    required this.controller,
    required this.video,
    this.isPodcast = false,
  });

  final VideoPlayerController controller;
  final TvScheduleModel video;
  final bool isPodcast;

  @override
  State<PlayerContorls> createState() => _PlayerContorlsState();
}

class _PlayerContorlsState extends State<PlayerContorls> {
  late FocusNode _videoButtonFocus;
  late FocusNode _fullScreenFocus;
  late EpgCubit epgCubit;

  @override
  void initState() {
    epgCubit = context.read<EpgCubit>();
    super.initState();
    _videoButtonFocus = FocusNode();
    _fullScreenFocus = FocusNode();
  }

  @override
  void dispose() {
    _videoButtonFocus.dispose();
    _fullScreenFocus.dispose();
    super.dispose();
  }

  bool get _isLive {
    return epgCubit.state.selectedDvr == null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VideoPlayerCubit, VideoPlayerState>(
      listenWhen: (previous, current) =>
          previous.isVisible != current.isVisible,
      listener: (context, state) {},
      builder: (context, state) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (state.isVisible) const BlackBackground(),
            if (epgCubit.state.selectedDvr == null)
              Positioned(
                top: 20,
                right: 30,
                child: Container(
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
              ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 20,
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
                      focusNode: _videoButtonFocus,
                    ),
                  ),
                  _isLive || widget.isPodcast
                      ? const Spacer(flex: 6)
                      : Flexible(flex: 15, child: getVodSeekbar(context)),
                  Flexible(
                    flex: 2,
                    child: VideoButton(
                      onPressed: (context) {
                        if (MediaQuery.of(context).orientation ==
                            Orientation.portrait) {
                          SystemChrome.setPreferredOrientations([
                            DeviceOrientation.landscapeLeft,
                            DeviceOrientation.landscapeRight,
                          ]);
                          return;
                        } else {
                          SystemChrome.setPreferredOrientations([
                            DeviceOrientation.portraitUp,
                            DeviceOrientation.portraitDown,
                          ]).then((val) {
                            SystemChrome.setPreferredOrientations([
                              DeviceOrientation.portraitUp,
                              DeviceOrientation.portraitDown,
                              DeviceOrientation.landscapeLeft,
                              DeviceOrientation.landscapeRight,
                            ]);
                          });
                          return;
                        }
                      },
                      icon: Assets.videoFullScreen,
                      focusNode: _fullScreenFocus,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _togglePlayPause(BuildContext context) {
    final isPlaying = widget.controller.value.isPlaying;
    isPlaying ? widget.controller.pause() : widget.controller.play();
    setState(() {});
  }

  String _playIcon() {
    return widget.controller.value.isPlaying
        ? Assets.videoPause
        : Assets.videoPlay;
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
                  child: VideoProgressIndicator(
                    widget.controller,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: context.uiColors.primary,
                      bufferedColor: context.uiColors.primary.withOpacity(0.3),
                      // backgroundColor: context.uiColors.outline.withOpacity(0.3),
                    ),
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
