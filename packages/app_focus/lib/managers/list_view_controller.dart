// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'package:flutter/material.dart';

import '../app_focus.dart';

/// [ListViewController] is a class that manages the UI FocusNode and its scrollController
///
final class ListViewController with FocusMixin {
  /// [primaryFocusNode] Used for traversal arrowUp and arrowDown
  final FocusNode primaryFocusNode;

  /// [focusNodes] used for each item in the list
  late final List<FocusNode> focusNodes;

  /// [controller] used for resetting scroll offset on primary focus change
  late final ScrollController scrollController = ScrollController();
  late BuildContext context;

  /// [itemCount] is the total number of items in the list
  final int itemCount;

  /// [activeFocusIndex] is the current active focus index
  int activeFocusIndex = 0;

  /// [previousFocusNode] is the focus node for the ArrowDown button
  /// [nextFocusNode] is the focus node for the ArrowUp button
  /// [primaryFocusNode] is passed as param if we need to pass the focus node to other [FocusManager]
  ListViewController({
    required this.itemCount,
    FocusNode? previousFocusNode,
    FocusNode? nextFocusNode,
    FocusNode? primaryFocusNode,
  }) : primaryFocusNode = primaryFocusNode ?? FocusNode() {
    this.previousFocusNode = previousFocusNode;
    this.nextFocusNode = nextFocusNode;

    _initFocusNodes();
  }

  // Initializes focusNodes depending on the item count
  void _initFocusNodes() {
    focusNodes = List.generate(
      itemCount,
      (index) => FocusNode(
        skipTraversal: true,
        debugLabel: '${index}ListViewFocusNode',
      ),
    );
  }

  /// [dispose] should be called when the widget is removed from the tree
  void dispose() {
    focusNodes.forEach((node) {
      node.dispose();
    });

    primaryFocusNode.dispose();

    scrollController.dispose();
  }

  /// Focuses on the current active node depending on
  /// [activeFocusIndex]
  void _handleFocus() {
    activeFocusNode.requestFocus();
  }

  /// [onFocusReceived] is called when the primary focus is received
  /// It resets the scroll offset and focuses on the first item
  void onFocusReceived() {
    activeFocusIndex = 0;
    _resetScrollOffset(scrollController);
    _handleFocus();
  }

  /// [previous] is called when the arrowLeft button is pressed
  void previous(BuildContext context) {
    this.context = context;
    // If the focus is on the first item, move the focus to the navigation rail
    if (hasReachedStart) {
      _focusOnNavigationRail();
      return;
    }

    _handleHorizontalClick(AxisDirection.left);
  }

  /// [next] is called when the arrowRight button is pressed
  void next(BuildContext context) {
    this.context = context;
    // If the focus is on the last item, scroll to listview or pageview initial offset
    if (hasReachedEnd) {
      _resetScrollOffset(scrollController);
    }

    _handleHorizontalClick(AxisDirection.right);
  }

  void _handleHorizontalClick(AxisDirection direction) {
    _handleIndex(direction);
    _handleFocus();
  }

  void _handleIndex(AxisDirection direction) {
    if (direction == AxisDirection.left) {
      activeFocusIndex--;
      return;
    }

    activeFocusIndex = hasReachedEnd ? 0 : activeFocusIndex + 1;
  }

  void _focusOnNavigationRail() {
    FocusScope.of(context).focusInDirection(TraversalDirection.left);
  }

  void _resetScrollOffset(ScrollController controller) {
    controller.animateTo(
      0,
      duration: Durations.long2,
      curve: Curves.easeInOut,
    );
  }

  /// HELPERS

  /// Needed when we need to move focus to the navigation rail
  bool get hasReachedStart {
    return activeFocusIndex == 0;
  }

  /// Needed when we need to loop the list
  /// only for channel focus or small list of videos
  bool get hasReachedEnd {
    return activeFocusIndex == focusNodes.length - 1;
  }

  FocusNode get activeFocusNode {
    return focusNodes[activeFocusIndex];
  }
}
