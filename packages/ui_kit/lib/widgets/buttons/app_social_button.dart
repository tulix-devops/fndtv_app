import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class AppSocialButton extends StatefulWidget {
  final void Function() onPressed;
  final String label;
  final ({String asset, double size}) prefixIcon;
  final ButtonType type;
  final bool isDisabled;

  const AppSocialButton({
    super.key,
    this.isDisabled = false,
    required this.prefixIcon,
    required this.label,
    required this.onPressed,
  }) : type = ButtonType.social;

  @override
  State<AppSocialButton> createState() => _AppSocialButtonState();
}

class _AppSocialButtonState extends State<AppSocialButton> {
  late AppButtonStyle _buttonStyle;

  @override
  Widget build(BuildContext context) {
    _buttonStyle = context.buttonStyle(widget.type);

    return ElevatedButton(
      onPressed: onPressed,
      style: context.elevatedButtonStyle(_buttonStyle),
      child: _DefaultButtonContent(
        prefixIcon: widget.prefixIcon,
        iconColor: _buttonStyle.iconColor,
        contentMargin: _buttonStyle.contentMargin,
        text: Text(
          widget.label,
          style: _buttonStyle.textStyle,
          maxLines: 1,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  VoidCallback? get onPressed {
    return !widget.isDisabled ? widget.onPressed : null;
  }
}

class _DefaultButtonContent extends StatelessWidget {
  final ({String asset, double size}) prefixIcon;
  final Color iconColor;

  final double contentMargin;

  final Text text;

  const _DefaultButtonContent({
    required this.prefixIcon,
    required this.contentMargin,
    required this.text,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: contentMargin,
      children: [
        _Icon(
          prefixIcon.asset,
          color: iconColor,
        ),
        text,
      ],
    );
  }
}

class _Icon extends StatelessWidget {
  const _Icon(
    this.icon, {
    required this.color,
  });

  final Color color;
  final String icon;
  @override
  Widget build(BuildContext context) {
    return AppIcon(
      icon,
      height: 20,
      width: 20,
      color: color,
    );
  }
}
