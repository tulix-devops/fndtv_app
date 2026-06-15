import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

extension ThemeExtensions on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  WidgetStateProperty<Color?> get foreGround =>
      WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.focused)) {
            return Theme.of(this).focusColor;
          }
          return uiColors.secondary;
        },
      );
  ButtonStyle elevatedButtonStyle(AppButtonStyle buttonStyle) {
    return ElevatedButton.styleFrom(
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: buttonStyle.color,
      disabledBackgroundColor: uiColors.disabledButton,
      backgroundColor: buttonStyle.color,
      padding: buttonStyle.padding,
      shape: buttonStyle.shape.copyWith(
        side: BorderSide(color: buttonStyle.borderColor ?? Colors.transparent),
      ),
    );
  }

  BoxDecoration chipButtonStyle(ChipStyle chipStyle, bool isOutlined) {
    return BoxDecoration(
      color: chipStyle.color,
      borderRadius: chipStyle.shape.borderRadius,
      border: isOutlined
          ? Border.all(color: chipStyle.textStyle.color!, width: 2)
          : null,
    );
  }

  ButtonStyle textButtonStyle(AppButtonStyle buttonStyle) {
    return TextButton.styleFrom(
      elevation: 0,
      disabledBackgroundColor: Colors.transparent,
      backgroundColor: buttonStyle.color,
      padding: buttonStyle.padding,
      shape: buttonStyle.shape,
    );
  }

  // Update colors with app changes
  AppButtonStyle buttonStyle(ButtonType type) {
    final Color primary = uiColors.primary;

    final Color secondary = uiColors.secondary;

    // Icon color is same as text color
    return switch (type) {
      // Primary button
      // Green Color [UiColors.primary]
      // White Text
      ButtonType.primary => AppButtonStyle.regular(
          textStyle: TextStyles.bodyLargeBold.white,
          iconColor: uiColors.onPrimary,
          color: primary,
        ),
      // Rounded Primary button
      // Green Color [UiColors.primary]
      // White Text
      ButtonType.primaryRounded => AppButtonStyle.rounded(
          textStyle: TextStyles.bodyLargeBold.white,
          iconColor: uiColors.onPrimary,
          color: primary,
        ),

      // Secondary button
      // Light green or dark grey color depending on theme [UiColors.secondary]
      // Green Text [UiColors.primary]
      ButtonType.secondary => AppButtonStyle.regular(
          textStyle: TextStyles.bodyLargeBold.primary(this),
          iconColor: uiColors.onSecondary,
          color: secondary,
        ),
      // Rounded Secondary button
      // Light green or dark grey color depending on theme [UiColors.secondary]
      // Green Text [UiColors.primary]
      ButtonType.secondaryRounded => AppButtonStyle.rounded(
          textStyle: TextStyles.bodyLargeBold.primary(this),
          iconColor: uiColors.onSecondary,
          color: secondary,
        ),
      // Icon only button
      // Green Color [UiColors.secondary]
      ButtonType.iconPrimary => AppButtonStyle.icon(
          color: primary,
          iconColor: uiColors.onPrimary,
        ),
      // Rounded Icon only button
      // Green Color [UiColors.secondary]
      ButtonType.iconPrimaryRounded => AppButtonStyle.iconRounded(
          color: primary,
          iconColor: uiColors.onPrimary,
        ),
      // Secondary Icon only button, color changes depending on ui mode
      // [Colors.white] or [AppColors.dark2]
      // Border Color [UiColors.themeButtonBorder]
      ButtonType.iconSecondary => AppButtonStyle.icon(
          color: uiColors.themeButton,
          iconColor: uiColors.onSurface,
          borderColor: uiColors.themeButtonBorder,
        ),
      // Rounded Secondary Icon only button, color changes depending on ui mode
      // [Colors.white] or [AppColors.dark2]
      // Border Color [UiColors.themeButtonBorder]

      ButtonType.iconSecondaryRounded => AppButtonStyle.iconRounded(
          color: uiColors.themeButton,
          iconColor: uiColors.onSurface,
          borderColor: uiColors.themeButtonBorder,
        ),
      // Social Button button, color changes depending on ui mode
      // [Colors.white] or [AppColors.dark2]
      // Border Color [UiColors.themeButtonBorder]

      ButtonType.social => AppButtonStyle.rounded(
          textStyle: TextStyles.bodyLargeBold.surface(this),
          iconColor: uiColors.onSurface,
          color: uiColors.themeButton,
          borderColor: uiColors.themeButtonBorder,
        ),

      /// Transparent button
      ButtonType.text => AppButtonStyle.text(
          iconColor: uiColors.onSurface,
          textStyle: TextStyles.bodyLargeBold.surface(this),
        ),
      ButtonType.textRounded => AppButtonStyle.textRounded(
          iconColor: uiColors.onSurface,
          textStyle: TextStyles.bodyLargeBold.surface(this),
        ),
    };
  }

  ChipStyle chipStyle(ChipType type, bool isOutlined) {
    final Color color = isOutlined ? Colors.transparent : uiColors.primary;
    final Color textColor = isOutlined ? uiColors.primary : Colors.white;

    final TextStyle largeTextStyle =
        TextStyles.bodyXLargeBold.copyWith(color: textColor);

    final TextStyle mediumTextStyle = TextStyles.bodyLargeSemiBold.copyWith(
      color: textColor,
    );

    final TextStyle smallTextStyle = TextStyles.bodyMediumSemiBold.copyWith(
      color: textColor,
    );

    // Icon color is same as text color
    return switch (type) {
      // small Primary chip
      // Green Color [UiColors.primary]
      // White Text
      ChipType.smallPrimary => ChipStyle.smallPrimary(
          textStyle: smallTextStyle,
          color: color,
        ),
      // small Rounded Primary chip
      // Green Color [UiColors.primary]
      // White Text
      ChipType.smallPrimaryRounded => ChipStyle.smallRounded(
          textStyle: smallTextStyle,
          color: color,
        ),

      // medium Primary chip
      // Green Color [UiColors.primary]
      // White Text
      ChipType.mediumPrimary => ChipStyle.mediumPrimary(
          textStyle: mediumTextStyle,
          color: color,
        ),
      // medium Rounded Primary chip
      // Green Color [UiColors.primary]
      // White Text
      ChipType.mediumPrimaryRounded => ChipStyle.mediumRounded(
          textStyle: mediumTextStyle,
          color: color,
        ),

      // large Primary chip
      // Green Color [UiColors.primary]
      // White Text
      ChipType.largePrimary => ChipStyle.largePrimary(
          textStyle: largeTextStyle,
          color: color,
        ),
      // large Rounded Primary chip
      // Green Color [UiColors.primary]
      // White Text
      ChipType.largePrimaryRounded => ChipStyle.largeRounded(
          textStyle: largeTextStyle,
          color: color,
        ),
    };
  }
}

