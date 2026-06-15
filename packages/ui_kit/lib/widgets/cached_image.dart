// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/widgets.dart';
// import 'package:transparent_image/transparent_image.dart';

// class CachedImage extends StatefulWidget {
//   const CachedImage({super.key, required this.url, this.fadeInDuration});

//   final String url;

//   /// fade in duration for animation
//   final int? fadeInDuration;

//   @override
//   State<CachedImage> createState() => _CachedImageState();
// }

// class _CachedImageState extends State<CachedImage> {
//   @override
//   Widget build(BuildContext context) {
//     return FadeInImage(
//       fadeInDuration: Duration(milliseconds: widget.fadeInDuration ?? 150),
//       image: CachedNetworkImageProvider(widget.url),
//       fadeInCurve: Curves.easeIn,
//       fadeOutCurve: Curves.easeOut,
//       placeholder: MemoryImage(kTransparentImage),
//       imageErrorBuilder: (_, __, ___) => const SizedBox.shrink(),
//     );
//   }
// }
