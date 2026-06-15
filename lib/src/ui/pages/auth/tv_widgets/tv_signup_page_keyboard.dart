import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/bloc/bloc.dart';
import 'package:fndtv/src/core/core.dart';
import 'package:ui_kit/ui_kit.dart';

class TvSignupPageKeyboard extends StatelessWidget {
  const TvSignupPageKeyboard({super.key, required this.currentInput});

  final SignUpInputFocus currentInput;

  @override
  Widget build(BuildContext context) {
    return AppKeyboard.email(
      onChanged: (value) {
        return switch (currentInput) {
          SignUpInputFocus.email => _handleEmailChange(context, value),
          SignUpInputFocus.password => _handlePasswordChange(context, value),
          SignUpInputFocus.repeatPassword => _handleRepeatPasswordChange(
              context,
              value,
            ),
        };
      },
      onDeleted: () {
        return switch (currentInput) {
          SignUpInputFocus.email => _handleEmailDelete(context),
          SignUpInputFocus.password => _handlePasswordDelete(context),
          SignUpInputFocus.repeatPassword => _handleRepeatPasswordDelete(
              context,
            ),
        };
      },
    );
  }

  void _handleEmailChange(BuildContext context, String key) {
    final email = context.read<SignUpCubit>().state.email.value;

    final newEmail = email == null ? key : email + key;

    context.read<SignUpCubit>().onEmailChanged(newEmail);
  }

  void _handlePasswordChange(BuildContext context, String key) {
    final password = context.read<SignUpCubit>().state.password.value;

    final newPassword = password == null ? key : password + key;

    context.read<SignUpCubit>().onPasswordChanged(newPassword);
  }

  void _handleRepeatPasswordChange(BuildContext context, String key) {
    final password = context.read<SignUpCubit>().state.repeatPassword.value;

    final newPassword = password == null ? key : password + key;

    context.read<SignUpCubit>().onRepeatPasswordChanged(newPassword);
  }

  void _handleEmailDelete(BuildContext context) {
    final String email = context.read<SignUpCubit>().state.email.value ?? '';

    if (email.isEmpty) return;

    context.read<SignUpCubit>().onEmailChanged(email.subtractFromString());
  }

  void _handlePasswordDelete(BuildContext context) {
    final String password =
        context.read<SignUpCubit>().state.password.value ?? '';

    if (password.isEmpty) return;

    context.read<SignUpCubit>().onPasswordChanged(
          password.subtractFromString(),
        );
  }

  void _handleRepeatPasswordDelete(BuildContext context) {
    final String password =
        context.read<SignUpCubit>().state.repeatPassword.value ?? '';

    if (password.isEmpty) return;

    context.read<SignUpCubit>().onRepeatPasswordChanged(
          password.subtractFromString(),
        );
  }
}
