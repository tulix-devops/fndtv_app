import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ui_kit/ui_kit.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeState(themeMode: AppThemeMode.blue));

  void setTheme(AppThemeMode mode) {
    emit(ThemeState(themeMode: mode));
  }

  UiKitColors get currentColors {
    switch (state.themeMode) {
      case AppThemeMode.blue:
        return UiKitColors.blue;
      case AppThemeMode.dark:
        return UiKitColors.dark;
    }
  }
}

enum AppThemeMode {
  blue,
  dark,
}
