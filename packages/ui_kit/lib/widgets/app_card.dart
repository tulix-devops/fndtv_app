import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
// ignore: library_prefixes
import 'package:shimmer/shimmer.dart' as DefaultShimmer;

const double _largeCardWidth = 180;

const double _largeCardHeight = 250;

const double _mediumCardWidth = 150;

const double _mediumCardHeight = 200;

const double _smallCardWidth = 184;

const double _smallCardHeight = 184;

const double _episodeCardWidth = 250;

const double _liveChannelCardWidth = 350;

const double _liveChannelCardHeight = 250;

final TextStyle cardTextStyle = TextStyles.bodySmallMedium;
final TextStyle tvCardTextStyle = TextStyles.bodyLargeMedium;
const String _defaultPosterImage =
    'https://wchupload.tulix.net/storage/etc/no-poster-found.png';

class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.image,
    required this.content,
    this.onTap,
    this.isSelected = false,
    this.extraPositionedChildren,
    this.onFocus,
    this.focusNode,
    this.isImageNetwork = true,
  })  : width = _largeCardWidth,
        height = _largeCardHeight;

  const AppCard.medium({
    super.key,
    required this.image,
    required this.content,
    this.onTap,
    this.isSelected = false,
    this.extraPositionedChildren,
    this.onFocus,
    this.focusNode,
    this.isImageNetwork = true,
  })  : width = _mediumCardWidth,
        height = _mediumCardHeight;

  const AppCard.tvSeries({
    super.key,
    required this.image,
    required this.content,
    this.onTap,
    this.isSelected = false,
    this.extraPositionedChildren,
    this.onFocus,
    this.focusNode,
    this.isImageNetwork = true,
  })  : width = _episodeCardWidth,
        height = _mediumCardHeight;

  const AppCard.liveChannels({
    super.key,
    required this.image,
    required this.content,
    this.onTap,
    this.isSelected = false,
    this.extraPositionedChildren,
    this.onFocus,
    this.focusNode,
    this.isImageNetwork = true,
  })  : width = _liveChannelCardWidth,
        height = _liveChannelCardHeight;

  const AppCard.small({
    super.key,
    required this.image,
    required this.content,
    this.onTap,
    this.isSelected = false,
    this.extraPositionedChildren,
    this.onFocus,
    this.focusNode,
    this.isImageNetwork = true,
  })  : width = _smallCardWidth,
        height = _smallCardHeight;

  final double height;
  final double width;

  /// Label or title of the card
  final Widget content;

  /// Image  of the card
  final String? image;
  final bool isImageNetwork;
  final void Function()? onTap;
  final void Function()? onFocus;
  final FocusNode? focusNode;

  final bool isSelected;
  final List<Positioned>? extraPositionedChildren;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  _focusListener() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    if (widget.focusNode != null) {
      widget.focusNode?.addListener(_focusListener);
    }

    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (!mounted) return;
    if (widget.isSelected != false) {
      setState(() {});
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.image == null) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.identity()..scale(.98),
      child: InkWell(
        focusColor: Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        onTap: widget.onTap,
        focusNode: widget.focusNode,
        onFocusChange: (value) {
          if (widget.onFocus != null) {
            widget.onFocus!();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient:
                  (widget.focusNode?.hasFocus ?? false) || widget.isSelected
                      ? context.uiColors.primaryGradient
                      : null,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: Container(
              margin: const EdgeInsets.all(4),
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.bottomLeft,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(9)),
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return AppColors.greyGradient.createShader(bounds);
                      },
                      blendMode: BlendMode.srcATop,
                      child: widget.isImageNetwork
                          ? Image.network(
                              widget.image!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.network(_defaultPosterImage);
                              },
                              loadingBuilder: (BuildContext context,
                                  Widget child,
                                  ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) return child;
                                return DefaultShimmer.Shimmer.fromColors(
                                  baseColor: context.uiColors.tvSurface
                                      .withOpacity(0.7),
                                  highlightColor: context.uiColors.secondary,
                                  child: Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            )
                          : Image.asset(
                              widget.image!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: widget.content,
                  ),
                  if (widget.extraPositionedChildren != null)
                    ...widget.extraPositionedChildren!
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CardItem extends StatefulWidget {
  const CardItem({
    super.key,
    required this.image,
    required this.title,
    this.label,
    this.subLabel,
    required this.onPressed,
    this.isOutlined,
    required this.button,
  });

  final String image;
  final String title;
  final String? label;
  final String? subLabel;
  final VoidCallback onPressed;
  final bool? isOutlined;
  final ({String buttonLabel, VoidCallback onPressed, String? icon}) button;

  @override
  State<CardItem> createState() => _CardItemState();
}

class _CardItemState extends State<CardItem> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _largeCardHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            onTap: widget.onPressed,
            content: const SizedBox.shrink(),
            image: widget.image,
          ),
          Margins.horizontal10,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                textBaseline: TextBaseline.alphabetic,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(
                    child: Text(
                      widget.title,
                      style: TextStyles.h5.surface(context),
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    ),
                  ),
                  if (widget.subLabel != null)
                    Text(
                      widget.subLabel!,
                      style: TextStyles.bodySmallMedium.surface(context),
                      textAlign: TextAlign.left,
                    ),
                  if (widget.label != null)
                    Text(
                      widget.label!,
                      style: TextStyles.bodyMediumSemiBold.surface(context),
                      textAlign: TextAlign.left,
                    ),
                  const Spacer(),
                  AppChip.mediumPrimaryRounded(
                    label: widget.button.buttonLabel,
                    onPressed: widget.button.onPressed,
                    isOutlined: widget.isOutlined ?? false,
                    prefixIcon: widget.button.icon != null
                        ? (asset: widget.button.icon!, size: 24)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
