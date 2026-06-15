part of 'localization_cubit.dart';

@freezed
class LocalizationState with _$LocalizationState {
  const factory LocalizationState({
    @Default(Locale(defaultLocaleKey)) Locale locale,
  }) = _LocalizationState;
}
