import 'package:commons/shared/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/bloc/app_cubit/app_cubit.dart';
import 'package:ui_kit/ui_kit.dart';

class DvrUnavailablePage extends StatelessWidget {
  const DvrUnavailablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: FocusNode(),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              Assets.dvrNotFound,
              width: 240,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            Text(
              'DVR not available',
              style: TextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.read<AppCubit>().state.authStatus == AuthStatus.unauthenticated
                  ? 'Log in to access DVR content.'
                  : 'Add a payment method to access DVR content.',
              style: TextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
