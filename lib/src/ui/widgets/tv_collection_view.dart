// import 'package:app_focus/widgets/page_view_focus.dart';
// import 'package:commons/shared/extensions.dart';
// import 'package:flutter/material.dart';
// import 'package:ui_kit/ui_kit.dart';
// import 'package:fndtv/src/data/models/content/content.dart';
// import 'package:fndtv/src/ui/pages/content_detail/content_detail_page.dart';
// import 'package:fndtv/src/ui/widgets/shared/content_app_card.dart';

// class TvCollectionView extends StatefulWidget {
//   const TvCollectionView({
//     super.key,
//     required this.videos,
//     required this.focusNode,
//     this.headerTitle,
//     required this.onPressed,
//     this.onPageChanged,
//   });
//   final List<ContentModel> videos;
//   final FocusNode focusNode;
//   final String? headerTitle;
//   final void Function(BuildContext context, ContentModel vod) onPressed;
//   final void Function(int activeIndex)? onPageChanged;
//   @override
//   State<TvCollectionView> createState() => TvCollectionViewState();
// }

// class TvCollectionViewState extends State<TvCollectionView> {
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       mainAxisAlignment: MainAxisAlignment.start,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         UiTvListHeader(headerTitle: widget.headerTitle ?? ''),
//         PageViewFocus(
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

//             return ContentAppCard(video: video, isSelected: isSelected);
//           },
//         ),
//       ],
//     );
//   }

//   void _onCardPressed(BuildContext context, ContentModel content) {
//     context.pushNamed(ContentDetailPage.name, extra: {'content': content});
//   }

//   // void _onPressed(BuildContext context, VodModel vod) {
//   //   context.read<VodCubit>().setSelectedContent(vod);
//   //   widget.onPressed(context, vod);
//   // }
// }
