import 'package:flutter/material.dart';
import 'package:ui_kit/theme/app_colors.dart';
import 'package:ui_kit/ui_kit.dart';

class UiStaticBackground extends StatelessWidget {
  const UiStaticBackground({
    super.key,
    required this.image,
    required this.child,
    this.isImageNetwork = true,
  });

  final String? image;
  final Widget child;
  final bool isImageNetwork;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: UiShaderMask(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [
              Color(0xffF7C6D7),
              Color.fromARGB(143, 0, 0, 0),
              Color(0xffF7C6D7),
            ],
            child: UiShaderMask(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: const [
                Color(0xffF7C6D7),
                Colors.transparent,
                Color(0xffF7C6D7)
              ],
              child: UiImageContainer(
                image: image,
                isImageNetwork: isImageNetwork,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xffF7C6D7).withOpacity(1.0),
                  Colors.transparent,
                  Color(0xffF7C6D7).withOpacity(1.0),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
