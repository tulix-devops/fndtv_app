import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// Use this when the builder is in CustomScrollView and widget is not centered
class SliverLoadingWidget extends StatelessWidget {
  const SliverLoadingWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const SliverFillRemaining(
      child: Center(
        child: AppLoadingIndicator(size: 50),
      ),
    );
  }
}
