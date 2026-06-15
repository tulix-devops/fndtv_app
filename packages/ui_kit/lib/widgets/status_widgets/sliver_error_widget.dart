import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// Use this when the builder is in CustomScrollView and widget is not centered
class SliverErrorWidget extends StatelessWidget {
  const SliverErrorWidget({
    super.key,
    this.error,
  });

  final String? error;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: Center(
        child: Text(
          error ?? 'Failed to load data. Please try again.',
          style: TextStyles.h4.primary(context),
        ),
      ),
    );
  }
}
