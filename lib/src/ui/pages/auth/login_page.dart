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

class LoginPage extends StatelessWidget {
  const LoginPage({
    super.key,
  });

  static const path = '/login';
  static const name = 'login';

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginCubit, AuthState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: _listener,
      child: AuthScaffold(
        // pageTitle: context.l.loginPageTitle,
        pageTitle: 'Login to your account',
        submitWidget: (
          label: context.l.loginButtonLabel,
          onPressed: () => _onSubmit(context),
        ),
        authActionWidget: const _AuthAction(),
        forgotPasswordWidget: AppTextButton(
          onPressed: () {},
          label: 'Forgot the password?',
          style: TextStyles.bodyLargeSemiBold.primary(context),
        ),
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

        // Navigate to AppView only after successful login

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
  final FocusNode email = FocusNode();
  final FocusNode password = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocSelector<LoginCubit, AuthState, String?>(
          selector: (s) => s.email.error,
          builder: (context, fieldError) {
            return AppInput.email(
              isDeviceTv: context.isTv,
              hintText: 'Enter your email',
              onChanged: context.read<LoginCubit>().onEmailChanged,
              prefixIcon: Assets.mail,
              textInputAction: TextInputAction.next,
              fieldError: fieldError,
            );
          },
        ),
        Margins.vertical16,
        BlocSelector<LoginCubit, AuthState, String?>(
          selector: (state) => state.password.error,
          builder: (context, fieldError) {
            return AppInput.password(
              isDeviceTv: context.isTv,
              hintText: 'Enter Your password',
              onChanged: context.read<LoginCubit>().onPasswordChanged,
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

final Iterable<({String asset, VoidCallback onPressed})> _socialButtons = [
  (asset: Assets.fb, onPressed: () {}),
  (asset: Assets.google, onPressed: () {}),
  (asset: Assets.apple, onPressed: () {}),
];

// STASH: Social Buttons
// ignore: unused_element
class _SocialButtons extends StatelessWidget {
  const _SocialButtons();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      direction: Axis.horizontal,
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 4,
      children: [
        const AuthDivider(label: 'or continue with '),
        for (final button in _socialButtons)
          AppIconButton.secondary(
            padding: const EdgeInsets.fromLTRB(32, 18, 32, 18),
            icon: (
              asset: button.asset,
              size: 24,
              color: _getColor(
                context,
                button.asset,
              )
            ),
            onPressed: button.onPressed,
          ),
      ],
    );
  }

  Color? _getColor(BuildContext context, String asset) {
    return context.isDarkMode && asset == Assets.apple ? Colors.white : null;
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
              'Don\'t have an account?',
              style: context.isDarkMode ? TextStyles.bodyMediumRegular.white : TextStyles.bodyMediumRegular.grey,
            ),
            Margins.horizontal10,
          ],
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

  // Navigation will be handled in _listener after successful login
}
