import 'package:app_localization/app_localization.dart';
import 'package:flutter/widgets.dart';

final class LocalizationRepositoryImpl implements LocalizationRepository {
  const LocalizationRepositoryImpl(this._localizationDataSource);

  final LocalLocalizationDataSource _localizationDataSource;
  @override
  Future<Locale> getLocale() async {
    final String locale =
        (await _localizationDataSource.getLocale()) ?? defaultLocaleKey;

    return Locale(locale);
  }

  @override
  Future<void> setLocale(String locale) {
    return _localizationDataSource.setLocale(locale);
  }
}
