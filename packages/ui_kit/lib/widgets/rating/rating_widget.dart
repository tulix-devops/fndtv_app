import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class RatingWidget extends StatelessWidget {
  const RatingWidget({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.uiColors.primary,
        borderRadius: const BorderRadius.all(
          Radius.circular(8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 6, bottom: 6),
        child: Text(
          title,
          style: TextStyles.bodySmallBold,
        ),
      ),
    );
  }
}
