import 'dart:ui';

import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/index.dart';
import 'package:fndtv/src/ui/widgets/tv/tv_back_hint.dart';
import 'package:fndtv/src/ui/widgets/tv/tv_clock.dart';
import 'package:ui_kit/ui_kit.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({
    super.key,
    this.color,
    this.hasNavbar = true,
    required this.body,
    this.navigationItems,
    this.currentNavIndex,
    this.onNavChanged,
  });

  /// ScrollView Body
  final Widget body;

  /// Scaffold Color
  final Color? color;

  // Also changes system nav bar color
  final bool hasNavbar;

  /// Dynamic navigation items - list of (label, icon) tuples
  final List<({String label, IconData icon})>? navigationItems;

  /// Current navigation index
  final int? currentNavIndex;

  /// Navigation changed callback
  final void Function(int)? onNavChanged;

  @override
  State<AppScaffold> createState() => AppScaffoldState();
}

class AppScaffoldState extends State<AppScaffold> {
  /// Reveals the TV nav rail and moves D-pad focus onto it. Used to restore
  /// focus after a full-screen popup (e.g. the language dialog) closes — by
  /// then the rail's per-item focus nodes have been disposed, so the framework
  /// cannot restore focus on its own.
  void requestNavFocus() {
    if (!mounted) return;
    setState(() => hasFocus = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) navigationFocus.requestFocus();
    });
  }

  bool hasFocus = false;
  final FocusNode _placeHolderFocus = FocusNode();

  bool get _isLandscape {
    final orientation = MediaQuery.of(context).orientation;
    return orientation == Orientation.landscape;
  }

  late FocusNode navigationFocus;

  void navigationListener() {
    if (mounted) {
      setState(() {
        hasFocus = navigationFocus.hasFocus ||
            navigationFocus.descendants.any((element) => element.hasFocus);
      });
    }
  }

  late FocusNode contentFocusNode;
  @override
  void initState() {
    super.initState();
    contentFocusNode = FocusNode(
      canRequestFocus: false,
      onKeyEvent: (node, event) {
        if (!context.isTv) {
          return KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.goBack) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (widget.hasNavbar) {
              setState(() {
                hasFocus = true;
                navigationFocus.requestFocus();
              });
              return;
            }
            if (context.canPop()) {
              context.pop();
            }
          });
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
            widget.hasNavbar) {
          // Let Left move within the content first (e.g. between grid columns).
          // Only reveal the nav rail when focus is already at the left edge and
          // couldn't move any further left.
          if (event is KeyDownEvent || event is KeyRepeatEvent) {
            final moved = FocusManager.instance.primaryFocus
                    ?.focusInDirection(TraversalDirection.left) ??
                false;
            if (moved) return KeyEventResult.handled;
            Future.delayed(const Duration(milliseconds: 200), () {
              if (!mounted) return;
              setState(() {
                hasFocus = true;
                navigationFocus.requestFocus();
              });
            });
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );

    navigationFocus = FocusNode()..addListener(navigationListener);
  }

  @override
  void dispose() {
    contentFocusNode.dispose();
    _placeHolderFocus.dispose();
    navigationFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Whether the TV nav rail is currently revealed (focused). When open the
    // content slides right by the rail width so nothing is covered/dimmed.
    final bool navOpen = context.isTv &&
        widget.hasNavbar &&
        (_placeHolderFocus.hasFocus || hasFocus);

    final Widget content = Focus(
      onFocusChange: (value) {
        setState(() {});
      },
      focusNode: contentFocusNode,
      child: widget.body,
    );

    final Widget body = Stack(
      children: <Widget>[
        if (context.isTv)
          AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(left: navOpen ? kTvNavWidth : 0),
            child: content,
          )
        else
          content,
        if (context.isTv) ...[
          if (widget.hasNavbar)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(-1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
                child: _placeHolderFocus.hasFocus || hasFocus
                    ? (widget.navigationItems != null
                        ? AppNavigationRail.dynamic(
                            key: const ValueKey('AppNavigationRail'),
                            focusNode: navigationFocus,
                            onPressed: (index) {
                              widget.onNavChanged?.call(index);
                            },
                            currentIndex: widget.currentNavIndex ?? 0,
                            items: widget.navigationItems!,
                          )
                        : BlocSelector<AppCubit, AppState, BottomBarTab>(
                            selector: (state) => state.currentTab,
                            builder: (context, state) {
                              return AppNavigationRail(
                                key: const ValueKey('AppNavigationRail'),
                                focusNode: navigationFocus,
                                onPressed: (s) {
                                  if (context.canPop()) {
                                    context
                                        .read<AppCubit>()
                                        .changeTab(s, canPop: true);
                                    context.pop();
                                  } else {
                                    context.read<AppCubit>().changeTab(s);
                                  }
                                },
                                currentTab: state,
                              );
                            },
                          ))
                    : Focus(
                        key: const ValueKey('EmptyFocusPlaceholder'),
                        skipTraversal: true,
                        onFocusChange: (value) {
                          if (value) {
                            navigationFocus.requestFocus();
                          }
                          setState(() {});
                        },
                        focusNode: _placeHolderFocus,
                        child: const SizedBox.shrink(),
                      ),
              ),
            ),
          // Local-time clock, top-right. Tap/select to open date settings.
          const Positioned(
            top: 18,
            right: 24,
            child: TvClock(),
          ),
          // Back-to-menu hint, shown while the content (not the nav rail) is
          // active — Back / Left reveals the navigation menu.
          if (widget.hasNavbar && !navOpen)
            const Positioned(
              left: 24,
              bottom: 16,
              child: TvBackHint(),
            ),
        ]
      ],
    );

    return UiOverlayProvider(
      child: OverlayStack(
        child: Scaffold(
          bottomNavigationBar: widget.hasNavbar && !context.isTv
              ? (widget.navigationItems != null && widget.onNavChanged != null
                  ? _DynamicBottomBar(
                      items: widget.navigationItems!,
                      currentIndex: widget.currentNavIndex ?? 0,
                      onPressed: widget.onNavChanged!,
                    )
                  : BlocSelector<AppCubit, AppState, BottomBarTab>(
                      selector: (state) => state.currentTab,
                      builder: (context, currentTab) {
                        return AppBottomBar(
                          onPressed: (s) {
                            context.read<AppCubit>().changeTab(s);
                          },
                          currentTab: currentTab,
                        );
                      },
                    ))
              : null,
          backgroundColor: widget.color,
          extendBody: true,
          body: context.isTv
              ? body
              : SafeArea(
                  top: !_isLandscape,
                  bottom: false,
                  right: false,
                  left: false,
                  child: body,
                ),
        ),
      ),
    );
  }
}

class _DynamicBottomBar extends StatelessWidget {
  const _DynamicBottomBar({
    required this.items,
    required this.currentIndex,
    required this.onPressed,
  });

  final List<({String label, IconData icon})> items;
  final int currentIndex;
  final void Function(int) onPressed;

  @override
  Widget build(BuildContext context) {
    const Color color = Color.fromRGBO(24, 26, 32, 0.85);
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
            children: List.generate(items.length, (i) {
              final bool isActive = i == currentIndex;
              final Color itemColor = isActive
                  ? context.uiColors.primary
                  : AppColors.greyscale[500] as Color;
              return Expanded(
                child: MaterialButton(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(4),
                  onPressed: () => onPressed(i),
                  child: Column(
                    children: [
                      Icon(
                        items[i].icon,
                        color: itemColor,
                        size: 24,
                      ),
                      Text(
                        items[i].label,
                        textAlign: TextAlign.center,
                        style: TextStyles.bodyXSmallBold.copyWith(
                          color: itemColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
