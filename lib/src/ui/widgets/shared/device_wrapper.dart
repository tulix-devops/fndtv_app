import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

class DeviceWrapper extends StatelessWidget {
  final Widget? tvWidget;
  final Widget widget;

  const DeviceWrapper({super.key, this.tvWidget, required this.widget});

  @override
  Widget build(BuildContext context) {
    return context.isTv ? tvWidget ?? widget : widget;
  }
}
