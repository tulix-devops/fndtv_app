import 'package:flutter/material.dart';
import 'dart:math' as math show sin, pi;

import 'package:ui_kit/ui_kit.dart';

class AppLoadingIndicator extends StatefulWidget {
  const AppLoadingIndicator({
    super.key,
    required this.size,
  });

  final double size;

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with SingleTickerProviderStateMixin {
  static const int _itemCount = 8;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.fromSize(
        size: Size.square(widget.size),
        child: Stack(
          children: List.generate(_itemCount, (index) {
            final double position = widget.size * .5;
            return Positioned.fill(
              left: position,
              top: position,
              child: Transform(
                transform:
                    Matrix4.rotationZ(360.0 / _itemCount * index * 0.0174533),
                child: Align(
                  alignment: Alignment.center,
                  child: ScaleTransition(
                    scale: _DelayTween(
                      begin: 0.0,
                      end: 1.0,
                      delay: index / _itemCount,
                    ).animate(_controller),
                    child: SizedBox.fromSize(
                      size: Size.square(widget.size * 0.2),
                      child: _Builder(
                          widget: widget, context: context, index: index),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _Builder extends StatelessWidget {
  const _Builder({
    required this.widget,
    required this.context,
    required this.index,
  });

  final AppLoadingIndicator widget;
  final BuildContext context;
  final int index;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: context.uiColors.primary,
          shape: BoxShape.circle,
        ),
      );
}

class _DelayTween extends Tween<double> {
  _DelayTween({
    double? begin,
    double? end,
    required this.delay,
  }) : super(begin: begin, end: end);

  final double delay;

  @override
  double lerp(double t) {
    return super.lerp((math.sin((t - delay) * 2 * math.pi) + 1) / 2);
  }

  @override
  double evaluate(Animation<double> animation) => lerp(animation.value);
}
