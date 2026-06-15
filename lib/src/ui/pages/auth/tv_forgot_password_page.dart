import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fndtv/src/bloc/bloc.dart';
import 'package:fndtv/src/ui/pages/auth/widgets/widgets.dart';
import 'package:ui_kit/ui_kit.dart';

class TvForgotPasswordPage extends StatelessWidget {
  const TvForgotPasswordPage({
    super.key,
  });

  static const path = '/forgot-password';
  static const name = 'forgot-password';

  @override
  Widget build(BuildContext context) {
    return BlocListener<ForgotPasswordCubit, AuthState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: _listener,
      child: TvAuthScaffold(
        pageTitle: 'Forgot Password',
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
          'We have sent a password reset link to your email',
        );

        ctx.pop();

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
    return state.hasFormError ? state.formError! : 'Failed to send reset email';
  }
}

class _Form extends StatefulWidget {
  const _Form();

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
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
                'Enter your email address',
                style: TextStyles.bodyLargeBold.surface(context),
              ),
              Margins.vertical16,
              _TvForgotPasswordKeyboard(),
              Margins.vertical10,
              Row(
                children: [
                  Expanded(
                    child: AppButton.secondary(
                      onPressed: () => context.pop(),
                      label: 'Back',
                    ),
                  ),
                  Margins.horizontal10,
                  Expanded(
                    child: AppButton.primary(
                      onPressed: _onSubmit,
                      label: 'Submit',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                BlocBuilder<ForgotPasswordCubit, AuthState>(
                  buildWhen: (prev, curr) => prev.email.value != curr.email.value,
                  builder: (context, state) {
                    return ActiveInputBorder(
                      isActive: true,
                      child: AppInput.email(
                        isDeviceTv: context.isTv,
                        value: state.email.value,
                        hintText: 'Enter your email',
                        onChanged: context.read<ForgotPasswordCubit>().onEmailChanged,
                        prefixIcon: Assets.mail,
                        textInputAction: TextInputAction.done,
                        fieldError: state.email.error,
                        onFieldSubmitted: (_) => _onSubmit(),
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

  void _onSubmit() {
    context.read<ForgotPasswordCubit>().onSubmit();
  }
}

class _TvForgotPasswordKeyboard extends StatelessWidget {
  const _TvForgotPasswordKeyboard();

  @override
  Widget build(BuildContext context) {
    return AppKeyboard.email(
      onChanged: (value) {
        _handleEmailChange(context, value);
      },
      onDeleted: () {
        _handleEmailDelete(context);
      },
    );
  }

  void _handleEmailChange(BuildContext context, String key) {
    final email = context.read<ForgotPasswordCubit>().state.email.value;

    final newEmail = email == null ? key : email + key;

    context.read<ForgotPasswordCubit>().onEmailChanged(newEmail);
  }

  void _handleEmailDelete(BuildContext context) {
    final String email = context.read<ForgotPasswordCubit>().state.email.value ?? '';

    if (email.isEmpty) return;

    context.read<ForgotPasswordCubit>().onEmailChanged(email.subtractFromString());
  }
}
