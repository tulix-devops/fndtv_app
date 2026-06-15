// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FocusWrapper extends StatefulWidget {
  final int focusNodeCount;
  final Widget Function(BuildContext context, List<FocusNode> focusNodes) build;
  final FocusNode focusNode;
  final Map<LogicalKeyboardKey?, Function(BuildContext, List<FocusNode>)?>
      focusActionMap;
  final int? focusOnWidget;
  final void Function(List<FocusNode>)? onFocus;
  final bool autoFocus;

  const FocusWrapper(
      {super.key,
      required this.focusNodeCount,
      required this.build,
      required this.focusNode,
      required this.focusActionMap,
      this.focusOnWidget,
      this.onFocus,
      this.autoFocus = true});

  @override
  State<FocusWrapper> createState() => _FocusWrapperState();
}

class _FocusWrapperState extends State<FocusWrapper> {
  List<FocusNode> _focusNodes = [];
  @override
  void initState() {
    super.initState();

    _focusNodes = List.generate(widget.focusNodeCount, (_) => FocusNode());

    if (widget.focusOnWidget != null && mounted) {
      if (widget.focusOnWidget! < _focusNodes.length &&
          _focusNodes[widget.focusOnWidget!].canRequestFocus) {
        _focusNodes[widget.focusOnWidget!].requestFocus();
      }
    }
  }

  // @override
  // void didUpdateWidget(covariant FocusWrapper oldWidget) {
  //   if (widget.focusNodeCount != oldWidget.focusNodeCount) {
  //     _focusNodes = List.generate(widget.focusNodeCount, (_) => FocusNode());
  //   }
  //   super.didUpdateWidget(oldWidget);
  // }
  //   void _initializeFocusNodes() {
  //   _focusNodes = List.generate(widget.focusNodeCount, (_) => FocusNode());
  // }

  // void _disposeFocusNodes() {
  //   for (FocusNode node in _focusNodes) {
  //     if (node.hasListeners) {
  //       node.dispose();
  //     }
  //   }
  //   _focusNodes.clear();
  // }

  @override
  void dispose() {
    for (FocusNode node in _focusNodes) {
      if (node.hasListeners) {
        node.dispose();
      }
    }

    if (widget.focusNode.hasListeners) {
      widget.focusNode.dispose();
    }

    super.dispose();
  }

  void _handleFocusChange() {
    if (widget.focusNode.hasFocus &&
        mounted &&
        _focusNodes.isNotEmpty &&
        _focusNodes[0].canRequestFocus) {
      _focusNodes[0].requestFocus();
    }
  }

  _focusOnChild(bool focused) {
    if (widget.onFocus != null) {
      widget.onFocus!(_focusNodes);
    }
    if (focused && widget.focusOnWidget != null) {
      if (widget.onFocus != null) {
        widget.onFocus!(_focusNodes);
      }
      _focusNodes[widget.focusOnWidget!].requestFocus();
      return;
    }
    if (focused && widget.focusOnWidget == null) {
      _handleFocusChange();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) {
        if (widget.autoFocus) {
          _focusOnChild(focused);
          return;
        }
        if (widget.onFocus != null) {
          widget.onFocus!(_focusNodes);
          return;
        }
      },
      focusNode: widget.focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final action = widget.focusActionMap[event.logicalKey];
          if (action != null) {
            action(context, _focusNodes);
            return KeyEventResult.handled;
          }
        }

        return KeyEventResult.ignored;
      },
      child: widget.build(context, _focusNodes),
    );
  }
}
