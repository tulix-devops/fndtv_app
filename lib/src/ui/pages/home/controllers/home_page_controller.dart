import 'package:app_focus/app_focus.dart';
import 'package:flutter/material.dart';

class HomePageController {
  late final VerticalPageViewController verticalPageViewController;
  late final VerticalPageViewController channelPageViewController;

  HomePageController({
    required int pageCount,
    required int itemCount,
  }) {
    final FocusNode verticalPageViewFocusNode = FocusNode();
    final FocusNode channelPageViewFocusNode = FocusNode();

    verticalPageViewController = VerticalPageViewController(
      pageCount: pageCount,
      previousFocusNode: channelPageViewFocusNode,
      primaryFocusNode: verticalPageViewFocusNode,
    );

    channelPageViewController = VerticalPageViewController(
      pageCount: 1,
      nextFocusNode: verticalPageViewFocusNode,
      primaryFocusNode: channelPageViewFocusNode,
    );
  }

  void dispose() {
    verticalPageViewController.dispose();
    channelPageViewController.dispose();
  }
}
