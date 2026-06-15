import 'package:flutter/widgets.dart';

abstract interface class LocalizationRepository {
  Future<Locale> getLocale();
  Future<void> setLocale(String locale);
}
