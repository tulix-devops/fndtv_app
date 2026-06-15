part of 'app_video_player.dart';

class VolumeSlider extends StatelessWidget {
  final VideoPlayerController controller;

  const VolumeSlider({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoPlayerCubit, VideoPlayerState>(
      buildWhen: _buildWhen,
      builder: (context, state) {
        final double value =
            state.isMuted ? 0.0 : state.videoVolume.previousVolume;

        return SizedBox(
          width: 80,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: CustomThumbShape(),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: value,
              inactiveColor: Colors.grey,
              min: 0.0,
              max: 1.0,
              onChanged: (newValue) => _onChange(newValue, context),
            ),
          ),
        );
      },
    );
  }

  bool _buildWhen(VideoPlayerState previous, VideoPlayerState current) =>
      previous.isMuted != current.isMuted ||
      previous.videoVolume != current.videoVolume;

  void _onChange(double newValue, BuildContext context) {
    controller.setVolume(newValue);

    context.read<VideoPlayerCubit>().setVolume(newValue);
  }
}
