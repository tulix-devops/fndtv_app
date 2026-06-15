import 'dart:convert';

import 'package:commons/commons.dart';

class RemoteAuthDataSource with ApiCallHandler {
  RemoteAuthDataSource(this._client);

  final CustomHTTPClient _client;

  Future<ResponseModel<LoginEntity>> login(LoginParams params) {
    return handleApiCall<LoginEntity>(
      url: APIList.login,
      httpMethod: HttpMethod.post,
      body: jsonEncode(params.toJson()),
      dataMapper: LoginEntity.fromJson,
      client: _client,
    );
  }

  Future<ResponseModel<bool>> forgotPassword(ForgotPasswordParams params) {
    return handleApiCall<bool>(
      url: APIList.forgotPassword,
      httpMethod: HttpMethod.post,
      body: jsonEncode(params.toJson()),
      dataMapper: (p0) => true,
      client: _client,
    );
  }

  Future<ResponseModel<SignUpEntity>> signUp(SignUpParams params) {
    return handleApiCall<SignUpEntity>(
      url: APIList.signUp,
      httpMethod: HttpMethod.post,
      body: jsonEncode(params.toJson()),
      dataMapper: SignUpEntity.fromJson,
      client: _client,
    );
  }

  Future<ResponseModel<bool>> logout(LogoutParams params) {
    return handleApiCall<bool>(
      url: APIList.logout,
      httpMethod: HttpMethod.post,
      body: jsonEncode(params.toJson()),
      client: _client,
    );
  }

  Future<ResponseModel<LoginEntity>> loginWithBiometrics(LoginWithBiometricsParams params) {
    return handleApiCall<LoginEntity>(
      url: APIList.loginWithBiometrics,
      httpMethod: HttpMethod.post,
      body: jsonEncode(params.toJson()),
      dataMapper: LoginEntity.fromJson,
      client: _client,
    );
  }
}
