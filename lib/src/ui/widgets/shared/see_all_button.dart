import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class SeeAllButton extends StatelessWidget {
  const SeeAllButton({
    super.key,
    required this.isSelected,
  });

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    const String label = 'See all';

    return isSelected
        ? AppButton.primary(
            label: label,
            onPressed: () {},
            gradient: context.uiColors.primaryGradient,
          )
        : AppButton.secondary(
            label: label,
            onPressed: () {},
          );
  }
}
