import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

import 'draggable_controller.dart';

class FlexibleBottomSheetController {
  Function()? _close;
  void close() {
    if (_close != null) {
      _close!();
    }
  }
}

class FlexibleBottomSheet extends StatefulWidget {
  const FlexibleBottomSheet({
    super.key,
    required this.onClose,
    required this.child,
    this.overlayWidget,
    this.curve = Curves.fastOutSlowIn,
    this.heightFactor = 0.8,
    this.padding = const EdgeInsets.only(
      left: 0,
      right: 0,
    ),
    this.bottomSheetController,
  });

  final VoidCallback onClose;
  final Widget child;
  final Curve curve;
  final FlexibleBottomSheetController? bottomSheetController;
  final double heightFactor;
  final EdgeInsets padding;
  final Widget? overlayWidget;
  static Future<void> show({
    required BuildContext context,
    required VoidCallback onClose,
    required Widget child,
    overlayWidget,
    Curve curve = Curves.fastOutSlowIn,
    double heightFactor = 0.8,
    FlexibleBottomSheetController? bottomSheetController,
    padding = const EdgeInsets.only(left: 10, right: 10, top: 20),
  }) {
    return Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      pageBuilder: (BuildContext context, _, __) => FlexibleBottomSheet(
        onClose: onClose,
        curve: curve,
        heightFactor: heightFactor,
        padding: padding,
        overlayWidget: overlayWidget,
        bottomSheetController: bottomSheetController,
        child: child,
      ),
    ));
  }

  @override
  State<FlexibleBottomSheet> createState() => _FlexibleBottomSheetState();
}

class _FlexibleBottomSheetState extends State<FlexibleBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;
  final DraggableController _draggableController = DraggableController();
  final GlobalKey _childKey = GlobalKey();
  double? _childHeight;

  @override
  void initState() {
    super.initState();
    if (widget.bottomSheetController != null) {
      widget.bottomSheetController?._close = _closeSheet;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_childKey.currentContext != null) {
        setState(() {
          _childHeight = _childKey.currentContext!.size!.height;
        });
      }
    });

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();

    _draggableController.controller = _controller;

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);

    _controller.addListener(() {
      if (_controller.status == AnimationStatus.dismissed) {
        widget.onClose();
        Navigator.of(context).pop();
      }
    });
  }

  void _closeSheet() {
    _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double maxHeight = screenHeight * widget.heightFactor;
    final uiColors = context.uiColors;

    Widget contentWidget = _childHeight == null
        ? ConstrainedBox(
            constraints:
                BoxConstraints(minWidth: MediaQuery.of(context).size.width),
            child: Container(
                padding: widget.padding, key: _childKey, child: widget.child),
          )
        : ConstrainedBox(
            constraints:
                BoxConstraints(minWidth: MediaQuery.of(context).size.width),
            child: Container(
              padding: widget.padding,
              height: (_childHeight! > maxHeight) ? maxHeight : _childHeight,
              decoration: BoxDecoration(
                color: uiColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
              child: SingleChildScrollView(child: widget.child),
            ),
          );
    return Stack(
      children: [
        FadeTransition(
          opacity: _opacityAnimation,
          child: GestureDetector(
            onTap: () {
              if (_controller.status == AnimationStatus.completed) {
                _controller.reverse();
              }
            },
            child: Container(
              color: uiColors.surface.withOpacity(0.8),
            ),
          ),
        ),
        SlideTransition(
          position: _offsetAnimation,
          child: GestureDetector(
            onVerticalDragStart: _draggableController.onDragStart,
            onVerticalDragUpdate: (details) =>
                _draggableController.onDragUpdate(details,
                    MediaQuery.of(context).size.height * widget.heightFactor),
            onVerticalDragEnd: (details) =>
                _draggableController.onDragEnd(details, velocityThreshold: 500),
            child: widget.overlayWidget != null
                ? Stack(
                    children: [
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Material(
                          type: MaterialType.transparency,
                          child: contentWidget,
                        ),
                      ),
                      widget.overlayWidget!,
                    ],
                  )
                : Align(
                    alignment: Alignment.bottomCenter,
                    child: Material(
                      type: MaterialType.transparency,
                      child: contentWidget,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
