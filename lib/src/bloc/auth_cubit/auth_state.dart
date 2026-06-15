part of 'auth_cubit.dart';

extension InputModelX on InputModel {
  bool get isValid => error == null || value == '';

  bool get isNotValid => !isValid;
}

@freezed
class AuthState with _$AuthState {
  const AuthState._();

  const factory AuthState({
    @Default((value: null, error: null)) InputModel email,
    @Default((value: null, error: null)) InputModel password,
    @Default((value: null, error: null)) InputModel repeatPassword,
    @Default(FormStatus.initial) FormStatus status,
    @Default(null) String? formError,
  }) = _AuthState;

  bool get isLoginFormValid => email.isValid && password.isValid;

  bool get isSignUpFormValid =>
      email.isValid && password.isValid && repeatPassword.isValid;

  bool get isValidating => status == FormStatus.inProgress;

  bool get hasFormError => formError != null && formError!.isNotEmpty;

  String errorsToString(List<ValidationErrorModel> errors) =>
      errors.map((e) => e.errors).expand((i) => i).join('\n');
}