extension TextStyleExtension on TextStyle {
  TextStyle primary(BuildContext context) {
    return copyWith(color: context.uiColors.primary);
  }

  /// Default text returns Text color white or black depending on dark mode
  TextStyle surface(BuildContext context) {
    return copyWith(color: context.uiColors.onSurface);
  }

  TextStyle get black {
    return copyWith(color: Colors.black);
  }

  TextStyle get white {
    return copyWith(color: Colors.white);
  }

  TextStyle get grey {
    return copyWith(color: AppColors.greyscale[500]);
  }
}

extension TextExtension on String {
  String subtractFromString() {
    return substring(0, length - 1);
  }
}

extension FocusNodeListExtension on List<FocusNode> {
  /// use this to focus up and focus left
  void shiftFocusUp(BuildContext context, List<FocusNode> focusNodes,
      {bool shouldLoop = true}) {
    for (int i = 0; i < focusNodes.length; i++) {
      if (this[i].hasFocus) {
        if (shouldLoop) {
          FocusScope.of(context)
              .requestFocus(i == 0 ? this[focusNodes.length - 1] : this[i - 1]);
          return;
        }
        FocusScope.of(context).requestFocus(this[i - 1]);
      }
    }
  }

  /// use this to focus down and focus right
  void shiftFocusDown(BuildContext context, List<FocusNode> focusNodes,
      {bool isSeasonsSelected = false, bool shouldLoop = true}) {
    if (isSeasonsSelected) {
      FocusScope.of(context).focusInDirection(TraversalDirection.down);
      return;
    }

    for (int i = 0; i < focusNodes.length; i++) {
      if (this[i].hasFocus) {
        if (shouldLoop) {
          FocusScope.of(context)
              .requestFocus(i == focusNodes.length - 1 ? this[0] : this[i + 1]);
          return;
        }
        FocusScope.of(context).requestFocus(this[i + 1]);

        return;
      }
    }
  }
}
