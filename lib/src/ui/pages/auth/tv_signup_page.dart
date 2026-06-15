import 'package:app_localization/app_localization.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fndtv/src/bloc/bloc.dart';
import 'package:fndtv/src/core/core.dart';
import 'package:fndtv/src/ui/app_view.dart';
import 'package:fndtv/src/ui/pages/auth/widgets/widgets.dart';
import 'package:fndtv/src/ui/pages/pages.dart';
import 'package:ui_kit/ui_kit.dart';

class TvSignUpPage extends StatelessWidget {
  const TvSignUpPage({
    super.key,
  });

  static const path = '/sign-up';
  static const name = 'sign-up';

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignUpCubit, AuthState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: _listener,
      child: TvAuthScaffold(
        // pageTitle: context.l.TvSignUpPageTitle,
        pageTitle: context.l.signUpPageTitle,

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

        cubit.showNotification(
          NotificationType.success,
          ctx.l.loginSuccess,
        );
        ctx.pushReplacementNamed(AppView.path);
      // ctx.popUntil(predicate: (route) {
      //   return route.settings.name != '/sign-up' &&
      //       route.settings.name != '/login';
      // });

      case FormStatus.failure:
        ctx.read<AppCubit>().hideOverlay();

        cubit.showNotification(
          NotificationType.error,
          _getError(ctx, state),
        );

      default:
        null;
    }
  }

  String _getError(BuildContext context, AuthState state) {
    return state.hasFormError ? state.formError! : context.l.loginError;
  }
}

class _Form extends StatefulWidget {
  const _Form();

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  SignUpInputFocus _currentInput = SignUpInputFocus.email;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.dark2,
            borderRadius: BorderRadius.circular(8),
          ),
          width: MediaQuery.of(context).size.width * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getHelperText(),
                style: TextStyles.bodyLargeBold.surface(context),
              ),
              Margins.vertical16,
              TvSignupPageKeyboard(currentInput: _currentInput),
              Margins.vertical10,
              Row(
                children: [
                  Expanded(
                    child: AppButton.secondary(
                      onPressed: _handleOnBackPressed,
                      label: 'Back',
                    ),
                  ),
                  Margins.horizontal10,
                  Expanded(
                    child: AppButton.primary(
                      onPressed: _handleOnNextPressed,
                      label: _getSubmitBtnText(),
                    ),
                  ),
                ],
              ),
              const _AuthAction(),
            ],
          ),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                BlocBuilder<SignUpCubit, AuthState>(
                  buildWhen: (prev, curr) =>
                      prev.email.value != curr.email.value,
                  builder: (context, state) {
                    return ActiveInputBorder(
                      isActive: _currentInput.isEmailActive,
                      child: AppInput.email(
                        isDeviceTv: context.isTv,
                        value: state.email.value,
                        hintText: 'Enter your email',
                        onChanged: context.read<SignUpCubit>().onEmailChanged,
                        prefixIcon: Assets.mail,
                        textInputAction: TextInputAction.next,
                        fieldError: state.email.error,
                      ),
                    );
                  },
                ),
                Margins.vertical16,
                BlocBuilder<SignUpCubit, AuthState>(
                  buildWhen: (prev, curr) =>
                      prev.password.value != curr.password.value,
                  builder: (context, state) {
                    return ActiveInputBorder(
                      isActive: _currentInput.isPasswordActive,
                      child: AppInput.password(
                        isDeviceTv: context.isTv,
                        value: state.password.value,
                        hintText: 'Enter Your password',
                        onChanged:
                            context.read<SignUpCubit>().onPasswordChanged,
                        prefixIcon: Assets.password,
                        textInputAction: TextInputAction.done,
                        fieldError: state.password.error,
                        onFieldSubmitted: (_) => _onSubmit(context),
                      ),
                    );
                  },
                ),
                Margins.vertical16,
                BlocBuilder<SignUpCubit, AuthState>(
                  buildWhen: (prev, curr) =>
                      prev.repeatPassword.value != curr.repeatPassword.value,
                  builder: (context, state) {
                    return ActiveInputBorder(
                      isActive: _currentInput.isRepeatPasswordActive,
                      child: AppInput.password(
                        isDeviceTv: context.isTv,
                        value: state.repeatPassword.value,
                        hintText: 'Repeat password',
                        onChanged:
                            context.read<SignUpCubit>().onRepeatPasswordChanged,
                        prefixIcon: Assets.password,
                        textInputAction: TextInputAction.done,
                        fieldError: state.repeatPassword.error,
                        onFieldSubmitted: (_) => _onSubmit(context),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleOnNextPressed() {
    if (_currentInput.isRepeatPasswordActive) {
      _onSubmit(context);
    } else {
      setState(() {
        _currentInput = switch (_currentInput) {
          SignUpInputFocus.email => SignUpInputFocus.password,
          SignUpInputFocus.password => SignUpInputFocus.repeatPassword,
          // ignores
          SignUpInputFocus.repeatPassword => SignUpInputFocus.repeatPassword,
        };
      });
    }
  }

  void _handleOnBackPressed() {
    if (_currentInput.isEmailActive) return;

    setState(() {
      _currentInput = switch (_currentInput) {
        SignUpInputFocus.email => SignUpInputFocus.email,
        SignUpInputFocus.password => SignUpInputFocus.email,
        SignUpInputFocus.repeatPassword => SignUpInputFocus.password,
      };
    });
  }

  String _getSubmitBtnText() {
    return _currentInput.isRepeatPasswordActive ? 'Sign up' : 'Next';
  }

  String _getHelperText() {
    return switch (_currentInput) {
      SignUpInputFocus.email => 'Enter your email',
      SignUpInputFocus.password => 'Enter your password',
      SignUpInputFocus.repeatPassword => 'Repeat your password',
    };
  }
}

class _AuthAction extends StatelessWidget {
  const _AuthAction();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account?',
              style: context.isDarkMode
                  ? TextStyles.bodyXLargeRegular.white
                  : TextStyles.bodyXLargeRegular.grey,
            ),
            Margins.horizontal10,
            AppTextButton(
              onPressed: () => context.pushReplacementNamed(LoginPage.path),
              label: 'Sign in',
              style: TextStyles.bodyMediumSemiBold.primary(context),
            ),
          ],
        ),
      ],
    );
  }
}

// This Function is library scoped for both widgets
void _onSubmit(BuildContext context) async {
  final String deviceInfo =
      await context.read<DeviceModelService>().deviceModel;

  if (!context.mounted) return;

  context.read<SignUpCubit>().onSubmit(deviceInfo);
  // context.pop();
}
