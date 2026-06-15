import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fndtv/src/bloc/bloc.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:fndtv/src/core/core.dart';

/// [OverlayStack] provides a way to show a
/// notification banner and a loading overlay on top of the app.
class OverlayStack extends StatelessWidget {
  const OverlayStack({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        const _NotificationOverlay(),
        const _LoadingOverlay(),
        const _ThemeSwitchOverlay(),
      ],
    );
  }
}

/// [_NotificationOverlay] listens to the [NotificationBannerCubit] to show or hide the notification banner.
class _NotificationOverlay extends StatefulWidget {
  const _NotificationOverlay();

  @override
  State<_NotificationOverlay> createState() => __NotificationOverlayState();
}

class __NotificationOverlayState extends State<_NotificationOverlay> {
  var _isNotificationVisible = false;
  var _shouldToggleOnEnd = false;
  var _isNotificationBannerVisible = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationBannerCubit, NotificationBannerState>(
      listener: _listener,
      builder: (context, state) {
        return AnimatedPositioned(
          top: _isNotificationVisible ? 0 : -100,
          left: 0,
          right: 0,
          curve: Curves.easeInOut,
          duration: Durations.long2,
          onEnd: _onEnd,
          child: Visibility(
            visible: _isNotificationBannerVisible,
            child: NotificationBanner(
              state.message,
              state.type,
              onDismissed: () {
                context.read<NotificationBannerCubit>().hideNotification(
                      shouldHideImmediately: true,
                    );
              },
            ),
          ),
        );
      },
    );
  }

  void _listener(BuildContext context, NotificationBannerState state) {
    final bool isNotificationVisible = state.isNotificationVisible;

    if (_isNotificationVisible == isNotificationVisible) return;

    if (state.shouldHideImmediately) {
      _hideNotificationBanner();
      return;
    }

    if (isNotificationVisible) {
      Future.delayed(
        NotificationType.defaultDuration,
        context.read<NotificationBannerCubit>().hideNotification,
      );
    }

    _onVisibilityChange(isNotificationVisible);
  }

  void _onEnd() {
    if (!_shouldToggleOnEnd) return;
    _hideNotificationBanner();
  }

  void _hideNotificationBanner() {
    setState(() {
      _isNotificationBannerVisible = false;
    });
  }

  void _onVisibilityChange(bool isNotificationVisible) {
    setState(() {
      _isNotificationVisible = isNotificationVisible;
      _shouldToggleOnEnd = !_isNotificationVisible;

      if (_isNotificationVisible) {
        _isNotificationBannerVisible = true;
      }
    });
  }
}

/// [_LoadingOverlay] listens to the [AppCubit] to show or hide the loading overlay.
class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AppCubit, AppState, bool>(
      selector: (state) {
        return state.hasOverlay;
      },
      builder: (context, hasOverlay) {
        return hasOverlay
            ? ColoredBox(
                color: AppColors.overlaySurfaceWithOpacity,
                child: const AppLoadingIndicator(size: 60),
              )
            : const SizedBox.shrink();
      },
    );
  }
}

/// [_ThemeSwitchOverlay] listens to the [AppCubit] to show or hide the ThemeSwitch overlay.
class _ThemeSwitchOverlay extends StatelessWidget {
  const _ThemeSwitchOverlay();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AppCubit, AppState, ThemeStatus>(
      selector: (state) {
        return state.themeStatus;
      },
      builder: (context, themeStatus) {
        return themeStatus == ThemeStatus.switching
            ? ColoredBox(
                color: context.isTv
                    ? context.uiColors.tvSurface
                    : context.uiColors.surface,
                child: const AppLoadingIndicator(size: 100),
              )
            : const SizedBox.shrink();
      },
    );
  }
}
