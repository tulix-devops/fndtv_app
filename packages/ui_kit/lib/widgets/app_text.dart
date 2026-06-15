import 'package:flutter/material.dart';
import 'package:ui_kit/theme/text_styles.dart';
import 'package:ui_kit/ui_kit.dart';

class AppText extends StatelessWidget {
  const AppText({super.key, this.gradient, required this.text, this.style});
  final LinearGradient? gradient;
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    Widget child = Text(text, style: style);
    return gradient != null
        ? GradientWrapper(gradient: gradient!, child: child)
        : child;
  }
}
