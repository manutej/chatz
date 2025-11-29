import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Dependency injection module for Analytics and Crashlytics services
@module
abstract class AnalyticsModule {
  /// Provide FirebaseAnalytics instance
  @lazySingleton
  FirebaseAnalytics get analytics => FirebaseAnalytics.instance;

  /// Provide FirebaseCrashlytics instance
  @lazySingleton
  FirebaseCrashlytics get crashlytics => FirebaseCrashlytics.instance;

  /// Provide Logger instance
  @lazySingleton
  Logger get logger => Logger(
        printer: PrettyPrinter(
          methodCount: 2,
          errorMethodCount: 8,
          lineLength: 120,
          colors: true,
          printEmojis: true,
          printTime: true,
        ),
      );
}
