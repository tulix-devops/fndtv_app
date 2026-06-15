import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class ActiveInputBorder extends StatelessWidget {
  const ActiveInputBorder({
    super.key,
    required this.child,
    required this.isActive,
  });

  final Widget child;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? context.uiColors.primary : Colors.transparent,
          width: 3,
        ),
      ),
      child: child,
    );
  }
}
