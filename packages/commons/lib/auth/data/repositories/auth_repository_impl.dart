import 'dart:async';

import 'package:commons/commons.dart';

final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required LocalAuthDataSource localAuthDataSource,
    required RemoteAuthDataSource remoteAuthDataSource,
  })  : _localAuthDataSource = localAuthDataSource,
        _remoteAuthDataSource = remoteAuthDataSource;

  final LocalAuthDataSource _localAuthDataSource;
  final RemoteAuthDataSource _remoteAuthDataSource;

  final _controller = StreamController<AuthStatus>();

  @override
  Stream<AuthStatus> get status async* {
    final String? token = await getToken();

    if (token != null) {
      yield AuthStatus.authenticated;
    } else {
      yield AuthStatus.unauthenticated;
    }

    yield* _controller.stream;
  }

  @override
  Future<String?> getToken() => _localAuthDataSource.getToken();

  @override
  Future<void> storeToken({required String value}) {
    _localAuthDataSource.storeToken(value);

    /// Emit the new status for authStatus listeners
    _controller.add(AuthStatus.authenticated);

    return Future.value();
  }

  @override
  Future<void> deleteToken() {
    _localAuthDataSource.deleteToken();

    _controller.add(AuthStatus.unauthenticated);

    return Future.value();
  }

  @override
  Future<ResponseModel<bool>> logout(LogoutParams params) => _remoteAuthDataSource.logout(params);

  @override
  Future<ResponseModel<LoginEntity>> login(LoginParams params) => _remoteAuthDataSource.login(params);

  @override
  Future<ResponseModel<SignUpEntity>> signUp(SignUpParams params) => _remoteAuthDataSource.signUp(params);

  @override
  Future<ResponseModel<LoginEntity>> loginWithBiometrics(
    LoginWithBiometricsParams params,
  ) =>
      _remoteAuthDataSource.loginWithBiometrics(params);

  @override
  Future<ResponseModel<bool>> forgotPassword(ForgotPasswordParams params) =>
      _remoteAuthDataSource.forgotPassword(params);
}
