// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class AppTabSwitcher extends StatelessWidget {
  final String title;
  final Color? color;
  final String? leftSideIcon;
  final String? rightSideIcon;
  final bool isActive;
  final void Function() onTap;

  const AppTabSwitcher(
      {super.key,
      required this.title,
      this.color,
      this.leftSideIcon,
      this.rightSideIcon,
      this.isActive = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color _color = _getColor(context);

    const EdgeInsets _padding =
        EdgeInsets.symmetric(horizontal: 12.0, vertical: 5);
    const double _width = 4.0;

    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(5)),
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _getColor(context),
                width: _width,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Icon(leftSideIcon, color: _color),
              Padding(
                padding: _padding,
                child: Text(
                  title,
                  style: TextStyles.bodyXLargeSemiBold.copyWith(
                    color: _getColor(context),
                  ),
                ),
              ),
              _Icon(rightSideIcon, color: _color),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPrimaryColor(BuildContext context) {
    return color ?? context.uiColors.primary;
  }

  Color _getInactiveColor(BuildContext context) {
    return (context.isDarkMode
        ? AppColors.greyscale[700]
        : AppColors.greyscale[500]) as Color;
  }

  Color _getColor(BuildContext context) {
    return isActive ? _getPrimaryColor(context) : _getInactiveColor(context);
  }
}

class _Icon extends StatelessWidget {
  const _Icon(
    this.icon, {
    required this.color,
  });

  final String? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return icon != null && icon!.isNotEmpty
        ? AppIcon(
            icon!,
            color: color,
          )
        : const SizedBox.shrink();
  }
}
