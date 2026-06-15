class LogoutParams {
  LogoutParams({
    required this.token,
  });

  final String token;

  Map<String, dynamic> toJson() {
    return {
      'token': token,
    };
  }
}

class LoginParams {
  LoginParams({
    required this.email,
    required this.password,
    required this.deviceInfo,
  });

  final String email;
  final String password;
  final String deviceInfo;

  @override
  String toString() {
    return 'LoginParams{email: $email, password: $password, deviceInfo: $deviceInfo}';
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'deviceInfo': deviceInfo,
    };
  }
}

class SignUpParams {
  SignUpParams({
    required this.email,
    required this.password,
    required this.repeatPassword,
    required this.deviceInfo,
  });

  final String email;
  final String password;
  final String repeatPassword;
  final String deviceInfo;

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'repeatPassword': repeatPassword,
      'deviceInfo': deviceInfo,
    };
  }
}

class LoginWithBiometricsParams {
  final String identity;
  final String password;
  final String deviceInfo;

  LoginWithBiometricsParams({
    required this.identity,
    required this.password,
    required this.deviceInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'identity': identity,
      'password': password,
      'deviceInfo': deviceInfo,
    };
  }
}

class ForgotPasswordParams {
  ForgotPasswordParams({
    required this.email,
  });

  final String email;

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}
