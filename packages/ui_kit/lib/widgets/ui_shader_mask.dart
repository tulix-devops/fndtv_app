import 'package:flutter/material.dart';

/// [UiShaderMask]
/// Image Gradient Filter
class UiShaderMask extends StatelessWidget {
  const UiShaderMask({
    super.key,
    required this.begin,
    required this.end,
    required this.colors,
    required this.child,
  });
  final Alignment begin;
  final Alignment end;
  final List<Color> colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: begin,
          end: end,
          colors: colors,
          tileMode: TileMode.mirror,
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcATop,
      child: child,
    );
  }
}
