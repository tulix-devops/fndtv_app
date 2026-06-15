import 'package:flutter/material.dart';

const BorderRadius _buttonBorderRadius =
    BorderRadius.all(Radius.circular(16.0));

const BorderRadius _roundedButtonBorderRadius =
    BorderRadius.all(Radius.circular(100));

const RoundedRectangleBorder _border =
    RoundedRectangleBorder(borderRadius: _buttonBorderRadius);

const RoundedRectangleBorder _roundedBorder =
    RoundedRectangleBorder(borderRadius: _roundedButtonBorderRadius);

const EdgeInsets _largePadding = EdgeInsets.symmetric(
  horizontal: 24,
  vertical: 10,
);

const EdgeInsets _mediumPadding = EdgeInsets.symmetric(
  horizontal: 20,
  vertical: 8,
);

const EdgeInsets _smallPadding = EdgeInsets.symmetric(
  horizontal: 16,
  vertical: 6,
);

const EdgeInsets _largeOutlinedPadding = EdgeInsets.symmetric(
  horizontal: 22,
  vertical: 8,
);

const EdgeInsets _mediumOutlinedPadding = EdgeInsets.symmetric(
  horizontal: 18,
  vertical: 6,
);

const EdgeInsets _smallOutlinedPadding = EdgeInsets.symmetric(
  horizontal: 14,
  vertical: 4,
);

const double _contentMargin = 8;
const double _smallIconSize = 16;
const double _mediumIconSize = 20;
const double _largeIconSize = 24;

final class ChipStyle {
  final TextStyle textStyle;
  final Color color;
  final double iconSize;
  final RoundedRectangleBorder shape;
  final double contentMargin;
  final EdgeInsets padding;
  final EdgeInsets outlinedPadding;

  ChipStyle.smallPrimary({
    required this.textStyle,
    required this.color,
  })  : contentMargin = _contentMargin,
        iconSize = _smallIconSize,
        padding = _smallPadding,
        outlinedPadding = _smallOutlinedPadding,
        shape = _border;

  ChipStyle.smallRounded({
    required this.textStyle,
    required this.color,
  })  : contentMargin = _contentMargin,
        iconSize = _smallIconSize,
        padding = _smallPadding,
        outlinedPadding = _smallOutlinedPadding,
        shape = _roundedBorder;

  ChipStyle.mediumPrimary({
    required this.textStyle,
    required this.color,
  })  : contentMargin = _contentMargin,
        iconSize = _mediumIconSize,
        padding = _mediumPadding,
        outlinedPadding = _mediumOutlinedPadding,
        shape = _border;

  ChipStyle.mediumRounded({
    required this.textStyle,
    required this.color,
  })  : contentMargin = _contentMargin,
        iconSize = _mediumIconSize,
        padding = _mediumPadding,
        outlinedPadding = _mediumOutlinedPadding,
        shape = _roundedBorder;

  ChipStyle.largePrimary({
    required this.textStyle,
    required this.color,
  })  : contentMargin = _contentMargin,
        iconSize = _largeIconSize,
        padding = _largePadding,
        outlinedPadding = _largeOutlinedPadding,
        shape = _border;

  ChipStyle.largeRounded({
    required this.textStyle,
    required this.color,
  })  : contentMargin = _contentMargin,
        iconSize = _largeIconSize,
        padding = _largePadding,
        outlinedPadding = _largeOutlinedPadding,
        shape = _roundedBorder;
}
