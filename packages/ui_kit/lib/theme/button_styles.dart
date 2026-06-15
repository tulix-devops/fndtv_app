import 'package:flutter/material.dart';

const BorderRadius _buttonBorderRadius =
    BorderRadius.all(Radius.circular(16.0));

const BorderRadius _roundedButtonBorderRadius =
    BorderRadius.all(Radius.circular(100));

const RoundedRectangleBorder _border =
    RoundedRectangleBorder(borderRadius: _buttonBorderRadius);

const RoundedRectangleBorder _roundedBorder =
    RoundedRectangleBorder(borderRadius: _roundedButtonBorderRadius);

const EdgeInsets _buttonPadding = EdgeInsets.symmetric(
  horizontal: 16,
  vertical: 18,
);

const EdgeInsets _iconButtonPadding = EdgeInsets.all(8);

const double _contentMargin = 16;

final class AppButtonStyle {
  final TextStyle? textStyle;
  final Color? borderColor;
  final Color color;
  final Color iconColor;
  final OutlinedBorder shape;
  final EdgeInsets padding;
  final double contentMargin;

  AppButtonStyle.regular({
    required this.iconColor,
    required this.textStyle,
    required this.color,
    this.borderColor,
  })  : contentMargin = _contentMargin,
        padding = _buttonPadding,
        shape = _border;

  AppButtonStyle.rounded({
    required this.iconColor,
    required this.textStyle,
    required this.color,
    this.borderColor,
  })  : contentMargin = _contentMargin,
        padding = _buttonPadding,
        shape = _roundedBorder;

  AppButtonStyle.roundedGradient(
      {required this.iconColor,
      required this.textStyle,
      this.borderColor,
      this.color = Colors.transparent})
      : contentMargin = _contentMargin,
        padding = _buttonPadding,
        shape = _roundedBorder;

  AppButtonStyle.icon({
    required this.iconColor,
    required this.color,
    this.borderColor,
  })  : contentMargin = 0,
        padding = _iconButtonPadding,
        shape = _border,
        textStyle = null;

  AppButtonStyle.iconRounded({
    required this.iconColor,
    required this.color,
    this.borderColor,
  })  : contentMargin = 0,
        padding = _iconButtonPadding,
        shape = const CircleBorder(),
        textStyle = null;

  AppButtonStyle.text({
    required this.iconColor,
    required this.textStyle,
    this.color = Colors.transparent,
    this.borderColor,
  })  : contentMargin = 0,
        padding = const EdgeInsets.all(4),
        shape = _roundedBorder;

  AppButtonStyle.textRounded({
    required this.iconColor,
    required this.textStyle,
    this.color = Colors.transparent,
    this.borderColor,
  })  : contentMargin = 0,
        padding = const EdgeInsets.all(4),
        shape = const CircleBorder();
}
