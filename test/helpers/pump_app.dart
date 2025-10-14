import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatz/core/themes/app_theme.dart';

/// Extension to simplify pumping widgets with MaterialApp and ProviderScope
extension PumpApp on WidgetTester {
  /// Pump a widget wrapped in MaterialApp and ProviderScope
  ///
  /// Example:
  /// ```dart
  /// await tester.pumpApp(
  ///   LoginPage(),
  ///   overrides: [
  ///     authProvider.overrideWith((ref) => mockAuthNotifier),
  ///   ],
  /// );
  /// ```
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const [],
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: widget,
        ),
      ),
    );
  }

  /// Pump a widget with router configuration
  ///
  /// Example:
  /// ```dart
  /// await tester.pumpRouter(
  ///   overrides: [
  ///     authProvider.overrideWith((ref) => mockAuthNotifier),
  ///   ],
  /// );
  /// ```
  Future<void> pumpRouter({
    List<Override> overrides = const [],
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    // Note: Requires GoRouter configuration
    // Import app_router.dart when implementing
    throw UnimplementedError(
      'Router testing requires GoRouter setup. '
      'Import app_router.dart and implement router configuration.',
    );
  }

  /// Pump a widget and wait for all animations and async operations
  ///
  /// Example:
  /// ```dart
  /// await tester.pumpAppAndSettle(LoginPage());
  /// ```
  Future<void> pumpAppAndSettle(
    Widget widget, {
    List<Override> overrides = const [],
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await pumpApp(widget, overrides: overrides);
    await pumpAndSettle(timeout);
  }
}
