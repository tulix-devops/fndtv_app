import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    super.key,
    required this.child,
    required this.loader,
    required this.status,
  });

  final Status status;
  final Widget child;
  final Widget loader;

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: loader,
      secondChild: status == Status.success ? child : const SizedBox.shrink(),
      duration: const Duration(milliseconds: 750),
      reverseDuration: Durations.long2,
      crossFadeState: status == Status.loading
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      firstCurve: Curves.easeInOut,
      sizeCurve: Curves.easeInOut,
    );
  }
}
