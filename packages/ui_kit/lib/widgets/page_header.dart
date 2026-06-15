import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    this.child,
    this.page,
    required this.onPressed,
    required this.isMainPage,
    required this.isTv,
    this.titlePadding,
  });

  final String? page;
  final Widget? child;
  final VoidCallback onPressed;
  final bool isMainPage;
  final bool isTv;
  final EdgeInsets? titlePadding;

  @override
  Widget build(BuildContext context) {
    final bool isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return SliverAppBar(
      leading: null,
      toolbarHeight: isPortrait ? 50 : 70,
      surfaceTintColor: context.uiColors.surface,
      backgroundColor: context.uiColors.surface,
      automaticallyImplyLeading: false,
      floating: true,
      primary: true,
      elevation: 0,
      flexibleSpace: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: context.uiColors.surface,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    if (!isMainPage)
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.all(4),
                          shape: const CircleBorder(),
                        ),
                        onPressed: onPressed,
                        child: AppIcon(
                          Assets.arrowLeft,
                          height: 28,
                          width: 24,
                          color: context.uiColors.onSurface,
                        ),
                      ),
                    Margins.horizontal20,
                    if (page != null)
                      Padding(
                          padding: titlePadding ?? EdgeInsets.zero,
                          child: AppText(
                            text: "$page",
                            style: TextStyles.h4,
                            gradient: context.uiColors.primaryGradient,
                          )),
                  ],
                ),
                if (child != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: FittedBox(
                      fit: BoxFit.none,
                      child: child!,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
