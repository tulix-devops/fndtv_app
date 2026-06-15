import 'package:flutter/widgets.dart';
import 'app_localization.dart';

extension LocalizationExtension on BuildContext {
  AppLocalizations get l => AppLocalizations.of(this);
}

const String georgianLocaleKey = 'ka';
const String defaultLocaleKey = georgianLocaleKey;
const String englishLocalekey = 'en';
