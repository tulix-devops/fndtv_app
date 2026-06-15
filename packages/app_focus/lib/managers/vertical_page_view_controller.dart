import 'package:app_focus/app_focus.dart';
import 'package:flutter/material.dart';

class VerticalPageViewController with FocusMixin {
  /// [primaryFocusNode] Used for traversal arrowUp and arrowDown
  final FocusNode primaryFocusNode;

  /// [controller] 0.8 viewportFraction so we can see the next or previous page
  late final PageController pageController = PageController(
    viewportFraction: 0.8,
  );

  /// [index] is the current active page index
  ValueNotifier<int> index = ValueNotifier<int>(0);

  /// [pageCount] is the total number of pages in the PageView
  int pageCount = 0;

  /// [focusNodes] used for each item in the list
  late final List<FocusNode> focusNodes;
  late BuildContext context;

  /// [VerticalPageViewController] is a class that manages the Primary focus node and the PageView
  /// [previousFocusNode] is the focus node for the ArrowDown button
  /// [nextFocusNode] is the focus node for the ArrowUp button
  /// [primaryFocusNode] is passed as param if we need to pass the focus node to other [FocusManager]
  VerticalPageViewController({
    required this.pageCount,
    FocusNode? previousFocusNode,
    FocusNode? nextFocusNode,
    FocusNode? primaryFocusNode,
  }) : primaryFocusNode = primaryFocusNode ?? FocusNode() {
    this.previousFocusNode = previousFocusNode;
    this.nextFocusNode = nextFocusNode;

    focusNodes = List.generate(
      pageCount,
      (index) => FocusNode(
        skipTraversal: true,
        debugLabel: '$index-VerticalPageViewFocusNode',
      ),
    );
  }

  /// [dispose] should be called when the widget is removed from the tree
  void dispose() {
    pageController.dispose();
    index.dispose();
  }

  /// [onFocusReceived] is called when the primary focus is received
  void onFocusReceived() {
    if (index.value < 0 || index.value >= focusNodes.length) return;
    _updateFocus();
  }

  /// [_updateFocus] is a helper function to update the focus node
  void _updateFocus() {
    focusNodes[index.value].requestFocus();
  }

  /// [nextPage] is called when the ArrowRight button is pressed
  void nextPage(BuildContext context) {
    this.context = context;

    /// If we are on the last page (end of pageView), reset pageview and focus on the first focus node

    if (isLastPage) {
      index.value = 0;
      _updateFocus();
      _resetScrollOffset();
      _focusDown();
      return;
    }

    index.value = index.value + 1;
    _animateToIndex(index.value);
    _updateFocus();
  }

  /// [previousPage] is called when the ArrowLeft button is pressed
  void previousPage(BuildContext context) {
    this.context = context;

    /// If we are on the first page (start of pageView), focus on the previous focus node
    if (isFirstPage) {
      return _focusUp();
    }

    index.value--;

    _animateToIndex(index.value);
    _updateFocus();
  }

  /// [_animateToIndex] is a helper function to animate to a specific index
  void _animateToIndex(int index) {
    pageController.animateToPage(
      index,
      duration: Durations.long2,
      curve: Curves.easeInOut,
    );
  }

  /// [_resetScrollOffset] is a helper function to reset the scroll offset
  void _resetScrollOffset() {
    pageController.animateTo(
      0,
      duration: Durations.long2,
      curve: Curves.easeInOut,
    );
  }

  /// [_focusUp] is a helper function to focus on the previous focus node
  void _focusUp() {
    focusUp(context);
  }

  /// [_focusDown] is a helper function to focus on the next focus node
  // ignore: unused_element
  void _focusDown() {
    focusDown(context);
  }

  bool get isLastPage {
    return index.value == pageCount - 1;
  }

  bool get isFirstPage {
    return index.value == 0;
  }
}
