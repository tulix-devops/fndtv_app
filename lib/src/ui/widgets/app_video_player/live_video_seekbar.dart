// import 'package:flutter/material.dart';
// import 'package:fndtv/src/index.dart';

// import 'package:ui_kit/ui_kit.dart';
// import 'package:video_player/video_player.dart';

// class LiveVideoSeekbar extends StatefulWidget {
//   const LiveVideoSeekbar({
//     super.key,
//     required this.controller,
//     required this.focusNode,
//   });

//   final VideoPlayerController controller;
//   final FocusNode focusNode;

//   @override
//   State<LiveVideoSeekbar> createState() => _LiveVideoSeekbarState();
// }

// class _LiveVideoSeekbarState extends State<LiveVideoSeekbar> {
//   double _value = 0.0;

//   Duration get _position =>
//       widget.controller.videoPlayerController!.value.position;
//   Duration? get _duration =>
//       widget.controller.videoPlayerController!.value.duration;

//   @override
//   void initState() {
//     super.initState();
//     widget.controller.addEventsListener((_) => _updateSeekbar());
//   }

//   void _updateSeekbar() {
//     if (!mounted) return;
//     final int position = _position.inSeconds;
//     final int duration = _duration?.inSeconds ?? 0;
//     final double newValue = duration != 0 ? position / duration : 0;
//     setState(() {
//       _value = duration != 0 ? newValue : 0;
//     });
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     widget.focusNode.addListener(() {
//       if (!mounted) return;
//       setState(() {});
//     });
//   }

//   @override
//   void dispose() {
//     widget.controller.removeEventsListener((_) => _updateSeekbar());
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return DecoratedBox(
//       decoration: BoxDecoration(
//         borderRadius: const BorderRadius.all(Radius.circular(20)),
//         color: (widget.focusNode.hasFocus) ? context.uiColors.primary : null,
//       ),
//       child: SliderTheme(
//         data: SliderTheme.of(context).copyWith(
//           thumbShape: CustomThumbShape(),
//           disabledActiveTrackColor: Colors.yellow,
//           overlayShape: SliderComponentShape.noOverlay,
//         ),
//         child: MediaQuery(
//           data: const MediaQueryData(
//             navigationMode: NavigationMode.directional,
//           ),
//           child: Slider(
//             focusNode: widget.focusNode,
//             value: _value,
//             inactiveColor: Colors.grey,
//             min: 0.0,
//             max: 1.0,
//             onChanged: (newValue) {
//               if (mounted) {
//                 setState(() {
//                   _value = newValue;
//                 });
//               }
//               final newProgress = Duration(
//                 milliseconds: (_value * _duration!.inMilliseconds).toInt(),
//               );
//               widget.controller.seekTo(newProgress);
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }
