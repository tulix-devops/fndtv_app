import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// Full screen Image background
class UiImageBackground extends StatelessWidget {
  const UiImageBackground({
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
      alignment: Alignment.topRight,
      children: [
        UiShaderMask(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const <Color>[
            Color(0xffF7C6D7),
            Color.fromARGB(0, 0, 0, 0),
            Colors.transparent
          ],
          child: UiShaderMask(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const <Color>[
              Colors.transparent,
              Color.fromARGB(0, 0, 0, 0),
              Color(0xffF7C6D7)
            ],
            child: UiImageContainer(
              image: image,
              isImageNetwork: isImageNetwork,
            ),
          ),
        ),
        child
      ],
    );
  }
}
