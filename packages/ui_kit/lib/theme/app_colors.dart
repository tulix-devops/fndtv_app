import 'package:flutter/material.dart';

class DefaultColors {
  const DefaultColors(this._primaryColor);

  final AppThemeColor _primaryColor;

  Color get success => const Color(0xFF06C149);
  Color get warning => const Color(0xFFFACC15);
  Color get error => const Color(0xFFF75555);
  Color get info => const Color(0xFF246BFD);
  Color get disabled => const Color(0xFFD8D8D8);

  /// Disabled Button is dark Green app wide (depends on design) [
  /// [AppColors.disabledGreen]
  Color get disabledButton => const Color(0xFFE91E63).withOpacity(0.2);
  Color get onDisabledButton => Colors.white;

  /// primary color based on design [AppColors.pink[500]]
  Color get primary => AppColors.themeColors[_primaryColor] as Color;
  LinearGradient get primaryGradient => AppColors.themeGradients[_primaryColor] as LinearGradient;

  /// primary text color based on design [Colors.white]
  Color get onPrimary => Colors.white;
}

abstract final class UiColors extends DefaultColors {
  const UiColors(super.primaryColor);

  // Secondary color is based on secondary button color
  Color get secondary;

  // Secondary color is based on secondary button text color
  Color get onSecondary;

  /// White or [AppColors.dark1] depending on ui theme
  Color get surface;

  /// Main Text Color white or black depending on ui theme
  Color get onSurface;

  /// App color for tv
  Color get tvSurface;

  /// Theme Button Color like used for icon,social buttons
  /// [Colors.white]
  /// [AppColors.dark2]
  Color get themeButton;

  /// Theme Buttons have borders used for icon,social buttons
  /// [AppColors.greyscale[300]]
  /// [AppColors.dark3]
  Color get themeButtonBorder;
}

final class LightUiColors extends UiColors {
  const LightUiColors(super.primaryColor);

  @override
  Color get secondary => AppColors.dark3;

  @override
  Color get onSecondary => Colors.white;

  @override
  Color get surface => AppColors.dark1;

  @override
  Color get tvSurface => AppColors.black;

  @override
  Color get onSurface => Colors.white;

  @override
  Color get themeButton => AppColors.dark2;

  @override
  Color get themeButtonBorder => AppColors.dark3;
}

final class DarkUiColors extends UiColors {
  const DarkUiColors(super.primaryColor);

  @override
  Color get secondary => AppColors.dark3;

  @override
  Color get onSecondary => Colors.white;

  @override
  Color get surface => AppColors.dark1;

  @override
  Color get tvSurface => AppColors.black;

  @override
  Color get onSurface => Colors.white;

  @override
  Color get themeButton => AppColors.dark2;

  @override
  Color get themeButtonBorder => AppColors.dark3;
}

enum AppThemeColor { deepPurple, teal, amber, pink, indigo, blueGrey, green, blue, red }

abstract final class AppColors {
  static const Map<int, Color> green = {
    500: Color(0xFF06C149),
    400: Color(0xFF38CD6D),
    300: Color(0xFF6ADA92),
    200: Color(0xFF9BE6B6),
    100: Color(0xFFE6F9ED),
  };

  // static const Map<int, Color> black = {
  //   500: Color(0xFF000000),
  //   400: Color(0xFF1A1A1A),
  //   300: Color(0xFF666666),
  //   200: Color(0xFF999999),
  //   100: Color(0xFFCCCCCC),
  // };

  static const Color disabledGreen = Color(0xFF0E9E42);

  static const Map<int, Color> yellow = {
    500: Color(0xFFFFD300),
    400: Color(0xFFFFDC33),
    300: Color(0xFFFFE566),
    200: Color(0xFFFFED99),
    100: Color(0xFFFFFBE6),
  };

  static const Map<int, Color> greyscale = {
    900: Color(0xFF212121),
    800: Color(0xFF424242),
    700: Color(0xFF616161),
    600: Color(0xFF757575),
    500: Color(0xFF9E9E9E),
    400: Color(0xFFBDBDBD),
    300: Color(0xFFE0E0E0),
    200: Color(0xFFEEEEEE),
    100: Color(0xFFF5F5F5),
    50: Color(0xFFFAFAFA),
  };

  static const LinearGradient greenGradient = LinearGradient(
    colors: [
      Color(0xFF06C149),
      Color(0xFF1ADF61),
    ],
  );

  static const LinearGradient pinkGradient = LinearGradient(
    colors: [
      Color(0xFFFE4E6F),
      Color(0xFFFF4451),
    ],
  );

  static const LinearGradient redGradient = LinearGradient(
    colors: [
      Color(0xFFC62828), // Deep red (from the Sacred Hearts)
      Color(0xFFD32F2F), // Rich red
      Color(0xFFE57373), // Lighter red with warmth
    ],
  );

  static const LinearGradient yellowGradient = LinearGradient(
    colors: [
      Color(0xFFFACC15),
      Color(0xFFFFE580),
    ],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [
      Color(0xFF7210FF),
      Color(0xFF9D59FF),
    ],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [
      Color(0xFF002171),
      Color(0xFF64B5F6),
      Color(0xFF0D47A1),
      Color(0xFF1976D2),
    ],
    stops: [
      0.0,
      0.35,
      0.7,
      1.0,
    ],
  );

  static const LinearGradient blueGradient =
      LinearGradient(begin: Alignment.bottomRight, end: Alignment.bottomLeft, colors: [
    Color(0xFF00C1D9),
    Color(0xFF007197),
  ]);

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [
      Color(0xFFFB9400),
      Color(0xFFFFAB38),
    ],
  );

  static const LinearGradient tealGradient = LinearGradient(
    colors: [
      Color(0xFF009688),
      Color.fromARGB(255, 1, 231, 208),
    ],
  );

  static final LinearGradient greyGradient = LinearGradient(
    colors: [
      dark1.withOpacity(0.6),
      Colors.transparent,
    ],
    stops: const [
      0.0,
      0.7,
    ],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static final LinearGradient homePageMask = LinearGradient(
    colors: [
      dark1.withOpacity(0.6),
      Colors.transparent,
      dark1.withOpacity(0.6),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Color overlaySurface = Color(0xFF09101D);
  static final Color overlaySurfaceWithOpacity = overlaySurface.withOpacity(0.7);

  static const Color dark1 = Color(0xFF181A20);
  static const Color dark2 = Color(0xFF1F222A);
  static const Color dark3 = Color(0xFF35383F);

  static const Color black = Color.fromARGB(255, 0, 0, 0);

  static const BoxShadow boxShadow = BoxShadow(
    color: Color.fromRGBO(4, 6, 15, 0.05),
    blurRadius: 10, // Adjust as needed
    spreadRadius: 2, // Adjust as needed
    offset: Offset(0, 4), // Adjust the offset as needed
  );

  static const Map<AppThemeColor, Color> themeColors = {
    AppThemeColor.deepPurple: Color(0xFF673AB7),
    AppThemeColor.blueGrey: Color.fromARGB(255, 41, 60, 70),
    AppThemeColor.teal: Color(0xFF009688),
    AppThemeColor.pink: Color(0xFFE91E63),
    AppThemeColor.red: Color(0xFFD32F2F),
    AppThemeColor.amber: Color(0xFFFFC107),
    AppThemeColor.indigo: Color(0xFF3F51B5),
    AppThemeColor.green: Color(0xFF06C149),
    AppThemeColor.blue: Color(0xFF007197),
  };

  static const Map<AppThemeColor, LinearGradient> themeGradients = {
    AppThemeColor.deepPurple: purpleGradient,
    AppThemeColor.blueGrey: backgroundGradient,
    AppThemeColor.pink: pinkGradient,
    AppThemeColor.teal: tealGradient,
    AppThemeColor.amber: yellowGradient,
    AppThemeColor.green: greenGradient,
    AppThemeColor.blue: blueGradient,
    AppThemeColor.indigo: purpleGradient,
    AppThemeColor.red: redGradient,
  };

  static AppThemeColor getThemeColorByName(String enumName) {
    return switch (enumName) {
      'deepPurple' => AppThemeColor.deepPurple,
      'teal' => AppThemeColor.teal,
      'amber' => AppThemeColor.amber,
      'indigo' => AppThemeColor.indigo,
      'blueGrey' => AppThemeColor.blueGrey,
      'green' => AppThemeColor.green,
      'pink' => AppThemeColor.pink,
      _ => AppThemeColor.green
    };
  }
}
