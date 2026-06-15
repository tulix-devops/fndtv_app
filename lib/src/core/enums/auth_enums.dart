enum LoginInputFocus {
  email,
  password,
}

extension XLoginPageInputFocus on LoginInputFocus {
  bool get isPasswordActive {
    return this == LoginInputFocus.password;
  }

  bool get isEmailActive {
    return this == LoginInputFocus.email;
  }
}

enum SignUpInputFocus {
  email,
  password,
  repeatPassword,
}

extension XSignupPageInputFocus on SignUpInputFocus {
  bool get isPasswordActive {
    return this == SignUpInputFocus.password;
  }

  bool get isEmailActive {
    return this == SignUpInputFocus.email;
  }

  bool get isRepeatPasswordActive {
    return this == SignUpInputFocus.repeatPassword;
  }
}
