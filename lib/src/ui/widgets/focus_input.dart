import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ui_kit/ui_kit.dart';

class FocusInput extends StatefulWidget {
  const FocusInput({super.key, required this.build, this.focusActionMap});

  final Widget Function(BuildContext context, List<FocusNode> focusNodes) build;
  final Map<LogicalKeyboardKey?, Function(BuildContext, List<FocusNode>)?>?
      focusActionMap;
  @override
  State<FocusInput> createState() => _FocusInputState();
}

class _FocusInputState extends State<FocusInput> with WidgetsBindingObserver {
  final FocusNode inputFocus = FocusNode();
  Color color = Colors.transparent;
  late final Map<LogicalKeyboardKey,
      dynamic Function(BuildContext, List<FocusNode>)> _focusActionMap = {
    LogicalKeyboardKey.select: (context, focusNodes) =>
        focusNodes.first.requestFocus(),
    LogicalKeyboardKey.arrowLeft: (context, focusNodes) =>
        FocusScope.of(context).focusInDirection(TraversalDirection.left),
    LogicalKeyboardKey.arrowDown: (context, focusNodes) =>
        FocusScope.of(context).focusInDirection(TraversalDirection.down),
  };

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final value = View.of(context).viewInsets.bottom;
    if (value == 0 && context.isTv) {
      inputFocus.unfocus();
      inputFocus.requestFocus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusWrapper(
      autoFocus: false,
      onFocus: (focus) {
        setState(() {
          inputFocus.hasFocus
              ? color = context.uiColors.primary
              : color = Colors.transparent;
        });
      },
      focusNodeCount: 1,
      build: (context, focusNodes) {
        return Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: context.isTv ? color : Colors.transparent,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          child: widget.build(context, focusNodes),
        );
      },
      focusNode: inputFocus,
      focusActionMap: widget.focusActionMap ?? _focusActionMap,
    );
  }
}
