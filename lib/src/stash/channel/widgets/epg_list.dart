import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class EpgHeader extends StatelessWidget {
  const EpgHeader({
    super.key,
    required this.onPressed,
    required this.label,
  });

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Row(
        children: [
          const Text('Stream Programs', style: TextStyles.h5),
          const Spacer(),
          AppTextButton(
            onPressed: onPressed,
            label: label,
            style: TextStyles.bodyMediumSemiBold.primary(context),
          )
        ],
      ),
    );
  }
}
