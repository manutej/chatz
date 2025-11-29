import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import '../services/analytics_service.dart';
import '../services/crashlytics_service.dart';

/// Route observer for automatic screen view tracking
/// Integrates with Flutter Navigator to log screen changes
@lazySingleton
class AnalyticsRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  final AnalyticsService _analyticsService;
  final CrashlyticsService _crashlyticsService;

  AnalyticsRouteObserver(
    this._analyticsService,
    this._crashlyticsService,
  );

  /// Extract clean screen name from route
  String _getScreenName(Route<dynamic>? route) {
    if (route?.settings.name == null) {
      return 'unknown_screen';
    }

    final name = route!.settings.name!;
    // Remove leading slash and convert to snake_case
    final cleanName = name
        .replaceAll(RegExp(r'^/'), '')
        .replaceAll('/', '_')
        .toLowerCase();

    return cleanName.isEmpty ? 'home' : cleanName;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);

    if (route is PageRoute) {
      final screenName = _getScreenName(route);
      final previousScreenName = _getScreenName(previousRoute);

      // Log to analytics
      _analyticsService.logScreenView(
        screenName: screenName,
        screenClass: route.runtimeType.toString(),
      );

      // Log to crashlytics for debugging
      _crashlyticsService.setCurrentScreen(screenName);
      _crashlyticsService.logNavigation(
        previousScreenName,
        screenName,
      );
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);

    if (newRoute is PageRoute) {
      final screenName = _getScreenName(newRoute);
      final previousScreenName = _getScreenName(oldRoute);

      // Log to analytics
      _analyticsService.logScreenView(
        screenName: screenName,
        screenClass: newRoute.runtimeType.toString(),
      );

      // Log to crashlytics for debugging
      _crashlyticsService.setCurrentScreen(screenName);
      _crashlyticsService.logNavigation(
        previousScreenName,
        screenName,
      );
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);

    if (previousRoute is PageRoute && route is PageRoute) {
      final screenName = _getScreenName(previousRoute);
      final oldScreenName = _getScreenName(route);

      // Log to analytics
      _analyticsService.logScreenView(
        screenName: screenName,
        screenClass: previousRoute.runtimeType.toString(),
      );

      // Log to crashlytics for debugging
      _crashlyticsService.setCurrentScreen(screenName);
      _crashlyticsService.logNavigation(
        oldScreenName,
        screenName,
      );
    }
  }
}
