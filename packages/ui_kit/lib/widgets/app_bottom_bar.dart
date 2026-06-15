import 'dart:ui';

import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class AppBottomBar extends StatefulWidget {
  final ValueChanged onPressed;
  final BottomBarTab currentTab;

  const AppBottomBar({
    super.key,
    required this.onPressed,
    required this.currentTab,
  });

  @override
  State<AppBottomBar> createState() => _AppBottomBarState();
}

class _AppBottomBarState extends State<AppBottomBar> {
  late final Iterable<({String label, String icon, BottomBarTab value})>
      _buttons = [
    (label: 'Radio', icon: Assets.podcastIcon, value: BottomBarTab.radio),
    (label: 'Television', icon: Assets.home, value: BottomBarTab.television),
    (
      label: 'Television Languages',
      icon: Assets.profileLight,
      value: BottomBarTab.televisionLan
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // final Color color = context.isDarkMode ? AppColors.dark3 : Colors.white;
    final Color color = context.isDarkMode
        ? const Color.fromRGBO(24, 26, 32, 0.85)
        : const Color.fromRGBO(24, 26, 32, 0.85);
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: BottomAppBar(
          surfaceTintColor: color,
          color: color,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(_buttons.length, (int i) {
              return Expanded(
                child: _NavButton(
                  onPressed: (v) {
                    widget.onPressed(v);
                  },
                  icon: _buttons.elementAt(i).icon,
                  label: _buttons.elementAt(i).label,
                  value: _buttons.elementAt(i).value,
                  selectedValue: widget.currentTab,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String icon;
  final String label;
  final BottomBarTab value;
  final BottomBarTab selectedValue;
  final ValueChanged<BottomBarTab> onPressed;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = value == selectedValue;

    final AppIcon icon = AppIcon(
      this.icon,
      color: isActive
          ? context.uiColors.primary
          : AppColors.greyscale[500] as Color,
      height: 24,
      width: 24,
    );

    final Text label = Text(
      this.label,
      textAlign: TextAlign.center,
      style: TextStyles.bodyXSmallBold.copyWith(
        color: isActive
            ? context.uiColors.primary
            : AppColors.greyscale[500] as Color,
      ),
    );

    return MaterialButton(
      shape: const CircleBorder(),
      padding: const EdgeInsets.all(4),
      onPressed: () => onPressed(value),
      child: Column(
        children: [
          icon,
          label,
        ],
      ),
    );
  }
}
