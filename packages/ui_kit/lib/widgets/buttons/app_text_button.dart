import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class AppTextButton extends StatefulWidget {
  final void Function()? onPressed;
  final String? label;
  final TextStyle? style;
  final ({String asset, double size})? icon;
  final Color? childColor;
  final ButtonType type;
  final bool isDisabled;
  final FocusNode? focusNode;

  const AppTextButton(
      {super.key,
      this.isDisabled = false,
      this.icon,
      this.label,
      this.childColor,
      this.style,
      required this.onPressed,
      this.focusNode})
      : type = ButtonType.text,
        assert(
          label != null || icon != null,
          'You must provide a label or an icon for the AppTextButton',
        );

  const AppTextButton.rounded(
      {super.key,
      this.isDisabled = false,
      this.icon,
      this.label,
      this.childColor,
      this.style,
      required this.onPressed,
      this.focusNode})
      : type = ButtonType.textRounded,
        assert(
          label != null || icon != null,
          'You must provide a label or an icon for the AppTextButton',
        );

  @override
  State<AppTextButton> createState() => _AppTextButtonState();
}

class _AppTextButtonState extends State<AppTextButton> {
  late AppButtonStyle _buttonStyle;

  @override
  Widget build(BuildContext context) {
    _buttonStyle = context.buttonStyle(widget.type);

    return TextButton(
      focusNode: widget.focusNode,
      onPressed: onPressed,
      style: context
          .textButtonStyle(_buttonStyle)
          .copyWith(overlayColor: context.foreGround),
      child: widget.label != null
          ? Text(
              widget.label!,
              style: widget.style ??
                  _buttonStyle.textStyle?.copyWith(
                    color: widget.childColor,
                  ),
              maxLines: 1,
              textAlign: TextAlign.center,
            )
          : AppIcon(
              widget.icon!.asset,
              height: widget.icon!.size,
              width: widget.icon!.size,
              color: widget.childColor ?? _buttonStyle.iconColor,
            ),
    );
  }

  VoidCallback? get onPressed {
    return !widget.isDisabled ? widget.onPressed : null;
  }
}
