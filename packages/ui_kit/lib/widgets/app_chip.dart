import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class AppChip extends StatefulWidget {
  final void Function() onPressed;
  final String label;
  final ({String asset, double? size})? prefixIcon;
  final ({String asset, double? size})? suffixIcon;
  final ChipType type;
  final Color? color;
  final bool isDisabled;
  final bool isOutlined;
  final FocusNode? focusNode;

  const AppChip.smallPrimary({
    super.key,
    this.isDisabled = false,
    this.isOutlined = false,
    this.prefixIcon,
    this.suffixIcon,
    this.color,
    required this.label,
    required this.onPressed,
    this.focusNode,
  }) : type = ChipType.smallPrimary;

  const AppChip.smallPrimaryRounded({
    super.key,
    this.isDisabled = false,
    this.isOutlined = false,
    this.prefixIcon,
    this.suffixIcon,
    this.color,
    required this.label,
    required this.onPressed,
    this.focusNode,
  }) : type = ChipType.smallPrimaryRounded;

  const AppChip.mediumPrimary({
    super.key,
    this.isDisabled = false,
    this.isOutlined = false,
    this.prefixIcon,
    this.suffixIcon,
    this.color,
    required this.label,
    required this.onPressed,
    this.focusNode,
  }) : type = ChipType.mediumPrimary;

  const AppChip.mediumPrimaryRounded({
    super.key,
    this.isDisabled = false,
    this.isOutlined = false,
    this.prefixIcon,
    this.suffixIcon,
    this.color,
    required this.label,
    required this.onPressed,
    this.focusNode,
  }) : type = ChipType.mediumPrimaryRounded;

  const AppChip.largePrimary({
    super.key,
    this.isDisabled = false,
    this.isOutlined = false,
    this.prefixIcon,
    this.suffixIcon,
    this.color,
    required this.label,
    required this.onPressed,
    this.focusNode,
  }) : type = ChipType.largePrimary;

  const AppChip.largePrimaryRounded({
    super.key,
    this.isDisabled = false,
    this.isOutlined = false,
    this.prefixIcon,
    this.suffixIcon,
    this.color,
    required this.label,
    required this.onPressed,
    this.focusNode,
  }) : type = ChipType.largePrimaryRounded;

  @override
  State<AppChip> createState() => _AppChipState();
}

class _AppChipState extends State<AppChip> {
  late ChipStyle _chipStyle;
  late ({String asset, double size})? prefixIcon = widget.prefixIcon != null
      ? (
          asset: widget.prefixIcon!.asset,
          size: widget.prefixIcon?.size ?? _chipStyle.iconSize,
        )
      : null;

  late ({String asset, double size})? suffixIcon = widget.suffixIcon != null
      ? (
          asset: widget.suffixIcon!.asset,
          size: widget.suffixIcon?.size ?? _chipStyle.iconSize,
        )
      : null;
  @override
  Widget build(BuildContext context) {
    _chipStyle = context.chipStyle(widget.type, widget.isOutlined);

    return Material(
      color: Colors.transparent,
      borderRadius: _chipStyle.shape.borderRadius,
      child: InkWell(
        focusNode: widget.focusNode,
        borderRadius: _chipStyle.shape.borderRadius as BorderRadius,
        onTap: onPressed,
        autofocus: true,
        child: Ink(
          padding: widget.isOutlined
              ? _chipStyle.outlinedPadding
              : _chipStyle.padding,
          decoration:
              context.chipButtonStyle(_chipStyle, widget.isOutlined).copyWith(
                    // If its outlined and we have custom color change border color if not widget.color
                    border: widget.isOutlined && widget.color != null
                        ? Border.all(color: widget.color!, width: 2)
                        : null,
                    color: !widget.isOutlined && widget.color != null
                        ? widget.color
                        : null,
                  ),
          child: DefaultButtonContent(
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            iconColor: _chipStyle.textStyle.color!,
            contentMargin: _chipStyle.contentMargin,
            text: Text(
              widget.label,
              maxLines: 1,
              style: _chipStyle.textStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  VoidCallback? get onPressed {
    return !widget.isDisabled ? widget.onPressed : null;
  }
}
