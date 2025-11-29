import 'dart:async';
import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import '../services/crashlytics_service.dart';

/// Global error handler for the application
/// Catches and reports all uncaught errors to Crashlytics and Analytics
class ErrorHandler {
  final CrashlyticsService _crashlyticsService;
  final AnalyticsService _analyticsService;

  ErrorHandler(
    this._crashlyticsService,
    this._analyticsService,
  );

  /// Initialize global error handlers
  Future<void> initialize() async {
    // Initialize Crashlytics
    await _crashlyticsService.initialize();

    // Set up zone error handler for async errors
    runZonedGuarded<Future<void>>(
      () async {
        // App initialization continues in the zone
      },
      (error, stackTrace) {
        _handleError(error, stackTrace, fatal: true);
      },
    );
  }

  /// Handle caught errors
  Future<void> handleError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    bool fatal = false,
  }) async {
    await _handleError(
      error,
      stackTrace,
      context: context,
      fatal: fatal,
    );
  }

  /// Internal error handler
  Future<void> _handleError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    bool fatal = false,
  }) async {
    // Log to Crashlytics
    await _crashlyticsService.recordError(
      error,
      stackTrace,
      reason: context ?? 'Uncaught error',
      fatal: fatal,
    );

    // Log error event to Analytics (for non-fatal errors)
    if (!fatal && context != null) {
      await _analyticsService.logCustomEvent(
        eventName: 'app_error',
        parameters: {
          'error_type': error.runtimeType.toString(),
          'context': context,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    }
  }

  /// Handle API errors specifically
  Future<void> handleApiError(
    dynamic error,
    StackTrace? stackTrace, {
    required String endpoint,
    required String method,
    int? statusCode,
  }) async {
    // Log to Crashlytics with API context
    await _crashlyticsService.recordApiError(
      error,
      stackTrace,
      endpoint: endpoint,
      method: method,
      statusCode: statusCode,
    );

    // Log to Analytics
    await _analyticsService.logApiError(
      endpoint: endpoint,
      statusCode: statusCode ?? 0,
      errorMessage: error.toString(),
      requestMethod: method,
    );
  }

  /// Handle authentication errors
  Future<void> handleAuthError(
    dynamic error,
    StackTrace? stackTrace, {
    required String method,
    String? userId,
  }) async {
    // Log to Crashlytics with auth context
    await _crashlyticsService.recordAuthError(
      error,
      stackTrace,
      method: method,
      userId: userId,
    );

    // Log to Analytics
    await _analyticsService.logAuthFailed(
      method: method,
      errorCode: error.toString(),
    );
  }

  /// Handle upload errors
  Future<void> handleUploadError(
    dynamic error,
    StackTrace? stackTrace, {
    required String fileType,
    required int fileSizeBytes,
  }) async {
    // Log to Crashlytics with storage context
    await _crashlyticsService.recordStorageError(
      error,
      stackTrace,
      operation: 'upload',
      fileSize: fileSizeBytes,
    );

    // Log to Analytics
    await _analyticsService.logUploadFailed(
      fileType: fileType,
      fileSizeBytes: fileSizeBytes,
      errorReason: error.toString(),
    );
  }

  /// Execute code with automatic error handling
  Future<T?> executeWithErrorHandling<T>({
    required String operation,
    required Future<T> Function() task,
    void Function(dynamic error)? onError,
    Map<String, dynamic>? context,
  }) async {
    try {
      return await task();
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace,
        context: operation,
        fatal: false,
      );

      if (onError != null) {
        onError(error);
      }

      return null;
    }
  }
}

/// Widget for displaying error UI to users
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorWidget;

  const ErrorBoundary({
    required this.child,
    this.errorWidget,
    super.key,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _error;

  @override
  void initState() {
    super.initState();

    // Set up error boundary
    ErrorWidget.builder = (FlutterErrorDetails details) {
      setState(() {
        _error = details;
      });

      // Return custom error widget or default
      return widget.errorWidget?.call(details) ??
          _DefaultErrorWidget(details: details);
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorWidget?.call(_error!) ??
          _DefaultErrorWidget(details: _error!);
    }

    return widget.child;
  }
}

/// Default error widget shown when app encounters an error
class _DefaultErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;

  const _DefaultErrorWidget({
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'We\'re sorry for the inconvenience. The error has been reported and we\'ll fix it soon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Restart the app or navigate to home
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Restart App'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
