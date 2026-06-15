import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/bloc/bloc.dart';
import 'package:ui_kit/ui_kit.dart';

/// [UiOverlayProvider] is a [StatefulWidget] that provides a way to change the
/// system UI overlay colors and brightness. (status bar, nav bar)
/// It listens to the [AppCubit] to change the system UI overlay to transparent
/// when the app has an loading overlay.
class UiOverlayProvider extends StatefulWidget {
  const UiOverlayProvider({
    super.key,
    this.statusBarColor,
    this.statusBarIconBrightness,
    this.systemNavigationBarColor,
    this.systemNavigationBarIconBrightness,
    required this.child,
  });

  final Widget child;
  final Color? statusBarColor;
  final Color? systemNavigationBarColor;
  final Brightness? statusBarIconBrightness;
  final Brightness? systemNavigationBarIconBrightness;

  @override
  State<UiOverlayProvider> createState() => _UiOverlayProviderState();
}

class _UiOverlayProviderState extends State<UiOverlayProvider> {
  late Color _statusBarColor = widget.statusBarColor ?? _getStatusBarColor();
  late Color _systemNavigationBarColor =
      widget.systemNavigationBarColor ?? _getColor();

  late Brightness _statusBarIconBrightness =
      widget.statusBarIconBrightness ?? _getMode();

  late Brightness _systemNavigationBarIconBrightness =
      widget.systemNavigationBarIconBrightness ?? _getMode();

  Color _getColor() {
    // return context.isDarkMode ? AppColors.dark3 : Colors.white;
    return context.isDarkMode
        ? const Color.fromRGBO(24, 26, 32, 0.85)
        : const Color.fromRGBO(24, 26, 32, 0.85);
  }

  Color _getStatusBarColor() {
    return Colors.transparent;
  }

  Brightness _getMode() {
    return context.isDarkMode ? Brightness.light : Brightness.dark;
  }

  void _updateColors() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: _statusBarColor,
        statusBarIconBrightness: _statusBarIconBrightness,
        systemNavigationBarColor: _systemNavigationBarColor,
        systemNavigationBarIconBrightness: _systemNavigationBarIconBrightness,
      ),
    );

    Future.microtask(() {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarIconBrightness: _statusBarIconBrightness,
          systemNavigationBarIconBrightness: _systemNavigationBarIconBrightness,
          statusBarColor: _statusBarColor,
          systemNavigationBarColor: _systemNavigationBarColor,
        ),
      );
    });
  }

  void _setTransparency() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _statusBarIconBrightness,
        systemNavigationBarColor: Color.alphaBlend(
          AppColors.overlaySurfaceWithOpacity,
          _systemNavigationBarColor,
        ),
        systemNavigationBarIconBrightness: _systemNavigationBarIconBrightness,
      ),
    );
  }

  void _setVariables() {
    _statusBarColor = widget.statusBarColor ?? _getStatusBarColor();
    _systemNavigationBarColor = widget.systemNavigationBarColor ?? _getColor();

    _statusBarIconBrightness = widget.statusBarIconBrightness ?? _getMode();

    _systemNavigationBarIconBrightness =
        widget.systemNavigationBarIconBrightness ?? _getMode();
  }

  @override
  void didChangeDependencies() {
    _setVariables();

    _updateColors();

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppCubit, AppState>(
      listenWhen: (previous, current) =>
          previous.hasOverlay != current.hasOverlay,
      listener: (context, state) {
        final bool hasOverlay = state.hasOverlay;

        if (!hasOverlay) {
          return _updateColors();
        }

        _setTransparency();
      },
      child: widget.child,
    );
  }
}
