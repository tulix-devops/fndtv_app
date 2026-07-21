import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_kit/ui_kit.dart';

/// Brand red used for the TV navigation rail highlight (kept local — ui_kit
/// cannot import app-level constants).
const Color _navAccent = Color(0xFFC7443F);

/// Solid panel colour — a single flat dark tone (no gradient) so the rail reads
/// as one clean surface next to the content.
const Color _navPanel = Color(0xFF15171C);

/// Fixed rail width; the content is pushed right by this amount when open.
const double kTvNavWidth = 268;

class AppNavigationRail extends StatefulWidget {
  const AppNavigationRail({
    super.key,
    required ValueChanged<dynamic> onPressed,
    required this.currentTab,
    required this.focusNode,
  })  : _onPressedDynamic = onPressed,
        _onPressedInt = null,
        items = null,
        currentIndex = null,
        isDynamic = false;

  const AppNavigationRail.dynamic({
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
  final List<({String label, IconData icon})>? items;
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
  late final List<({String label, String icon, BottomBarTab value})> _buttons =
      [
    (label: 'Home', icon: Assets.homeIcon, value: BottomBarTab.television),
    (label: 'Live', icon: Assets.liveIcon, value: BottomBarTab.televisionLan),
    (label: 'Radio', icon: Assets.headphone, value: BottomBarTab.radio),
    (label: 'About', icon: Assets.infoSquare, value: BottomBarTab.profile),
  ];

  int get _itemCount =>
      widget.isDynamic ? (widget.items?.length ?? 0) : _buttons.length;

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
      width: kTvNavWidth,
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        color: _navPanel,
        border: Border(right: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 30, 20, 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(Assets.logo, height: 40, fit: BoxFit.contain),
                const SizedBox(width: 12),
                const Text(
                  'FNDTV',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          // Scrolls when there are more items than fit the rail height; focus
          // traversal auto-scrolls the focused item into view.
          Expanded(
            child: SingleChildScrollView(
              child: Focus(
                focusNode: widget.focusNode,
                onFocusChange: (value) {
                  if (value) {
                    final currentIdx = widget.isDynamic
                        ? (widget.currentIndex ?? 0)
                        : (widget.currentTab?.index ?? 0);
                    if (currentIdx < list.length) {
                      list[currentIdx].requestFocus();
                    }
                    setState(() {});
                  }
                },
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: widget.isDynamic
                        ? _buildDynamicItems()
                        : _buildStaticItems()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDynamicItems() {
    final items = widget.items!;
    return [
      for (var i = 0; i < items.length; i++)
        _RailItem(
          focusNode: list[i],
          icon: items[i].icon,
          label: items[i].label,
          selected: i == widget.currentIndex,
          onTap: () => widget.onPressed(i),
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
                if (button.value == widget.currentTab &&
                    Navigator.canPop(context)) {
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
                      Flexible(
                        child: AppText(
                          style: TextStyles.bodySmallBold
                              .copyWith(overflow: TextOverflow.ellipsis),
                          text: button.label,
                          gradient: _getSelectedColor(button.value),
                        ),
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

/// A single row in the dynamic TV navigation rail. Highlights solid red when
/// focused by the remote, and red-tinted when it's the active tab.
class _RailItem extends StatefulWidget {
  final FocusNode focusNode;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RailItem({
    required this.focusNode,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
  }

  void _onFocus() {
    if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool focused = _focused;
    final bool selected = widget.selected;

    final Color bg = focused
        ? _navAccent
        : (selected ? _navAccent.withValues(alpha: 0.16) : Colors.transparent);
    final Color fg = focused
        ? Colors.white
        : (selected ? _navAccent : Colors.white60);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          focusNode: widget.focusNode,
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 236,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(widget.icon, size: 23, color: fg),
                const SizedBox(width: 14),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          focused || selected ? FontWeight.w700 : FontWeight.w500,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
