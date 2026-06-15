import 'package:commons/commons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ignore: unused_import
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.dart';

part 'auth_cubit.freezed.dart';

/// Auth Form mixin is for login and sign up forms because it uses the same business logic
/// TEntity is for Response entity type and TParams is for request parameter type
//
mixin AuthFormMixin on Cubit<AuthState> {
  void onEmailChanged(String value) {
    emit(state.copyWith(
      email: (
        value: value,
        error: _validateEmail(value),
      ),
    ));
  }

  void onPasswordChanged(String value) {
    emit(
      state.copyWith(
        password: (
          value: value,
          error: _validatePassword(value),
        ),
      ),
    );
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) return null;

    final RegExp emailRegex =
        RegExp(r'^[\w-]+(\.[\w-]+)*@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*(\.[a-zA-Z]{2,})$', caseSensitive: false);

    return !emailRegex.hasMatch(value) ? 'Invalid email' : null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return null;

    return value.length < 4 ? 'Type more than 4 characters' : null;
  }
}

class LoginCubit extends Cubit<AuthState> with AuthFormMixin {
  LoginCubit(LoginUseCase loginUseCase)
      : _loginUseCase = loginUseCase,
        super(const AuthState());

  final LoginUseCase _loginUseCase;

  void onSubmit(String deviceInfo) async {
    if (!state.isLoginFormValid) {
      emit(state.copyWith(status: FormStatus.failure));
      return;
    }
    if (state.email.value == null || state.password.value == null) {
      emit(state.copyWith(status: FormStatus.failure));
      return;
    }

    final String email = state.email.value!;
    final String password = state.password.value!;

    final LoginParams parameters = LoginParams(
      email: email,
      password: password,
      deviceInfo: deviceInfo,
    );

    emit(state.copyWith(status: FormStatus.inProgress));

    _handleRequest(parameters);
  }

  void _handleRequest(LoginParams params) async {
    final ResponseModel<LoginEntity> response = await _loginUseCase(params);
    print(response);
    (switch (response) {
      SuccessModel<LoginEntity>() => emit(
          state.copyWith(
            status: FormStatus.success,
          ),
        ),
      AuthenticationFailureModel<LoginEntity>() => emit(
          state.copyWith(
            status: FormStatus.failure,
            formError: response.message,
          ),
        ),
      ValidationFailureModel<LoginEntity>() => emit(
          state.copyWith(
            status: FormStatus.failure,
            formError: state.errorsToString(response.validationErrors),
          ),
        ),
      _ => {
          print('we are failed'),
          emit(
            state.copyWith(status: FormStatus.failure),
          )
        },
    });
  }
}

class SignUpCubit extends Cubit<AuthState> with AuthFormMixin {
  SignUpCubit(SignUpUseCase signUpUseCase)
      : _signUpUseCase = signUpUseCase,
        super(const AuthState());

  final SignUpUseCase _signUpUseCase;

  void onSubmit(String deviceInfo) async {
    if (!state.isSignUpFormValid) return;

    final String email = state.email.value!;
    final String password = state.password.value!;
    final String repeatPassword = state.repeatPassword.value!;

    final SignUpParams parameters = SignUpParams(
      email: email,
      password: password,
      deviceInfo: deviceInfo,
      repeatPassword: repeatPassword,
    );

    emit(state.copyWith(status: FormStatus.inProgress));

    _handleRequest(parameters);
  }

  void _handleRequest(SignUpParams params) async {
    final ResponseModel<SignUpEntity> response = await _signUpUseCase(params);

    print(response);

    (switch (response) {
      SuccessModel<SignUpEntity>() => emit(
          state.copyWith(
            status: FormStatus.success,
          ),
        ),
      AuthenticationFailureModel<SignUpEntity>() => emit(
          state.copyWith(
            status: FormStatus.failure,
            formError: response.message,
          ),
        ),
      FailureModel<SignUpEntity>() => () {
          print(response.message);
          emit(
            state.copyWith(
              status: FormStatus.failure,
              formError: response.message,
            ),
          );
        }(),
      ValidationFailureModel<SignUpEntity>() => () {
          print(response.message);
          emit(
            state.copyWith(
              status: FormStatus.failure,
              formError: state.errorsToString(response.validationErrors),
            ),
          );
        }(),
      _ => emit(
          state.copyWith(status: FormStatus.failure),
        ),
    });
  }

  @override
  void onPasswordChanged(String value) {
    emit(state.copyWith(password: (value: value, error: _validatePassword(value))));

    if (state.repeatPassword.value == null) return;

    onRepeatPasswordChanged(state.repeatPassword.value!);
  }

  void onRepeatPasswordChanged(String value) {
    emit(
      state.copyWith(
        repeatPassword: (
          value: value,
          error: _validateRepeatPassword(value),
        ),
      ),
    );
  }

  String? _validateRepeatPassword(String value) {
    if (value.isEmpty) return null;

    if (value != state.password.value) return 'Passwords do not match';

    return value.length < 4 ? 'Type more than 4 characters' : null;
  }
}

class ForgotPasswordCubit extends Cubit<AuthState> with AuthFormMixin {
  ForgotPasswordCubit(ForgotPasswordUseCase forgotPasswordUseCase)
      : _forgotPasswordUseCase = forgotPasswordUseCase,
        super(const AuthState());

  final ForgotPasswordUseCase _forgotPasswordUseCase;

  void onSubmit() async {
    if (state.email.value == null || state.email.error != null) {
      emit(state.copyWith(status: FormStatus.failure));
      return;
    }

    final String email = state.email.value!;

    final ForgotPasswordParams parameters = ForgotPasswordParams(
      email: email,
    );

    emit(state.copyWith(status: FormStatus.inProgress));

    _handleRequest(parameters);
  }

  void _handleRequest(ForgotPasswordParams params) async {
    final ResponseModel<bool> response = await _forgotPasswordUseCase(params);

    (switch (response) {
      SuccessModel<bool>() => emit(
          state.copyWith(
            status: FormStatus.success,
          ),
        ),
      AuthenticationFailureModel<bool>() => emit(
          state.copyWith(
            status: FormStatus.failure,
            formError: response.message,
          ),
        ),
      ValidationFailureModel<bool>() => emit(
          state.copyWith(
            status: FormStatus.failure,
            formError: state.errorsToString(response.validationErrors),
          ),
        ),
      _ => {
          print('forgot password failed'),
          emit(
            state.copyWith(status: FormStatus.failure),
          )
        },
    });
  }
}
