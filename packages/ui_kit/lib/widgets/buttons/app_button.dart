import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class AppButton extends StatefulWidget {
  final void Function() onPressed;
  final String label;
  final ({String asset, double? size})? prefixIcon;
  final ({String asset, double? size})? suffixIcon;
  final ButtonType type;
  final Color? textColor;
  final bool isDisabled;
  final FocusNode? focusNode;
  final LinearGradient? gradient;

  const AppButton.primary({
    super.key,
    this.isDisabled = false,
    this.prefixIcon,
    this.suffixIcon,
    this.textColor,
    required this.label,
    required this.onPressed,
    this.focusNode,
    this.gradient,
  }) : type = ButtonType.primary;

  const AppButton.primaryRounded({
    super.key,
    this.isDisabled = false,
    this.prefixIcon,
    this.suffixIcon,
    this.textColor,
    required this.label,
    required this.onPressed,
    this.focusNode,
    this.gradient,
  }) : type = ButtonType.primaryRounded;

  const AppButton.secondary({
    super.key,
    this.isDisabled = false,
    this.prefixIcon,
    this.suffixIcon,
    this.textColor,
    required this.label,
    required this.onPressed,
    this.focusNode,
    this.gradient,
  }) : type = ButtonType.secondary;

  const AppButton.secondaryRounded({
    super.key,
    this.isDisabled = false,
    this.prefixIcon,
    this.suffixIcon,
    this.textColor,
    required this.label,
    required this.onPressed,
    this.focusNode,
    this.gradient,
  }) : type = ButtonType.secondaryRounded;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  late AppButtonStyle _buttonStyle;
  late FocusNode focusNode = widget.focusNode ?? FocusNode();
  BorderRadius _extractBorderRadius(OutlinedBorder shape) {
    if (shape is RoundedRectangleBorder) {
      return shape.borderRadius as BorderRadius;
    } else if (shape is CircleBorder) {
      return BorderRadius.circular(100.0);
    } else {
      return BorderRadius.zero;
    }
  }

  @override
  void initState() {
    super.initState();
    focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    super.dispose();
  }

  late ({String asset, double size})? prefixIcon = widget.prefixIcon != null
      ? (
          asset: widget.prefixIcon!.asset,
          size: widget.prefixIcon?.size ?? 20,
        )
      : null;

  late ({String asset, double size})? suffixIcon = widget.suffixIcon != null
      ? (
          asset: widget.suffixIcon!.asset,
          size: widget.suffixIcon?.size ?? 20,
        )
      : null;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        focusNode.hasFocus ? context.uiColors.onSecondary : Colors.transparent;
    _buttonStyle = context.buttonStyle(widget.type);
    BorderRadius borderRadius = _extractBorderRadius(_buttonStyle.shape);
    final decoration = widget.gradient != null
        ? BoxDecoration(
            gradient: context.uiColors.primaryGradient,
            borderRadius: borderRadius,
          )
        : null;

    return Container(
      decoration: decoration,
      child: ElevatedButton(
        focusNode: focusNode,
        onPressed: onPressed,
        style: context.elevatedButtonStyle(_buttonStyle).copyWith(
              overlayColor: context.foreGround,
              backgroundColor: widget.gradient != null
                  ? WidgetStateProperty.all(Colors.transparent)
                  : WidgetStateProperty.all(_buttonStyle.color),
              shape: WidgetStateProperty.all(
                _buttonStyle.shape.copyWith(
                  side: BorderSide(color: borderColor, width: 4),
                ),
              ),
            ),
        child: DefaultButtonContent(
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          iconColor: _buttonStyle.iconColor,
          contentMargin: _buttonStyle.contentMargin,
          text: Text(
            widget.label,
            style: _buttonStyle.textStyle?.copyWith(
              color: widget.textColor ?? _buttonStyle.textStyle!.color,
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  VoidCallback? get onPressed {
    return !widget.isDisabled ? widget.onPressed : null;
  }
}
