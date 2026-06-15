import 'package:flutter/material.dart';

class AppFocusGroup extends StatelessWidget {
  const AppFocusGroup({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(
        requestFocusCallback: (
          FocusNode node, {
          ScrollPositionAlignmentPolicy? alignmentPolicy,
          double? alignment,
          Duration? duration,
          Curve? curve,
        }) {
          node.requestFocus();
          Scrollable.ensureVisible(
            node.context!,
            alignment: alignment ?? 1,
            alignmentPolicy:
                alignmentPolicy ?? ScrollPositionAlignmentPolicy.explicit,
            duration: Durations.long2,
            curve: Curves.easeInOut,
          );
        },
      ),
      child: child,
    );
  }
}
