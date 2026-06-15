import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_kit/ui_kit.dart';

class AppNavigationRail extends StatefulWidget {
  AppNavigationRail({
    super.key,
    required ValueChanged<dynamic> onPressed,
    required this.currentTab,
    required this.focusNode,
  })  : _onPressedDynamic = onPressed,
        _onPressedInt = null,
        items = null,
        currentIndex = null,
        isDynamic = false;

  AppNavigationRail.dynamic({
    super.key,
    required ValueChanged<int> onPressed,
    required this.currentIndex,
    required this.focusNode,
    required this.items,
  })  : _onPressedInt = onPressed,
        _onPressedDynamic = null,
        currentTab = null,
        isDynamic = true;

  final ValueChanged<dynamic>? _onPressedDynamic;
  final ValueChanged<int>? _onPressedInt;
  final BottomBarTab? currentTab;
  final FocusNode focusNode;

  // For dynamic navigation
  final bool isDynamic;
  final List<({String label, String icon})>? items;
  final int? currentIndex;

  // Helper to call onPressed with the right type
  void onPressed(dynamic value) {
    if (isDynamic) {
      _onPressedInt?.call(value as int);
    } else {
      _onPressedDynamic?.call(value);
    }
  }

  @override
  State<AppNavigationRail> createState() => _AppNavigationRailState();
}

class _AppNavigationRailState extends State<AppNavigationRail> {
  late final List<({String label, String icon, BottomBarTab value})> _buttons = [
    (label: 'Television', icon: Assets.homeIcon, value: BottomBarTab.television),
    (label: 'Television Languages', icon: Assets.tvShowIcon, value: BottomBarTab.televisionLan),
    (label: 'Radio', icon: Assets.podcastIcon, value: BottomBarTab.radio),
    (label: 'DVR', icon: Assets.tvShowIcon, value: BottomBarTab.dvr),
    (label: 'Profile', icon: Assets.profile, value: BottomBarTab.profile),
  ];

  int get _itemCount => widget.isDynamic ? (widget.items?.length ?? 0) : _buttons.length;

  FocusNode _getFocus(int index, int length) {
    return FocusNode(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          if (index == 0) {
            return KeyEventResult.skipRemainingHandlers;
          }
          list[index - 1].requestFocus();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          if (index == length - 1) {
            return KeyEventResult.skipRemainingHandlers;
          }
          list[index + 1].requestFocus();
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
    );
  }

  late final List<FocusNode> list = List.generate(_itemCount, (value) {
    return _getFocus(value, _itemCount);
  });

  @override
  void dispose() {
    for (var element in list) {
      element.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromRGBO(24, 26, 32, 0.85),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 50,
          ),
          Focus(
            focusNode: widget.focusNode,
            onFocusChange: (value) {
              if (value) {
                final currentIdx = widget.isDynamic ? (widget.currentIndex ?? 0) : (widget.currentTab?.index ?? 0);
                if (currentIdx < list.length) {
                  list[currentIdx].requestFocus();
                }
                setState(() {});
              }
            },
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: widget.isDynamic ? _buildDynamicItems() : _buildStaticItems()),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDynamicItems() {
    final items = widget.items!;
    return [
      for (var i = 0; i < items.length; i++)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              focusNode: list[i],
              borderRadius: const BorderRadius.all(Radius.circular(45)),
              onTap: () => widget.onPressed(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: SizedBox(
                  width: 200,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 70,
                        child: AppIcon(
                          items[i].icon,
                          height: 15,
                          width: 15,
                          color: AppColors.greyscale[500],
                          gradient: i == widget.currentIndex ? context.uiColors.primaryGradient : null,
                        ),
                      ),
                      AppText(
                        style: TextStyles.bodySmallBold,
                        text: items[i].label,
                        gradient: i == widget.currentIndex ? context.uiColors.primaryGradient : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _buildStaticItems() {
    return [
      for (final (index, button) in _buttons.indexed)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              focusNode: list[index],
              borderRadius: const BorderRadius.all(Radius.circular(45)),
              onTap: () {
                if (button.value == widget.currentTab && Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                if (button.value != widget.currentTab) {
                  widget.onPressed(button.value);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: SizedBox(
                  width: 200,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 70,
                        child: AppIcon(
                          button.icon,
                          height: 15,
                          width: 15,
                          color: AppColors.greyscale[500],
                          gradient: _getSelectedColor(button.value),
                        ),
                      ),
                      AppText(
                        style: TextStyles.bodySmallBold,
                        text: button.label,
                        gradient: _getSelectedColor(button.value),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
    ];
  }

  LinearGradient? _getSelectedColor(BottomBarTab value) {
    return value == widget.currentTab ? context.uiColors.primaryGradient : null;
  }
}
