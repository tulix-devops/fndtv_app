import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class DefaultButtonContent extends StatelessWidget {
  final ({String asset, double size})? prefixIcon;
  final ({String asset, double size})? suffixIcon;

  final Color iconColor;

  final double contentMargin;

  final Text text;

  const DefaultButtonContent({
    super.key,
    this.prefixIcon,
    this.suffixIcon,
    required this.contentMargin,
    required this.text,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final prefixIcon = this.prefixIcon != null
        ? AppIcon(
            this.prefixIcon!.asset,
            height: this.prefixIcon!.size,
            width: this.prefixIcon!.size,
            color: iconColor,
          )
        : const SizedBox.shrink();

    final suffixIcon = this.suffixIcon != null
        ? AppIcon(
            this.suffixIcon!.asset,
            height: this.suffixIcon!.size,
            width: this.suffixIcon!.size,
            color: iconColor,
          )
        : const SizedBox.shrink();

    return Wrap(
      spacing: contentMargin,
      direction: Axis.horizontal,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        prefixIcon,
        text,
        suffixIcon,
      ],
    );
  }
}
