import 'package:app_localization/app_localization.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
// ignore: unused_import
import 'package:flutter/foundation.dart';

part 'localization_state.dart';
part 'localization_cubit.freezed.dart';

class LocalizationCubit extends Cubit<LocalizationState> {
  LocalizationCubit({
    required GetLocaleUseCase getLocaleUseCase,
    required SetLocaleUseCase setLocaleUseCase,
  })  : _getLocaleUseCase = getLocaleUseCase,
        _setLocaleUseCase = setLocaleUseCase,
        super(LocalizationState());

  final GetLocaleUseCase _getLocaleUseCase;
  final SetLocaleUseCase _setLocaleUseCase;

  void getLocale() async {
    emit(state.copyWith(locale: await _getLocaleUseCase()));
  }

  void setLocale(String locale) async {
    await _setLocaleUseCase(locale);
    getLocale();
  }
}
