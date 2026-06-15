import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

abstract final class TextStyles {
  // 48px
  static const TextStyle h1 = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 48,
  );

  // 40px
  static const TextStyle h2 = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 40,
  );

  // 32px
  static const TextStyle h3 = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 32,
  );

  // 24px
  static const TextStyle h4 = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 24,
  );

  // 20px
  static const TextStyle h5 = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 20,
  );

  // 18px
  static const TextStyle h6 = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 18,
  );

  // 18px
  static const TextStyle bodyXLarge = TextStyle(
    fontSize: 18,
  );

  // 18px
  static final TextStyle bodyXLargeBold = bodyXLarge.copyWith(
    fontWeight: FontWeight.bold,
  );

  // 18px
  static final TextStyle bodyXLargeSemiBold = bodyXLarge.copyWith(
    fontWeight: FontWeight.w600,
  );

  // 18px
  static final TextStyle bodyXLargeMedium = bodyXLarge.copyWith(
    fontWeight: FontWeight.w500,
  );

  // 18px
  static final TextStyle bodyXLargeRegular = bodyXLarge.copyWith(
    fontWeight: FontWeight.normal,
  );

  // 16px
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
  );

  // 16px
  static final TextStyle bodyLargeBold = bodyLarge.copyWith(
    fontWeight: FontWeight.bold,
  );

  // 16px
  static final TextStyle bodyLargeSemiBold = bodyLarge.copyWith(
    fontWeight: FontWeight.w600,
  );

  // 16px
  static final TextStyle bodyLargeMedium = bodyLarge.copyWith(
    fontWeight: FontWeight.w500,
  );

  // 16px
  static final TextStyle bodyLargeRegular = bodyLarge.copyWith(
    fontWeight: FontWeight.normal,
  );

  // 14px
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
  );

  // 14px
  static final TextStyle bodyMediumBold = bodyMedium.copyWith(
    fontWeight: FontWeight.bold,
  );

  // 14px
  static final TextStyle bodyMediumSemiBold = bodyMedium.copyWith(
    fontWeight: FontWeight.w600,
  );

  // 14px
  static final TextStyle bodyMediumMedium = bodyMedium.copyWith(
    fontWeight: FontWeight.w500,
  );

  // 14px
  static final TextStyle bodyMediumRegular = bodyMedium.copyWith(
    fontWeight: FontWeight.normal,
  );

  // 12px
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
  );

  // 12px
  static final TextStyle bodySmallBold = bodySmall.copyWith(
    fontWeight: FontWeight.bold,
  );

  static final TextStyle bodySmallSemiBold = bodySmall.copyWith(
    fontWeight: FontWeight.w600,
  );

  // 12px
  static final TextStyle bodySmallMedium = bodySmall.copyWith(
    fontWeight: FontWeight.w500,
  );

  // 12px
  static final TextStyle bodySmallRegular = bodySmall.copyWith(
    fontWeight: FontWeight.normal,
  );

  // 10px
  static const TextStyle bodyXSmall = TextStyle(
    fontSize: 10,
  );

  // 10px
  static final TextStyle bodyXSmallBold = bodyXSmall.copyWith(
    fontWeight: FontWeight.bold,
  );

  // 10px
  static final TextStyle bodyXSmallSemiBold = bodyXSmall.copyWith(
    fontWeight: FontWeight.w600,
  );

  // 10px
  static final TextStyle bodyXSmallMedium = bodyXSmall.copyWith(
    fontWeight: FontWeight.w500,
  );

  // 10px
  static final TextStyle bodyXSmallRegular = bodyXSmall.copyWith(
    fontWeight: FontWeight.normal,
  );

  static TextStyle getPrimary(BuildContext context, TextStyle style) {
    return style.copyWith(color: context.uiColors.primary);
  }

  static TextStyle getBlack(TextStyle style) {
    return style.copyWith(color: AppColors.greyscale[900]);
  }

  static TextStyle getWhite(TextStyle style) {
    return style.copyWith(color: Colors.white);
  }

  static TextStyle getGrey(TextStyle style) {
    return style.copyWith(color: AppColors.greyscale[500]);
  }
}
