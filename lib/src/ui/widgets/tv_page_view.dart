// import 'package:app_focus/app_focus.dart';
// import 'package:commons/commons.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:fndtv/src/ui/pages/content_detail/content_detail_page.dart';
// import 'package:fndtv/src/ui/pages/see_all/see_all_page.dart';
// import 'package:fndtv/src/ui/widgets/widgets.dart';
// import 'package:ui_kit/ui_kit.dart';

// class TvPageView extends StatefulWidget {
//   const TvPageView({
//     super.key,
//     required this.videos,
//     required this.focusNode,
//     this.contentTypeId,
//     this.headerTitle,
//     required this.onPressed,
//     this.onPageChanged,
//   });
//   final List<ContentModel> videos;
//   final FocusNode focusNode;
//   final int? contentTypeId;
//   final String? headerTitle;
//   final void Function(BuildContext context, ContentModel vod) onPressed;
//   final void Function(int activeIndex)? onPageChanged;

//   @override
//   State<TvPageView> createState() => TvPageViewState();
// }

// class TvPageViewState extends State<TvPageView> {
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       mainAxisAlignment: MainAxisAlignment.start,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         UiTvListHeader(headerTitle: widget.headerTitle ?? ''),
//         PageViewFocus(
//           infinityCarousel: widget.contentTypeId != ContentType.series.value,
//           focusNode: widget.focusNode,
//           pageCount: widget.videos.length,
//           onEnterPressed: (currentPageIndex, controller) {
//             _onCardPressed(context, widget.videos[currentPageIndex]);
//           },
//           onFocusChange: (value, controller) {
//             setState(() {
//               if (!value) return;

//               controller.onFocusReceived();
//             });
//           },
//           onPageChanged: widget.onPageChanged ?? (_) {},
//           builder: (context, controller, itemIndex, currentPageIndex) {
//             final bool isSelected =
//                 widget.focusNode.hasFocus &&
//                 controller.index.value == itemIndex;

//             final ContentModel video =
//                 widget.videos[controller.getItemIndex(itemIndex)];

//             // if (video.storage?.record.thumb == null) {
//             //   return const SizedBox.shrink();
//             // }

//             return VodAppCard(video: video, isSelected: isSelected);
//           },
//         ),
//       ],
//     );
//   }

//   void _onPressed(BuildContext context) {
//     context.pushNamed(
//       SeeAllPage.name,
//       extra: {
//         'contentCubit': context.read<ContentCubit>(),
//         'typeId': widget.contentTypeId,
//       },
//     );
//   }

//   void _onCardPressed(BuildContext context, ContentModel video) {
//     context.read<ContentCubit>().setSelectedContent(video);
//     context.pushNamed(ContentDetailPage.name, extra: {'content': video});
//   }
// }
