import 'package:flutter/widgets.dart';

/// Navigator observer exposing the current route name — used by the identity
/// badge to hide itself over fullscreen video. Unnamed pushed routes (e.g.
/// TvUpdatesPage) report null, which counts as "show the badge".
class AppRouteTracker extends NavigatorObserver {
  static final ValueNotifier<String?> currentRoute = ValueNotifier<String?>(null);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      currentRoute.value = route.settings.name;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      currentRoute.value = previousRoute?.settings.name;

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      currentRoute.value = newRoute?.settings.name;
}
