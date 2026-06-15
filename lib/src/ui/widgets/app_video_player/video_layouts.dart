// part of 'app_video_player.dart';

// class VideoFullScreen extends StatelessWidget {
//   final BetterPlayerController controller;
//   final bool isLocked;
//   final bool isLive;

//   const VideoFullScreen({
//     super.key,
//     required this.controller,
//     required this.isLocked,
//     required this.isLive,
//   });

//   String _isMuted(VideoPlayerState state) {
//     return state.isMuted || state.videoVolume.currentVolume == 0.0
//         ? Assets.videoMute
//         : Assets.videoVolume;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Positioned(
//       left: 10,
//       right: 10,
//       bottom: 35,
//       child: ValueListenableBuilder<VideoPlayerValue>(
//         valueListenable: controller.videoPlayerController!,
//         builder: (context, value, child) {
//           final VideoPlayerCubit cubit = context.read<VideoPlayerCubit>();
//           final String duration = cubit.formatDuration(value.duration);
//           final String position = cubit.formatDuration(value.position);

//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               if (!isLive) _buildSeekBar(context, position, duration),
//               const SizedBox(height: 20),
//               _buildControlBar(context),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildSeekBar(BuildContext context, String position, String duration) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 38),
//       child: Row(
//         mainAxisSize: MainAxisSize.max,
//         children: [
//           Text(
//             position,
//             style: TextStyles.bodyMediumBold.surface(context),
//           ),
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 10),
//               child: VideoSeekbar(
//                 focusNode: FocusNode(),
//                 controller: controller,
//               ),
//             ),
//           ),
//           Text(
//             duration,
//             style: TextStyles.bodyMediumBold.surface(context),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildControlBar(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           _buildVolumeControl(context),
//           _buildFullscreenButton(context),
//         ],
//       ),
//     );
//   }

//   Widget _buildVolumeControl(BuildContext context) {
//     return BlocConsumer<VideoPlayerCubit, VideoPlayerState>(
//       listener: (context, state) =>
//           controller.setVolume(state.videoVolume.currentVolume),
//       builder: (context, state) {
//         return Row(
//           children: [
//             VideoButton(
//               focusNode: FocusNode(),
//               icon: _isMuted(state),
//               onPressed: (_) => context.read<VideoPlayerCubit>().muteVideo(),
//             ),
//             VolumeSlider(controller: controller),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildFullscreenButton(BuildContext context) {
//     return VideoButton(
//       focusNode: FocusNode(),
//       icon: Assets.videoFullScreen,
//       onPressed: (_) async {
//         await context.read<VideoPlayerCubit>().fullScreen();
//         controller.toggleFullScreen();
//       },
//     );
//   }
// }

// class VideoPortrait extends StatelessWidget {
//   final bool isLive;
//   final BetterPlayerController controller;

//   const VideoPortrait({
//     super.key,
//     required this.controller,
//     required this.isLive,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Positioned(
//       left: 10,
//       right: 10,
//       bottom: 8,
//       child: ValueListenableBuilder<VideoPlayerValue>(
//         valueListenable: controller.videoPlayerController!,
//         builder: (context, value, child) {
//           final VideoPlayerCubit cubit = context.read<VideoPlayerCubit>();
//           final String position = cubit.formatDuration(value.position);
//           final String duration = cubit.formatDuration(value.duration);

//           return Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               if (!isLive) _buildDurationDisplay(position, duration, context),
//               _buildFullscreenButton(context),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildDurationDisplay(
//       String position, String duration, BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.only(left: 10),
//       alignment: Alignment.center,
//       child: Text(
//         '$position/$duration',
//         style: TextStyles.bodyMediumBold.surface(context),
//       ),
//     );
//   }

//   Widget _buildFullscreenButton(BuildContext context) {
//     return VideoButton(
//       focusNode: FocusNode(),
//       icon: Assets.videoFullScreen,
//       onPressed: (_) async {
//         await context.read<VideoPlayerCubit>().fullScreen();
//         controller.toggleFullScreen();
//       },
//     );
//   }
// }

// class TvFullScreen extends StatelessWidget {
//   final BetterPlayerController controller;
//   final FocusNode? sliderFocus;
//   final bool isLive;

//   const TvFullScreen({
//     super.key,
//     required this.controller,
//     required this.sliderFocus,
//     required this.isLive,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Positioned(
//       left: 10,
//       right: 10,
//       bottom: 35,
//       child: ValueListenableBuilder<VideoPlayerValue>(
//         valueListenable: controller.videoPlayerController!,
//         builder: (context, value, child) {
//           final VideoPlayerCubit cubit = context.read<VideoPlayerCubit>();
//           final String duration = cubit.formatDuration(value.duration);
//           final String position = cubit.formatDuration(value.position);

//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               if (!isLive) _buildSeekBar(context, position, duration),
//               const SizedBox(height: 55),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildSeekBar(BuildContext context, String position, String duration) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 38),
//       child: Row(
//         mainAxisSize: MainAxisSize.max,
//         children: [
//           Text(
//             position,
//             style: TextStyles.bodyMediumBold.surface(context),
//           ),
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 10),
//               child: VideoSeekbar(
//                 focusNode: sliderFocus,
//                 controller: controller,
//               ),
//             ),
//           ),
//           Text(
//             duration,
//             style: TextStyles.bodyMediumBold.surface(context),
//           ),
//         ],
//       ),
//     );
//   }
// }
