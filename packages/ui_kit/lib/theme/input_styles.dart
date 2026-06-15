import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

abstract final class InputStyle {
  static InputDecoration decoration(Color primaryColor, Color errorColor) {
    const BorderRadius borderRadius = BorderRadius.all(Radius.circular(12.0));

    const OutlineInputBorder defaultBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide.none,
    );

    return InputDecoration(
        hintStyle: TextStyles.bodyMediumRegular.grey,
        errorStyle: TextStyles.bodyMediumRegular.copyWith(color: errorColor),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 16.0,
        ),
        enabledBorder: defaultBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: primaryColor),
        ),
        errorBorder: defaultBorder,
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: errorColor),
        ),
        disabledBorder: defaultBorder);
  }
}
