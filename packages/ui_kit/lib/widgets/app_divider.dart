import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class AppDivider extends StatelessWidget {
  const AppDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final Color color = context.isDarkMode
        ? AppColors.dark3
        : AppColors.greyscale[200] as Color;

    return ColoredBox(
      color: color,
      child: const SizedBox(
        height: 1,
        width: double.infinity,
      ),
    );
  }
}
