import 'package:flutter/material.dart';

mixin FocusMixin {
  /// [previousFocusNode] is the focus node for the ArrowDown button
  FocusNode? previousFocusNode;

  /// [nextFocusNode] is the focus node for the ArrowUp button
  FocusNode? nextFocusNode;

  void focusDown(BuildContext context) {
    if (nextFocusNode != null) {
      nextFocusNode!.requestFocus();

      Scrollable.ensureVisible(
        nextFocusNode!.context!,
        alignment: 1,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        duration: Durations.long2,
        curve: Curves.easeInOut,
      );
      return;
    }
    FocusScope.of(context).focusInDirection(TraversalDirection.down);
  }

  void focusUp(BuildContext context) {
    if (previousFocusNode != null) {
      previousFocusNode!.requestFocus();

      Scrollable.ensureVisible(
        previousFocusNode!.context!,
        alignment: 0,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
        duration: Durations.long2,
        curve: Curves.easeInOut,
      );

      return;
    }

    FocusScope.of(context).focusInDirection(TraversalDirection.up);
  }
}
