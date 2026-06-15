import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class UiTvListHeader extends StatelessWidget {
  const UiTvListHeader({
    super.key,
    required this.headerTitle,
  });

  final String headerTitle;

  @override
  Widget build(BuildContext context) {
    const EdgeInsets headerPadding = EdgeInsets.fromLTRB(15, 0, 15, 0);

    return Padding(
      padding: headerPadding,
      child: Text(
        headerTitle,
        style: TextStyles.h5.copyWith(color: context.uiColors.surface),
      ),
    );
  }
}
