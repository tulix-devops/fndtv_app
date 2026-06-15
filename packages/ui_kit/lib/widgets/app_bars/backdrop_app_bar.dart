import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class BackdropAppBar extends StatelessWidget {
  const BackdropAppBar({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      forceMaterialTransparency: true,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Image.asset(
            Assets.logo,
            height: 40,
            width: 60,
          ),
          const Spacer(),
          Hero(
            tag: 'search',
            child: IconButton(
              icon: const Icon(Icons.search),
              onPressed: onPressed,
            ),
          ),
        ],
      ),
    );
  }
}
