import 'package:flutter/material.dart';

class DraggableController {
  late AnimationController controller;

  void onDragStart(DragStartDetails details) {
    controller.stop();
  }

  void onDragUpdate(DragUpdateDetails details, double height) {
    controller.value -= details.primaryDelta! / height;
  }

  void onDragEnd(DragEndDetails details, {required double velocityThreshold}) {
    if (details.primaryVelocity!.abs() >= velocityThreshold) {
      if (details.primaryVelocity! > 0) {
        controller.reverse();
      } else {
        controller.forward();
      }
    } else {
      if (controller.value > 0.5) {
        controller.forward();
      } else {
        controller.reverse();
      }
    }
  }
}
