import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Service for Firebase Crashlytics integration
/// Provides crash reporting, error tracking, and debugging breadcrumbs
@lazySingleton
class CrashlyticsService {
  final FirebaseCrashlytics _crashlytics;
  final Logger _logger;

  CrashlyticsService(
    this._crashlytics,
    this._logger,
  );

  /// Initialize Crashlytics service
  /// Should be called early in app startup
  Future<void> initialize() async {
    try {
      // Enable Crashlytics collection in release mode
      // Disable in debug mode to avoid polluting crash reports
      final enabled = kReleaseMode;
      await _crashlytics.setCrashlyticsCollectionEnabled(enabled);

      // Set up Flutter error handlers
      if (enabled) {
        _setupFlutterErrorHandlers();
        _logger.i('Crashlytics: Initialized and enabled');
      } else {
        _logger.i('Crashlytics: Disabled in debug mode');
      }
    } catch (e) {
      _logger.e('Failed to initialize Crashlytics', error: e);
    }
  }

  /// Set up Flutter error handlers for automatic crash reporting
  void _setupFlutterErrorHandlers() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      _logger.e(
        'Flutter Error: ${details.exceptionAsString()}',
        error: details.exception,
        stackTrace: details.stack,
      );
    };

    // Handle errors outside Flutter framework (async errors)
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        fatal: true,
        reason: 'Uncaught platform error',
      );
      _logger.e('Platform Error', error: error, stackTrace: stack);
      return true; // Prevents error from propagating
    };
  }

  // ==================== User Identification ====================

  /// Set user identifier for crash reports
  /// Use non-PII identifiers (user IDs, not emails or names)
  Future<void> setUserIdentifier(String? userId) async {
    try {
      await _crashlytics.setUserIdentifier(userId ?? '');
      _logger.d('Crashlytics: User identifier set - ${userId != null ? 'authenticated' : 'cleared'}');
    } catch (e) {
      _logger.e('Failed to set user identifier', error: e);
    }
  }

  // ==================== Custom Keys ====================

  /// Set custom key-value pair for crash context
  /// Useful for debugging state at time of crash
  Future<void> setCustomKey(String key, dynamic value) async {
    try {
      await _crashlytics.setCustomKey(key, value);
    } catch (e) {
      _logger.e('Failed to set custom key: $key', error: e);
    }
  }

  /// Set multiple custom keys at once
  Future<void> setCustomKeys(Map<String, dynamic> keys) async {
    try {
      for (final entry in keys.entries) {
        await _crashlytics.setCustomKey(entry.key, entry.value);
      }
      _logger.d('Crashlytics: Set ${keys.length} custom keys');
    } catch (e) {
      _logger.e('Failed to set custom keys', error: e);
    }
  }

  /// Set current screen name
  Future<void> setCurrentScreen(String screenName) async {
    await setCustomKey('current_screen', screenName);
  }

  /// Set current chat context
  Future<void> setChatContext({
    required String chatId,
    String? chatType,
    int? participantCount,
  }) async {
    await setCustomKeys({
      'current_chat_id': chatId,
      if (chatType != null) 'chat_type': chatType,
      if (participantCount != null) 'chat_participant_count': participantCount,
    });
  }

  /// Set current call context
  Future<void> setCallContext({
    required String callId,
    required String callType,
    required String callStatus,
  }) async {
    await setCustomKeys({
      'current_call_id': callId,
      'call_type': callType,
      'call_status': callStatus,
    });
  }

  /// Set wallet context
  Future<void> setWalletContext({
    required double balance,
    required String currency,
  }) async {
    await setCustomKeys({
      'wallet_balance': balance,
      'wallet_currency': currency,
    });
  }

  /// Set network context
  Future<void> setNetworkContext({
    required bool isConnected,
    String? connectionType, // 'wifi', 'cellular', 'none'
  }) async {
    await setCustomKeys({
      'network_connected': isConnected,
      if (connectionType != null) 'network_type': connectionType,
    });
  }

  // ==================== Logging & Breadcrumbs ====================

  /// Log custom message (breadcrumb) for debugging
  /// Messages appear in crash reports to help trace events leading to crash
  Future<void> log(String message) async {
    try {
      await _crashlytics.log(message);
    } catch (e) {
      _logger.e('Failed to log message to Crashlytics', error: e);
    }
  }

  /// Log navigation event
  Future<void> logNavigation(String from, String to) async {
    await log('Navigation: $from -> $to');
  }

  /// Log user action
  Future<void> logUserAction(String action, {Map<String, dynamic>? params}) async {
    final paramsStr = params != null ? ' | ${params.entries.map((e) => '${e.key}=${e.value}').join(', ')}' : '';
    await log('User Action: $action$paramsStr');
  }

  /// Log API call
  Future<void> logApiCall(String method, String endpoint, {int? statusCode}) async {
    final status = statusCode != null ? ' | Status: $statusCode' : '';
    await log('API: $method $endpoint$status');
  }

  /// Log authentication event
  Future<void> logAuthEvent(String event, {String? method}) async {
    final methodStr = method != null ? ' via $method' : '';
    await log('Auth: $event$methodStr');
  }

  /// Log payment event
  Future<void> logPaymentEvent(String event, {double? amount, String? currency}) async {
    final amountStr = amount != null && currency != null ? ' | $amount $currency' : '';
    await log('Payment: $event$amountStr');
  }

  /// Log media event
  Future<void> logMediaEvent(String event, {String? mediaType, int? sizeBytes}) async {
    final details = <String>[];
    if (mediaType != null) details.add('type=$mediaType');
    if (sizeBytes != null) details.add('size=${(sizeBytes / 1024).toStringAsFixed(2)}KB');
    final detailsStr = details.isNotEmpty ? ' | ${details.join(', ')}' : '';
    await log('Media: $event$detailsStr');
  }

  // ==================== Error Recording ====================

  /// Record non-fatal error
  /// Use for caught exceptions that don't crash the app but should be tracked
  Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    Iterable<Object>? information,
    bool fatal = false,
  }) async {
    try {
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: reason,
        information: information,
        fatal: fatal,
      );
      _logger.w(
        'Crashlytics: ${fatal ? 'Fatal' : 'Non-fatal'} error recorded${reason != null ? ' - $reason' : ''}',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (e) {
      _logger.e('Failed to record error to Crashlytics', error: e);
    }
  }

  /// Record Flutter error details
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    try {
      await _crashlytics.recordFlutterFatalError(details);
      _logger.e(
        'Crashlytics: Flutter error recorded',
        error: details.exception,
        stackTrace: details.stack,
      );
    } catch (e) {
      _logger.e('Failed to record Flutter error', error: e);
    }
  }

  // ==================== Specialized Error Handlers ====================

  /// Record authentication error
  Future<void> recordAuthError(
    dynamic error,
    StackTrace? stackTrace, {
    required String method,
    String? userId,
  }) async {
    await setCustomKeys({
      'error_type': 'authentication',
      'auth_method': method,
      if (userId != null) 'user_id': userId,
    });
    await recordError(
      error,
      stackTrace,
      reason: 'Authentication error during $method',
      fatal: false,
    );
  }

  /// Record API error
  Future<void> recordApiError(
    dynamic error,
    StackTrace? stackTrace, {
    required String endpoint,
    required String method,
    int? statusCode,
  }) async {
    await setCustomKeys({
      'error_type': 'api',
      'api_endpoint': endpoint,
      'api_method': method,
      if (statusCode != null) 'api_status_code': statusCode,
    });
    await recordError(
      error,
      stackTrace,
      reason: 'API error: $method $endpoint${statusCode != null ? ' ($statusCode)' : ''}',
      fatal: false,
    );
  }

  /// Record database error
  Future<void> recordDatabaseError(
    dynamic error,
    StackTrace? stackTrace, {
    required String operation,
    String? collection,
    String? documentId,
  }) async {
    await setCustomKeys({
      'error_type': 'database',
      'db_operation': operation,
      if (collection != null) 'db_collection': collection,
      if (documentId != null) 'db_document_id': documentId,
    });
    await recordError(
      error,
      stackTrace,
      reason: 'Database error during $operation',
      fatal: false,
    );
  }

  /// Record storage error
  Future<void> recordStorageError(
    dynamic error,
    StackTrace? stackTrace, {
    required String operation,
    String? filePath,
    int? fileSize,
  }) async {
    await setCustomKeys({
      'error_type': 'storage',
      'storage_operation': operation,
      if (filePath != null) 'file_path': filePath,
      if (fileSize != null) 'file_size_bytes': fileSize,
    });
    await recordError(
      error,
      stackTrace,
      reason: 'Storage error during $operation',
      fatal: false,
    );
  }

  /// Record call error
  Future<void> recordCallError(
    dynamic error,
    StackTrace? stackTrace, {
    required String callId,
    required String callType,
    required String phase, // 'initialization', 'connection', 'ongoing', 'termination'
  }) async {
    await setCustomKeys({
      'error_type': 'call',
      'call_id': callId,
      'call_type': callType,
      'call_phase': phase,
    });
    await recordError(
      error,
      stackTrace,
      reason: 'Call error during $phase phase',
      fatal: false,
    );
  }

  /// Record payment error
  Future<void> recordPaymentError(
    dynamic error,
    StackTrace? stackTrace, {
    required String operation,
    double? amount,
    String? currency,
    String? paymentMethod,
  }) async {
    await setCustomKeys({
      'error_type': 'payment',
      'payment_operation': operation,
      if (amount != null) 'payment_amount': amount,
      if (currency != null) 'payment_currency': currency,
      if (paymentMethod != null) 'payment_method': paymentMethod,
    });
    await recordError(
      error,
      stackTrace,
      reason: 'Payment error during $operation',
      fatal: false,
    );
  }

  /// Record media error
  Future<void> recordMediaError(
    dynamic error,
    StackTrace? stackTrace, {
    required String operation,
    String? mediaType,
    String? source, // 'camera', 'gallery', 'file_picker'
  }) async {
    await setCustomKeys({
      'error_type': 'media',
      'media_operation': operation,
      if (mediaType != null) 'media_type': mediaType,
      if (source != null) 'media_source': source,
    });
    await recordError(
      error,
      stackTrace,
      reason: 'Media error during $operation',
      fatal: false,
    );
  }

  // ==================== Testing & Debugging ====================

  /// Force a crash (for testing crash reporting)
  /// WARNING: Only use in development/testing!
  Future<void> forceCrash() async {
    if (kDebugMode) {
      _logger.w('Crashlytics: Force crash called in debug mode');
      throw Exception('Test crash - This is intentional for testing Crashlytics');
    } else {
      _logger.e('Crashlytics: Force crash called in production mode!');
      await _crashlytics.crash();
    }
  }

  /// Test non-fatal error reporting
  Future<void> testNonFatalError() async {
    await recordError(
      Exception('Test non-fatal error'),
      StackTrace.current,
      reason: 'Testing Crashlytics integration',
      fatal: false,
    );
    _logger.d('Crashlytics: Test non-fatal error sent');
  }

  /// Check if unsent reports are available
  Future<bool> checkForUnsentReports() async {
    try {
      final hasReports = await _crashlytics.checkForUnsentReports();
      _logger.d('Crashlytics: Unsent reports available: $hasReports');
      return hasReports;
    } catch (e) {
      _logger.e('Failed to check for unsent reports', error: e);
      return false;
    }
  }

  /// Send unsent crash reports
  Future<void> sendUnsentReports() async {
    try {
      await _crashlytics.sendUnsentReports();
      _logger.d('Crashlytics: Unsent reports sent');
    } catch (e) {
      _logger.e('Failed to send unsent reports', error: e);
    }
  }

  /// Delete unsent crash reports
  Future<void> deleteUnsentReports() async {
    try {
      await _crashlytics.deleteUnsentReports();
      _logger.d('Crashlytics: Unsent reports deleted');
    } catch (e) {
      _logger.e('Failed to delete unsent reports', error: e);
    }
  }

  /// Enable/disable Crashlytics collection
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    try {
      await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
      _logger.i('Crashlytics: Collection ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      _logger.e('Failed to set Crashlytics collection', error: e);
    }
  }

  /// Check if Crashlytics is enabled
  Future<bool> isCrashlyticsCollectionEnabled() async {
    try {
      final enabled = await _crashlytics.isCrashlyticsCollectionEnabled();
      return enabled;
    } catch (e) {
      _logger.e('Failed to check Crashlytics status', error: e);
      return false;
    }
  }

  // ==================== Crash-Free Users Tracking ====================

  /// Mark session as crash-free
  /// Call this when app successfully completes important operations
  Future<void> markSessionSuccessful() async {
    await log('Session milestone: Operation completed successfully');
  }

  // ==================== Helper Methods ====================

  /// Execute code with automatic error reporting
  /// Wraps code in try-catch and reports errors to Crashlytics
  Future<T?> executeWithCrashReporting<T>({
    required String operation,
    required Future<T> Function() task,
    Map<String, dynamic>? context,
  }) async {
    try {
      await log('Starting: $operation');
      if (context != null) {
        await setCustomKeys(context);
      }

      final result = await task();

      await log('Completed: $operation');
      return result;
    } catch (error, stackTrace) {
      await recordError(
        error,
        stackTrace,
        reason: 'Error during $operation',
        fatal: false,
      );
      return null;
    }
  }

  /// Execute synchronous code with automatic error reporting
  T? executeSyncWithCrashReporting<T>({
    required String operation,
    required T Function() task,
    Map<String, dynamic>? context,
  }) {
    try {
      log('Starting: $operation');
      if (context != null) {
        setCustomKeys(context);
      }

      final result = task();

      log('Completed: $operation');
      return result;
    } catch (error, stackTrace) {
      recordError(
        error,
        stackTrace,
        reason: 'Error during $operation',
        fatal: false,
      );
      return null;
    }
  }
}
