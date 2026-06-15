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

class TvLoginPage extends StatelessWidget {
  const TvLoginPage({
    super.key,
  });

  static const path = '/login';
  static const name = 'login';

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginCubit, AuthState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: _listener,
      child: TvAuthScaffold(
        pageTitle: 'Login',
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
  LoginInputFocus _currentInput = LoginInputFocus.email;

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
              TvLoginPageKeyboard(currentInput: _currentInput),
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
                BlocBuilder<LoginCubit, AuthState>(
                  buildWhen: (prev, curr) => prev.email.value != curr.email.value,
                  builder: (context, state) {
                    return ActiveInputBorder(
                      isActive: _currentInput.isEmailActive,
                      child: AppInput.email(
                        isDeviceTv: context.isTv,
                        value: state.email.value,
                        hintText: 'Enter your email',
                        onChanged: context.read<LoginCubit>().onEmailChanged,
                        prefixIcon: Assets.mail,
                        textInputAction: TextInputAction.next,
                        fieldError: state.email.error,
                      ),
                    );
                  },
                ),
                Margins.vertical16,
                BlocBuilder<LoginCubit, AuthState>(
                  buildWhen: (prev, curr) => prev.password.value != curr.password.value,
                  builder: (context, state) {
                    return ActiveInputBorder(
                      isActive: _currentInput.isPasswordActive,
                      child: AppInput.password(
                        isDeviceTv: context.isTv,
                        value: state.password.value,
                        hintText: 'Enter Your password',
                        onChanged: context.read<LoginCubit>().onPasswordChanged,
                        prefixIcon: Assets.password,
                        textInputAction: TextInputAction.done,
                        fieldError: state.password.error,
                        onFieldSubmitted: (_) => _onSubmit(context),
                      ),
                    );
                  },
                ),
                SizedBox(
                  height: 50,
                ),
                Text(
                  'Watching Live is free. Watching DVR needs a subscription.',
                  style: TextStyles.bodyMediumBold.surface(context).copyWith(color: context.uiColors.primary),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleOnNextPressed() {
    if (_currentInput.isPasswordActive) {
      _onSubmit(context);
      return;
    }

    setState(() {
      _currentInput = LoginInputFocus.password;
    });
  }

  void _handleOnBackPressed() {
    if (_currentInput.isEmailActive) return;

    setState(() {
      _currentInput = LoginInputFocus.email;
    });
  }

  String _getSubmitBtnText() {
    return _currentInput.isPasswordActive ? 'Login' : 'Next';
  }

  String _getHelperText() {
    return _currentInput.isPasswordActive ? 'Enter your password' : 'Enter your email';
  }
}

class _AuthAction extends StatelessWidget {
  const _AuthAction();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Margins.horizontal10,
        AppTextButton(
          onPressed: () => context.pushNamed(TvForgotPasswordPage.path),
          label: 'Forgot Password?',
          style: TextStyles.bodyMediumSemiBold.primary(context),
        ),
      ],
    );
  }
}

// This Function is library scoped for both widgets
void _onSubmit(BuildContext context) async {
  final String deviceInfo = await context.read<DeviceModelService>().deviceModel;

  if (!context.mounted) return;

  context.read<LoginCubit>().onSubmit(deviceInfo);
  // context.pop();
}
