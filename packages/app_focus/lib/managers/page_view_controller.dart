import 'package:flutter/material.dart';

class PageViewController {
  /// Horizontal PageView Controller with a
  /// viewportFraction of 0.22 So we can see all list items
  late final PageController pageController = PageController(
    viewportFraction: viewPortFraction ?? 0.22,
  );

  /// [viewPortFraction] is the fraction of the viewport that each page should occupy
  /// Default is 0.22
  final double? viewPortFraction;

  final bool? infinityCarousel;

  final ValueChanged<int>? onPageChanged;

  /// [index] is the current active page index
  ValueNotifier<int> index = ValueNotifier<int>(0);

  /// [pageCount] is the total number of pages in the PageView
  int pageCount = 0;
  late BuildContext context;

  /// [PageViewController] is a class that manages the UI FocusNode and scrollControllers
  PageViewController({
    required this.pageCount,
    this.viewPortFraction,
    this.infinityCarousel,
    this.onPageChanged,
  });

  /// [dispose] should be called when the widget is removed from the tree
  void dispose() {
    pageController.dispose();
    index.dispose();
  }

  /// [onFocusReceived] is called when the primary focus is received
  void onFocusReceived() {
    index.value = 0;

    _resetScrollOffset();
  }

  /// [nextPage] is called when the ArrowRight button is pressed
  void nextPage(BuildContext context) {
    this.context = context;

    index.value = isLastPage ? 0 : index.value + 1;

    _animateToIndex(index.value);
  }

  /// [previousPage] is called when the ArrowLeft button is pressed
  void previousPage(BuildContext context) {
    this.context = context;

    if (isFirstPage) {
      return _focusOnNavigationRail();
    }

    index.value--;

    _animateToIndex(index.value);
  }

  /// [_animateToIndex] is a helper function to animate to a specific index
  void _animateToIndex(int index) {
    pageController.animateToPage(
      index,
      duration: Durations.long2,
      curve: Curves.easeInOut,
    );

    if (onPageChanged != null) {
      onPageChanged!(index);
    }
  }

  /// [_resetScrollOffset] is a helper function to reset the scroll offset
  /// Used when receiving or removing primary focus
  void _resetScrollOffset() {
    pageController.animateTo(
      0,
      duration: Durations.long2,
      curve: Curves.easeInOut,
    );
  }

  /// [_focusOnNavigationRail] is a helper function to focus on the navigation rail
  void _focusOnNavigationRail() {
    FocusScope.of(context).focusInDirection(TraversalDirection.left);
  }

  /// [currentPageIndex] is the current active page index
  int get currentPageIndex {
    return isInfinityCarousel ? index.value % pageCount : index.value;
  }

  /// For the infinite carousel, we need to get the correct index
  /// when rendering the item
  int getItemIndex(int index) {
    return isInfinityCarousel ? index % pageCount : index;
  }

  bool get isInfinityCarousel {
    if (infinityCarousel != null) return infinityCarousel!;
    return pageCount < 4;
  }

  int? get itemCount {
    return isInfinityCarousel ? null : pageCount;
  }

  bool get isLastPage {
    if (isInfinityCarousel) {
      return false;
    }

    return index.value == pageCount - 1;
  }

  bool get isFirstPage {
    if (isInfinityCarousel) {
      return index.value % pageCount == 0;
    }

    return index.value == 0;
  }
}
