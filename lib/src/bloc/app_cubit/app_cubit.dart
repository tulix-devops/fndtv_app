import 'dart:async';

import 'package:commons/commons.dart';
import 'package:http/http.dart' as http;
import 'package:fndtv/src/data/models/profile/customer_info_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ignore: unused_import
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fndtv/src/data/data.dart';
import 'package:ui_kit/ui_kit.dart';

part 'app_state.dart';
part 'app_cubit.freezed.dart';

class AppCubit extends Cubit<AppState> {
  AppCubit({
    required AuthStatusUseCase authStatusUseCase,
    required LogoutUseCase logoutUseCase,
    required GetAuthTokenUseCase getAuthTokenUseCase,
  })  : _authStatusUseCase = authStatusUseCase,
        _logoutUseCase = logoutUseCase,
        _getAuthTokenUseCase = getAuthTokenUseCase,
        super(const AppState());

  // ignore: unused_field
  final AuthStatusUseCase _authStatusUseCase;

  final LogoutUseCase _logoutUseCase;

  final GetAuthTokenUseCase _getAuthTokenUseCase;

  // ignore: unused_field
  late final StreamSubscription<AuthStatus> _authStatusSubscription;

  @override
  Future<void> close() {
    _authStatusSubscription.cancel();
    return super.close();
  }

  Future<void> init() async {
    emit(state.copyWith(initializationStatus: InitializationStatus.loading));

    _authStatusSubscription = _authStatusUseCase().listen((AuthStatus status) {
      print('Auth Status: $status');
      emit(state.copyWith(authStatus: status));
    });

    emit(
      state.copyWith(initializationStatus: InitializationStatus.initialized),
    );
  }

  Future<String?> getToken() async {
    return await _getAuthTokenUseCase();
  }

  void changeTab(BottomBarTab tab, {bool canPop = false}) {
    emit(state.copyWith(currentTab: tab, canPop: canPop));
  }

  /// Execute logout usecase
  void onLogout() async {
    _logoutUseCase();

    await Future.delayed(const Duration(milliseconds: 500));

    emit(state.copyWith(currentTab: BottomBarTab.television));
  }

  void showOverlay() {
    emit(state.copyWith(hasOverlay: true));
  }

  void hideOverlay() {
    emit(state.copyWith(hasOverlay: false));
  }

  void showAuthDialog() {
    hideDialog();
    emit(state.copyWith(appDialogType: AppDialogType.auth));
  }

  void showSubscribeDialog() {
    hideDialog();

    emit(state.copyWith(appDialogType: AppDialogType.subscribe));
  }

  void showPaymentDialog() {
    hideDialog();

    emit(state.copyWith(appDialogType: AppDialogType.payment));
  }

  void hideDialog() {
    emit(state.copyWith(appDialogType: AppDialogType.none));
  }
}
