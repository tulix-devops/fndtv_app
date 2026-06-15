// import 'package:flutter/material.dart';
// import 'package:fndtv/src/index.dart';
// import 'package:river_player/river_player.dart';
// import 'package:ui_kit/ui_kit.dart';

// class VideoHeader extends StatefulWidget {
//   const VideoHeader({super.key, required this.controller, required this.onTap});
//   final BetterPlayerController controller;
//   final void Function() onTap;

//   @override
//   State<VideoHeader> createState() => _VideoHeaderState();
// }

// class _VideoHeaderState extends State<VideoHeader> {
//   late FocusNode focusNode;

//   @override
//   void initState() {
//     focusNode = FocusNode();
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: <Widget>[
//         Padding(
//           padding: const EdgeInsets.only(left: 10),
//           child: VideoButton(
//             focusNode: focusNode,
//             onPressed: (_) {
//               widget.onTap();
//             },
//             icon: Assets.moreCircles,
//           ),
//         ),
//       ],
//     );
//   }
// }
