import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class PockoAppBar extends StatelessWidget {
  const PockoAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
        key: key,
        forceMaterialTransparency: true,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: Focus(
            focusNode: FocusNode(),
            child: Image.asset(
              Assets.pockoMiniLogo,
              height: 40,
              width: 60,
            ),
          ),
        ));
  }
}
