import 'package:app_localization/app_localization.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/core/core.dart';

import 'package:fndtv/src/bloc/bloc.dart';
import 'package:fndtv/src/ui/app_view.dart';
import 'package:fndtv/src/ui/pages/auth/widgets/widgets.dart';
import 'package:fndtv/src/ui/pages/pages.dart';
import 'package:ui_kit/ui_kit.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  static const path = '/sign-up';
  static const name = 'sign-up';

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignUpCubit, AuthState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: _listener,
      child: AuthScaffold(
        pageTitle: context.l.signUpPageTitle,
        submitWidget: (
          label: context.l.signUpButtonLabel,
          onPressed: () => _onSubmit(context),
        ),
        authActionWidget: const _AuthActionButton(),
        child: const _Form(),
      ),
    );
  }

  void _listener(BuildContext ctx, AuthState state) {
    final NotificationBannerCubit cubit = ctx.read<NotificationBannerCubit>();

    switch (state.status) {
      case FormStatus.inProgress:
        ctx.read<AppCubit>().showOverlay();
      case FormStatus.success:
        ctx.read<AppCubit>().hideOverlay();

        cubit.showNotification(NotificationType.success, ctx.l.loginSuccess);

        ctx.pushReplacementNamed(AppView.path);

      case FormStatus.failure:
        ctx.read<AppCubit>().hideOverlay();

        cubit.showNotification(NotificationType.error, _getError(ctx, state));

      default:
        null;
    }
  }

  String _getError(BuildContext context, AuthState state) {
    return state.hasFormError ? state.formError! : context.l.loginError;
  }
}

class _Form extends StatelessWidget {
  const _Form();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocSelector<SignUpCubit, AuthState, String?>(
          selector: (s) => s.email.error,
          builder: (context, fieldError) {
            return AppInput.email(
              isDeviceTv: context.isTv,
              hintText: 'Enter your email',
              onChanged: context.read<SignUpCubit>().onEmailChanged,
              prefixIcon: Assets.mail,
              textInputAction: TextInputAction.next,
              fieldError: fieldError,
            );
          },
        ),
        Margins.vertical16,
        BlocSelector<SignUpCubit, AuthState, String?>(
          selector: (state) => state.password.error,
          builder: (context, fieldError) {
            return AppInput.password(
              isDeviceTv: context.isTv,
              hintText: 'Enter Your password',
              onChanged: context.read<SignUpCubit>().onPasswordChanged,
              prefixIcon: Assets.password,
              textInputAction: TextInputAction.next,
              fieldError: fieldError,
            );
          },
        ),
        Margins.vertical16,
        BlocSelector<SignUpCubit, AuthState, String?>(
          selector: (state) => state.repeatPassword.error,
          builder: (context, fieldError) {
            return AppInput.password(
              isDeviceTv: context.isTv,
              hintText: 'Repeat password',
              onChanged: context.read<SignUpCubit>().onRepeatPasswordChanged,
              prefixIcon: Assets.password,
              textInputAction: TextInputAction.done,
              fieldError: fieldError,
              onFieldSubmitted: (_) => _onSubmit(context),
            );
          },
        ),
      ],
    );
  }
}

class _AuthActionButton extends StatelessWidget {
  const _AuthActionButton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Margins.vertical10,
        const AuthDivider(label: 'Already have an account?'),
        Margins.vertical10,
        SizedBox(
          width: double.infinity,
          child: AppButton.secondaryRounded(
            label: 'Sign in',
            onPressed: () => context.pushReplacementNamed(LoginPage.name),
            textColor: context.uiColors.onSurface,
          ),
        ),
      ],
    );
  }
}

// This Function is library scoped for both widgets
void _onSubmit(BuildContext context) async {
  final String deviceInfo = await context.read<DeviceModelService>().deviceModel;

  if (!context.mounted) return;

  context.read<SignUpCubit>().onSubmit(deviceInfo);
}
