import 'package:commons/commons.dart';

abstract class AuthRepository {
  Stream<AuthStatus> get status;
  Future<String?> getToken();
  Future<void> storeToken({required String value});
  Future<void> deleteToken();
  Future<ResponseModel<bool>> logout(LogoutParams params);
  Future<ResponseModel<LoginEntity>> login(LoginParams params);
  Future<ResponseModel<SignUpEntity>> signUp(SignUpParams params);
  Future<ResponseModel<LoginEntity>> loginWithBiometrics(
    LoginWithBiometricsParams params,
  );
  Future<ResponseModel<bool>> forgotPassword(ForgotPasswordParams params);
}
