import 'package:flutter/material.dart';
import 'package:ui_kit/widgets/app_loading_indicator.dart';
import 'package:ui_kit/widgets/buttons/app_button.dart';

class GridViewBuilder extends StatelessWidget {
  const GridViewBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.showLoadingIndicator,
    required this.paginationButton,
  });
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final bool showLoadingIndicator;
  final ({bool visibility, void Function() callback}) paginationButton;
  @override
  Widget build(BuildContext context) {
    final double mainAxisAlignment =
        (MediaQuery.sizeOf(context).height / 3) + 30;
    final double maxCrossAxisExtent =
        (MediaQuery.sizeOf(context).width / 6) - 10;
    return CustomScrollView(
      slivers: [
        SliverGrid.builder(
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxCrossAxisExtent,
            mainAxisSpacing: 0,
            childAspectRatio: 16 / 9,
            mainAxisExtent: mainAxisAlignment,
            crossAxisSpacing: 0,
          ),
          itemBuilder: itemBuilder,
        ),
        if (showLoadingIndicator)
          const SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(
                  height: 40,
                ),
                AppLoadingIndicator(size: 50),
                SizedBox(
                  height: 20,
                )
              ],
            ),
          ),
        if (paginationButton.visibility)
          SliverToBoxAdapter(
            child: AppButton.primary(
              label: 'Load More',
              onPressed: paginationButton.callback,
            ),
          )
      ],
    );
  }
}
