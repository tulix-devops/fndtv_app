// Custom InheritedWidget to provide UiColors based on platform brightness
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class UiColorProvider extends InheritedWidget {
  final UiColors uiColors;
  final UiKitColors uiKitColors;

  const UiColorProvider({
    super.key,
    required this.uiColors,
    required this.uiKitColors,
    required super.child,
  });

  static UiColorProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<UiColorProvider>();
  }

  @override
  bool updateShouldNotify(covariant UiColorProvider oldWidget) {
    return uiColors != oldWidget.uiColors || 
           uiKitColors != oldWidget.uiKitColors;
  }
}

// Widget that listens to platform brightness and provides appropriate colors
class ThemeColorListener extends StatefulWidget {
  final Widget child;
  final UiKitColors? initialTheme;

  const ThemeColorListener({
    super.key,
    required this.child,
    this.initialTheme,
  });

  @override
  State<ThemeColorListener> createState() => ThemeColorListenerState();
}

class ThemeColorListenerState extends State<ThemeColorListener> {
  late DarkUiColors _darkUiColors;
  late UiKitColors _uiKitColors;

  @override
  void initState() {
    super.initState();
    _darkUiColors = const DarkUiColors(AppThemeColor.red);
    _uiKitColors = widget.initialTheme ?? UiKitColors.blue;
  }

  @override
  void didUpdateWidget(ThemeColorListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTheme != null && widget.initialTheme != oldWidget.initialTheme) {
      _uiKitColors = widget.initialTheme!;
    }
  }

  void updateTheme(UiKitColors newTheme) {
    if (mounted) {
      setState(() {
        _uiKitColors = newTheme;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return UiColorProvider(
      uiColors: _darkUiColors,
      uiKitColors: _uiKitColors,
      child: widget.child,
    );
  }
}

extension UiColorProviderExtension on BuildContext {
  UiColors get uiColors {
    final UiColorProvider? provider = UiColorProvider.of(this);

    assert(provider != null, 'No UiColorProvider found in context');

    return provider!.uiColors;
  }

  /// Access the new UiKit color tokens
  UiKitColors get uiKitColors {
    final UiColorProvider? provider = UiColorProvider.of(this);

    assert(provider != null, 'No UiColorProvider found in context');

    return provider!.uiKitColors;
  }
}
