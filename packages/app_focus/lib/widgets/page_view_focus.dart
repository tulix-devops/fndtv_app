import 'package:app_focus/app_focus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PageViewFocus extends StatefulWidget {
  const PageViewFocus(
      {super.key,
      required this.builder,
      required this.pageCount,
      required this.focusNode,
      required this.onEnterPressed,
      required this.onFocusChange,
      this.onPageChanged,
      this.height,
      this.viewPortFraction,
      this.infinityCarousel = true});

  /// builder
  /// itemIndex (index of the page view item)
  /// currentIndex (index of the current active pageController item)
  /// controller (PageViewController)
  final Widget Function(BuildContext context, PageViewController controller,
      int itemIndex, int currentIndex) builder;
  final int pageCount;
  // primaryFocusNode
  final FocusNode focusNode;

  /// default height is 250
  final double? height;

  final bool infinityCarousel;

  /// Enter key pressed
  final void Function(int activeIndex, PageViewController controller)
      onEnterPressed;

  /// PageController changed
  final void Function(int activeIndex)? onPageChanged;

  /// Primary Focus state  changed
  final void Function(bool value, PageViewController controller) onFocusChange;

  /// viewPortFraction
  /// Default is 0.22
  final double? viewPortFraction;

  @override
  State<PageViewFocus> createState() => _PageViewFocusState();
}

class _PageViewFocusState extends State<PageViewFocus> {
  late PageViewController _controller;
  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(covariant PageViewFocus oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.pageCount != oldWidget.pageCount) {
      _initializeController();
    }
  }

  void _initializeController() {
    _controller = PageViewController(
      pageCount: widget.pageCount,
      viewPortFraction: widget.viewPortFraction,
      infinityCarousel: widget.infinityCarousel,
      onPageChanged: widget.onPageChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (value) {
        widget.onFocusChange(value, _controller);
      },
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }

        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _controller.nextPage(context);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _controller.previousPage(context);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.select) {
          widget.onEnterPressed(_controller.currentPageIndex, _controller);

          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: SizedBox(
        height: _getHeight(),
        child: PageView.builder(
          controller: _controller.pageController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          scrollBehavior: const ScrollBehavior().copyWith(
            overscroll: false,
          ),
          padEnds: false,
          itemCount: _controller.itemCount,
          itemBuilder: (context, itemIndex) {
            return ValueListenableBuilder(
              valueListenable: _controller.index,
              builder: (context, _, __) {
                return widget.builder(
                  context,
                  _controller,
                  itemIndex,
                  _controller.currentPageIndex,
                );
              },
            );
          },
        ),
      ),
    );
  }

  double _getHeight() {
    return widget.height ?? 250;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
