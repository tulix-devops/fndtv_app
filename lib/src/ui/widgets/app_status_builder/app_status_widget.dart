import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

class AppStatusWidget extends StatelessWidget {
  const AppStatusWidget({
    super.key,
    required this.status,
    required this.loaderWidget,
    required this.errorWidget,
    required this.widget,
  });

  final Status status;

  final Widget loaderWidget;

  final Widget errorWidget;

  final Widget widget;

  @override
  Widget build(BuildContext context) {
    if (status.isLoading) {
      return loaderWidget;
    }

    if (status.isFailure) {
      return errorWidget;
    }

    return widget;
  }
}
