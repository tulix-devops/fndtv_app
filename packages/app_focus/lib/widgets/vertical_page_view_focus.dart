import 'package:app_focus/app_focus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VerticalPageViewFocus extends StatefulWidget {
  VerticalPageViewFocus({
    super.key,
    required this.builder,
    this.pageCount,
    this.controller,
    required this.onFocusChange,
  }) {
    assert(pageCount != null || controller != null);
  }

  final int? pageCount;
  final VerticalPageViewController? controller;
  final Widget Function(
      BuildContext context, VerticalPageViewController controller) builder;
  final void Function(bool value, VerticalPageViewController controller)
      onFocusChange;

  @override
  State<VerticalPageViewFocus> createState() => _VerticalPageViewFocusState();
}

class _VerticalPageViewFocusState extends State<VerticalPageViewFocus> {
  late final VerticalPageViewController _controller = widget.controller ??
      VerticalPageViewController(
        pageCount: widget.pageCount!,
      );

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _controller.primaryFocusNode,
      onFocusChange: (value) {
        widget.onFocusChange(value, _controller);
      },
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }

        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _controller.previousPage(context);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _controller.nextPage(context);
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: widget.builder(context, _controller),
    );
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }
}
