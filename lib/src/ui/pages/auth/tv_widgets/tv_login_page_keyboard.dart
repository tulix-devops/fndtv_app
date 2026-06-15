import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/bloc/bloc.dart';
import 'package:fndtv/src/core/core.dart';
import 'package:ui_kit/ui_kit.dart';

class TvLoginPageKeyboard extends StatelessWidget {
  const TvLoginPageKeyboard({super.key, required this.currentInput});

  final LoginInputFocus currentInput;

  @override
  Widget build(BuildContext context) {
    return AppKeyboard.email(
      onChanged: (value) {
        return switch (currentInput) {
          LoginInputFocus.email => _handleEmailChange(context, value),
          LoginInputFocus.password => _handlePasswordChange(context, value),
        };
      },
      onDeleted: () {
        return switch (currentInput) {
          LoginInputFocus.email => _handleEmailDelete(context),
          LoginInputFocus.password => _handlePasswordDelete(context),
        };
      },
    );
  }

  void _handleEmailChange(BuildContext context, String key) {
    final email = context.read<LoginCubit>().state.email.value;

    final newEmail = email == null ? key : email + key;

    context.read<LoginCubit>().onEmailChanged(newEmail);
  }

  void _handlePasswordChange(BuildContext context, String key) {
    final password = context.read<LoginCubit>().state.password.value;

    final newPassword = password == null ? key : password + key;

    context.read<LoginCubit>().onPasswordChanged(newPassword);
  }

  void _handleEmailDelete(BuildContext context) {
    final String email = context.read<LoginCubit>().state.email.value ?? '';

    if (email.isEmpty) return;

    context.read<LoginCubit>().onEmailChanged(email.subtractFromString());
  }

  void _handlePasswordDelete(BuildContext context) {
    final String password =
        context.read<LoginCubit>().state.password.value ?? '';

    if (password.isEmpty) return;

    context.read<LoginCubit>().onPasswordChanged(password.subtractFromString());
  }
}
