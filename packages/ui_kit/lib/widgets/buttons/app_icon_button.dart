import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class AppIconButton extends StatefulWidget {
  final VoidCallback onPressed;
  final ButtonType type;
  final bool isDisabled;
  final EdgeInsets? padding;
  final ({String asset, double size, Color? color}) icon;

  /// Apply default icon color from buttonStyle
  final bool defaultIconColor;

  const AppIconButton.primary({
    super.key,
    this.isDisabled = false,
    this.padding,
    required this.icon,
    required this.onPressed,
    this.defaultIconColor = false,
  }) : type = ButtonType.iconPrimary;

  const AppIconButton.primaryRounded({
    super.key,
    this.isDisabled = false,
    this.padding,
    required this.icon,
    required this.onPressed,
    this.defaultIconColor = false,
  }) : type = ButtonType.iconPrimaryRounded;

  const AppIconButton.secondary({
    super.key,
    this.isDisabled = false,
    this.padding,
    required this.icon,
    required this.onPressed,
    this.defaultIconColor = false,
  }) : type = ButtonType.iconSecondary;

  const AppIconButton.secondaryRounded(
      {super.key,
      this.isDisabled = false,
      this.padding,
      required this.icon,
      required this.onPressed,
      this.defaultIconColor = false})
      : type = ButtonType.iconSecondaryRounded;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  late AppButtonStyle _buttonStyle;

  @override
  Widget build(BuildContext context) {
    _buttonStyle = context.buttonStyle(widget.type);
    final ({String asset, double size, Color? color}) icon = widget.icon;

    return ElevatedButton(
        onPressed: onPressed,
        style: context.elevatedButtonStyle(_buttonStyle).copyWith(
              padding: WidgetStateProperty.all(widget.padding),
            ),
        child: AppIcon(
          icon.asset,
          height: icon.size,
          width: icon.size,
          color: iconColor,
        ));
  }

  VoidCallback? get onPressed {
    return !widget.isDisabled ? widget.onPressed : null;
  }

  // Override icon.color if defaultIconColor is true
  Color? get iconColor {
    return widget.defaultIconColor ? _buttonStyle.iconColor : widget.icon.color;
  }
}
