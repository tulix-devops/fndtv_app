import 'package:flutter/widgets.dart';
import 'app_localization.dart';

extension LocalizationExtension on BuildContext {
  AppLocalizations get l => AppLocalizations.of(this);
}

const String frenchLocaleKey = 'fr';
const String englishLocalekey = 'en';
const String spanishLocaleKey = 'es';

/// FNDTV launches in French by default.
const String defaultLocaleKey = frenchLocaleKey;
