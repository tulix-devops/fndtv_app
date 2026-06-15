import 'package:app_localization/domain/repositories/localization_repository.dart';
import 'package:flutter/widgets.dart';

class GetLocaleUseCase {
  GetLocaleUseCase({required LocalizationRepository localizationRepository})
      : _localizationRepository = localizationRepository;
  final LocalizationRepository _localizationRepository;

  Future<Locale> call() {
    return _localizationRepository.getLocale();
  }
}

class SetLocaleUseCase {
  SetLocaleUseCase({required LocalizationRepository localizationRepository})
      : _localizationRepository = localizationRepository;
  final LocalizationRepository _localizationRepository;

  Future<void> call(String locale) {
    return _localizationRepository.setLocale(locale);
  }
}
