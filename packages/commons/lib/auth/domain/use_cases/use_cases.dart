import 'dart:async';

import 'package:app_logger/app_logger.dart';
import 'package:commons/commons.dart';

final class GetAuthTokenUseCase {
  GetAuthTokenUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<String?> call() => _authRepository.getToken();
}

final class StoreAuthTokenUseCase {
  StoreAuthTokenUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> call(String value) => _authRepository.storeToken(value: value);
}

final class LogoutUseCase {
  LogoutUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> call() async {
    final String? token = await _authRepository.getToken();

    unawaited(_authRepository.deleteToken());

    if (token == null) return;

    final LogoutParams params = LogoutParams(token: token);

    try {
      await _authRepository.logout(params);
    } catch (e) {
      logger.e('Network error on logout');
    }
  }
}

final class AuthStatusUseCase {
  AuthStatusUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Stream<AuthStatus> call() => _authRepository.status;
}

class LoginUseCase {
  LoginUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<ResponseModel<LoginEntity>> call(LoginParams params) async {
    final ResponseModel<LoginEntity> response = await _authRepository.login(params);

    if (response is SuccessModel<LoginEntity>) {
      await _authRepository.storeToken(value: response.data.accessToken);
    }

    return response;
  }
}

class SignUpUseCase {
  SignUpUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<ResponseModel<SignUpEntity>> call(SignUpParams params) async {
    final ResponseModel<SignUpEntity> response = await _authRepository.signUp(params);

    if (response is SuccessModel<SignUpEntity>) {
      await _authRepository.storeToken(value: response.data.accessToken);
    }

    return response;
  }
}

class LoginWithBiometricsUseCase {
  LoginWithBiometricsUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<ResponseModel<LoginEntity>> call(LoginWithBiometricsParams params) =>
      _authRepository.loginWithBiometrics(params);
}

class ForgotPasswordUseCase {
  ForgotPasswordUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<ResponseModel<bool>> call(ForgotPasswordParams params) => _authRepository.forgotPassword(params);
}
