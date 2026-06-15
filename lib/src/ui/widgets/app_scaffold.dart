import 'dart:ui';

import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/index.dart';
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
  final List<({String label, String icon})>? navigationItems;

  /// Current navigation index
  final int? currentNavIndex;

  /// Navigation changed callback
  final void Function(int)? onNavChanged;

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
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
        hasFocus = navigationFocus.hasFocus || navigationFocus.descendants.any((element) => element.hasFocus);
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
    final Widget body = Stack(
      children: <Widget>[
        Focus(
          onFocusChange: (value) {
            setState(() {});
          },
          focusNode: contentFocusNode,
          child: widget.body,
        ),
        if (context.isTv) ...[
          if (widget.hasNavbar && navigationFocus.hasFocus)
            Container(
              color: Colors.black26,
            ),
          if (widget.hasNavbar)
            Positioned(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-1.5, .3),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
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
                                    context.read<AppCubit>().changeTab(s, canPop: true);
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
            )
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
          backgroundColor: context.uiColors.surface,
          extendBody: true,
          body: context.isTv
              ? SafeArea(
                  minimum: const EdgeInsets.all(10),
                  child: Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.backgroundGradient,
                      ),
                      child: body),
                )
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

  final List<({String label, String icon})> items;
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
                      AppIcon(
                        items[i].icon,
                        color: itemColor,
                        height: 24,
                        width: 24,
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
