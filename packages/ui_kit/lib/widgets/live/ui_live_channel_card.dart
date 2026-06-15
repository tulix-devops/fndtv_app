import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class UiLiveChannelCard extends StatelessWidget {
  const UiLiveChannelCard(
      {super.key,
      this.onPressed,
      this.onFocus,
      required this.channelTitle,
      required this.channelThumb,
      required this.isLive,
      this.focusNode,
      this.isSelected = false,
      this.isImageNetwork = true});

  final VoidCallback? onPressed;
  final VoidCallback? onFocus;

  final String channelTitle;
  final String channelThumb;
  final bool isLive;
  final FocusNode? focusNode;
  final bool isSelected;
  final bool isImageNetwork;

  @override
  Widget build(BuildContext context) {
    return AppCard.small(
      focusNode: focusNode,
      isSelected: isSelected,
      extraPositionedChildren: [
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.greyscale[600],
              gradient: isLive ? context.uiColors.primaryGradient : null,
              borderRadius: const BorderRadius.all(
                Radius.circular(8),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 10,
                right: 10,
                top: 6,
                bottom: 6,
              ),
              child: Text(
                isLive ? 'LIVE' : 'Offline',
                style: TextStyles.bodySmallBold,
              ),
            ),
          ),
        )
      ],
      onTap: onPressed,
      onFocus: onFocus,
      content: Text(
        channelTitle,
        style: cardTextStyle.white.copyWith(fontSize: 18),
      ),
      isImageNetwork: isImageNetwork,
      image: channelThumb,
    );
  }
}
