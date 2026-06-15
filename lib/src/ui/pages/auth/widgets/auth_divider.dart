import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class AuthDivider extends StatelessWidget {
  const AuthDivider({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: AppDivider()),
        Margins.horizontal16,
        Text(
          label,
          style: TextStyles.bodyXLargeSemiBold.copyWith(
            color: context.isDarkMode ? Colors.white : AppColors.greyscale[700],
          ),
        ),
        Margins.horizontal16,
        const Expanded(child: AppDivider()),
      ],
    );
  }
}
