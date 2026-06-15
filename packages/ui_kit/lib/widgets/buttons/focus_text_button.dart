import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class FocusTextButton extends StatefulWidget {
  final FocusNode focusNode;
  final void Function(BuildContext) onPressed;
  final String? icon;
  final ({Color defaultColor, Color focusedColor}) backgroundColor;
  final String? label;
  final bool useDefaultButtonStyle;
  final ({Color defaultColor, Color focusedColor})? labelColor;
  final ({Color defaultColor, Color focusedColor})? iconColor;
  final ({double height, double width}) iconSize;
  final LinearGradient? linearGradient;

  const FocusTextButton({
    super.key,
    required this.onPressed,
    this.icon,
    required this.focusNode,
    this.backgroundColor = (
      defaultColor: Colors.transparent,
      focusedColor: Colors.transparent
    ),
    this.label,
    this.useDefaultButtonStyle = false,
    this.labelColor,
    this.iconColor,
    this.iconSize = (height: 28, width: 28),
    this.linearGradient,
  });

  @override
  State<FocusTextButton> createState() => _FocusTextButtonState();
}

class _FocusTextButtonState extends State<FocusTextButton> {
  _focusListener() {
    setState(() {});
  }

  @override
  void initState() {
    widget.focusNode.addListener(_focusListener);
    super.initState();
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_focusListener);
    super.dispose();
  }

  Color getColor(({Color defaultColor, Color focusedColor})? color) {
    if (color == null) {
      return widget.focusNode.hasFocus
          ? context.uiColors.primary
          : Colors.white;
    }
    return widget.focusNode.hasFocus ? color.focusedColor : color.defaultColor;
  }

  LinearGradient? getLinearGradient() {
    return widget.focusNode.hasFocus ? widget.linearGradient : null;
  }

  Color getBackgroundColor() {
    if (widget.focusNode.hasFocus) {
      return widget.backgroundColor.focusedColor;
    }
    return widget.backgroundColor.defaultColor;
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      focusNode: widget.focusNode,
      style: widget.useDefaultButtonStyle
          ? TextButton.styleFrom(
              backgroundColor: getBackgroundColor(),
            )
          : TextButton.styleFrom(
              backgroundColor: getBackgroundColor(),
              padding: const EdgeInsets.all(5),
              shape: const CircleBorder(),
            ),
      onPressed: () => widget.onPressed(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null)
            AppIcon(
              widget.icon!,
              height: widget.iconSize.height,
              width: widget.iconSize.width,
              gradient: getLinearGradient(),
              color: getColor(widget.iconColor),
            ),
          if (widget.label != null)
            Padding(
              padding: EdgeInsets.only(left: widget.icon != null ? 8.0 : 0.0),
              child: AppText(
                text: widget.label!,
                gradient: getLinearGradient(),
                style: TextStyle(
                  color: getColor(widget.labelColor),
                ),
              ),
            )
        ],
      ),
    );
  }
}
