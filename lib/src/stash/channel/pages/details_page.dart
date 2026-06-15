// import 'package:flutter/material.dart';

// import 'package:fndtv/src/data/models/vod/vod_model.dart';
// import 'package:fndtv/src/stash/channel/widgets/video_program_list.dart';
// import 'package:fndtv/src/ui/widgets/widgets.dart';
// import 'package:ui_kit/ui_kit.dart';
// import 'package:fndtv/src/core/core.dart';

// class DetailsPage extends StatefulWidget {
//   const DetailsPage({
//     required this.data,
//     super.key,
//   });

//   final VodModel data;

//   static const path = 'detail';
//   static const name = 'detail';

//   @override
//   State<DetailsPage> createState() => _DetailsPageState();
// }

// class _DetailsPageState extends State<DetailsPage> {
//   void _showFullScreenDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return Dialog(
//           surfaceTintColor: Colors.transparent,
//           backgroundColor: context.isTv
//               ? context.uiColors.tvSurface
//               : context.uiColors.surface,
//           insetPadding: EdgeInsets.zero,
//           child: FractionallySizedBox(
//             heightFactor: 0.8,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 _Header(
//                   label: 'Close',
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                   },
//                 ),
//                 const Expanded(
//                   child: SingleChildScrollView(
//                     child: VideoProgramList(
//                       isExpanded: true,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final AppVideoPlayer videoPlayer = AppVideoPlayer(
//       video: widget.data.,
//       image: widget.data.storageRecord?.poster ?? '',
//       link: widget.data.storageRecord?.trailer ?? '',
//     );

//     return AppScaffold(
//         hasNavbar: false,
//         body: DeviceWrapper(
//           tvWidget: AspectRatio(
//             aspectRatio: 16 / 9,
//             child: videoPlayer,
//           ),
//           widget: CustomScrollView(
//             slivers: [
//               PageHeader(
//                 isTv: context.isTv,
//                 onPressed: () {
//                   // context.pop();
//                 },
//                 isMainPage: false,
//                 page: 'Details',
//               ),
//               SliverToBoxAdapter(
//                 child: SingleChildScrollView(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       AspectRatio(
//                         aspectRatio: 16 / 9,
//                         child: videoPlayer,
//                       ),
//                       Margins.vertical20,
//                       Padding(
//                         padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(widget.data.title, style: TextStyles.h4),
//                             Margins.vertical20,
//                             Margins.vertical20,
//                             const _ActionsRow(),
//                             Margins.vertical20,
//                             Text(widget.data.description),
//                           ],
//                         ),
//                       ),
//                       Margins.vertical20,
//                       // _Header(
//                       //   onPressed: () {
//                       //     _showFullScreenDialog(context);
//                       //   },
//                       //   label: 'Expand',
//                       // ),
//                       // const VideoProgramList(isExpanded: false),
//                       const SizedBox(height: 50)
//                     ],
//                   ),
//                 ),
//               )
//             ],
//           ),
//         ));
//   }
// }

// class _Header extends StatelessWidget {
//   const _Header({
//     required this.onPressed,
//     required this.label,
//   });

//   final VoidCallback onPressed;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
//       child: Row(
//         children: [
//           const Text('Stream Programs', style: TextStyles.h5),
//           const Spacer(),
//           AppTextButton(
//             onPressed: onPressed,
//             label: label,
//             style: TextStyles.bodyMediumSemiBold.primary(context),
//           )
//         ],
//       ),
//     );
//   }
// }

// class _Chip extends StatelessWidget {
//   const _Chip({
//     required this.label,
//   });
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         border: Border.all(width: 1.5, color: context.uiColors.primary),
//         borderRadius: const BorderRadius.all(Radius.circular(5.0) //
//             ),
//       ),
//       child: Text(
//         label,
//         style: TextStyles.bodyXSmallSemiBold.copyWith(
//           color: context.uiColors.primary,
//         ),
//       ),
//     );
//   }
// }

// class _ActionsRow extends StatelessWidget {
//   const _ActionsRow();

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: AppChip.mediumPrimaryRounded(
//             label: 'Play',
//             onPressed: () {},
//             prefixIcon: (asset: Assets.play, size: 24),
//           ),
//         ),
//         const SizedBox(width: 8),
//         Expanded(
//           child: AppChip.mediumPrimaryRounded(
//             label: 'Download',
//             isOutlined: true,
//             onPressed: () {},
//             color: context.uiColors.primary,
//             prefixIcon: (asset: Assets.download, size: 24),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _RatingRow extends StatelessWidget {
//   const _RatingRow({required this.categories});

//   final List<String> categories;

//   @override
//   Widget build(BuildContext context) {
//     final Color iconColor = context.uiColors.primary;

//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: [
//         AppIcon(
//           Assets.star,
//           color: iconColor,
//         ),
//         const Text('9.8'),
//         AppIcon(
//           Assets.singleArrowRight,
//           color: iconColor,
//         ),
//         const Text('2022'),
//         for (final category in categories) _Chip(label: category)
//       ],
//     );
//   }
// }
