import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Service for Firebase Analytics integration
/// Provides comprehensive event tracking, user properties, and screen view logging
@lazySingleton
class AnalyticsService {
  final FirebaseAnalytics _analytics;
  final Logger _logger;

  AnalyticsService(
    this._analytics,
    this._logger,
  );

  /// Get analytics observer for navigation tracking
  FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(
        analytics: _analytics,
        nameExtractor: _screenNameExtractor,
      );

  /// Extract clean screen names from route settings
  String _screenNameExtractor(RouteSettings settings) {
    final name = settings.name ?? 'unknown_screen';
    // Remove leading slash and convert to snake_case
    final cleanName = name
        .replaceAll(RegExp(r'^/'), '')
        .replaceAll('/', '_')
        .toLowerCase();
    return cleanName.isEmpty ? 'home' : cleanName;
  }

  // ==================== Authentication Events ====================

  /// Log user login event
  Future<void> logLogin({
    required String method, // 'google', 'apple', 'phone', 'email'
  }) async {
    try {
      await _analytics.logLogin(
        loginMethod: method,
      );
      _logger.d('Analytics: User logged in via $method');
    } catch (e) {
      _logger.e('Failed to log login event', error: e);
    }
  }

  /// Log user signup event
  Future<void> logSignUp({
    required String method,
  }) async {
    try {
      await _analytics.logSignUp(
        signUpMethod: method,
      );
      _logger.d('Analytics: User signed up via $method');
    } catch (e) {
      _logger.e('Failed to log signup event', error: e);
    }
  }

  /// Log user logout event
  Future<void> logLogout() async {
    try {
      await _analytics.logEvent(
        name: 'logout',
      );
      _logger.d('Analytics: User logged out');
    } catch (e) {
      _logger.e('Failed to log logout event', error: e);
    }
  }

  // ==================== Messaging Events ====================

  /// Log message sent event
  Future<void> logMessageSent({
    required String chatId,
    required String messageType, // 'text', 'image', 'video', 'audio', 'file'
    int? messageLength,
    bool? hasMedia,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'message_sent',
        parameters: {
          'chat_id': chatId,
          'message_type': messageType,
          if (messageLength != null) 'message_length': messageLength,
          if (hasMedia != null) 'has_media': hasMedia,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      _logger.d('Analytics: Message sent - type: $messageType');
    } catch (e) {
      _logger.e('Failed to log message_sent event', error: e);
    }
  }

  /// Log message read event
  Future<void> logMessageRead({
    required String chatId,
    required String messageId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'message_read',
        parameters: {
          'chat_id': chatId,
          'message_id': messageId,
        },
      );
    } catch (e) {
      _logger.e('Failed to log message_read event', error: e);
    }
  }

  /// Log chat created event
  Future<void> logChatCreated({
    required String chatId,
    required String chatType, // 'direct', 'group'
    int? participantCount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'chat_created',
        parameters: {
          'chat_id': chatId,
          'chat_type': chatType,
          if (participantCount != null) 'participant_count': participantCount,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      _logger.d('Analytics: Chat created - type: $chatType');
    } catch (e) {
      _logger.e('Failed to log chat_created event', error: e);
    }
  }

  /// Log media shared event
  Future<void> logMediaShared({
    required String mediaType, // 'image', 'video', 'audio', 'document'
    required int fileSizeBytes,
    String? chatId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'media_shared',
        parameters: {
          'media_type': mediaType,
          'file_size_bytes': fileSizeBytes,
          'file_size_mb': (fileSizeBytes / (1024 * 1024)).toStringAsFixed(2),
          if (chatId != null) 'chat_id': chatId,
        },
      );
      _logger.d('Analytics: Media shared - $mediaType');
    } catch (e) {
      _logger.e('Failed to log media_shared event', error: e);
    }
  }

  // ==================== Call Events ====================

  /// Log call initiated event
  Future<void> logCallInitiated({
    required String callType, // 'voice', 'video'
    required String recipientId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'call_initiated',
        parameters: {
          'call_type': callType,
          'recipient_id': recipientId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      _logger.d('Analytics: Call initiated - $callType');
    } catch (e) {
      _logger.e('Failed to log call_initiated event', error: e);
    }
  }

  /// Log call answered event
  Future<void> logCallAnswered({
    required String callType,
    required String callId,
    int? ringDurationSeconds,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'call_answered',
        parameters: {
          'call_type': callType,
          'call_id': callId,
          if (ringDurationSeconds != null)
            'ring_duration_seconds': ringDurationSeconds,
        },
      );
      _logger.d('Analytics: Call answered - $callType');
    } catch (e) {
      _logger.e('Failed to log call_answered event', error: e);
    }
  }

  /// Log call ended event
  Future<void> logCallEnded({
    required String callType,
    required String callId,
    required int durationSeconds,
    required String endReason, // 'completed', 'cancelled', 'failed', 'rejected'
    double? costAmount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'call_ended',
        parameters: {
          'call_type': callType,
          'call_id': callId,
          'duration_seconds': durationSeconds,
          'duration_minutes': (durationSeconds / 60).toStringAsFixed(2),
          'end_reason': endReason,
          if (costAmount != null) 'cost_amount': costAmount,
        },
      );
      _logger.d('Analytics: Call ended - $endReason after $durationSeconds seconds');
    } catch (e) {
      _logger.e('Failed to log call_ended event', error: e);
    }
  }

  /// Log call duration for analytics
  Future<void> logCallDuration({
    required String callType,
    required int durationSeconds,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'call_duration',
        parameters: {
          'call_type': callType,
          'duration_seconds': durationSeconds,
        },
      );
    } catch (e) {
      _logger.e('Failed to log call_duration event', error: e);
    }
  }

  // ==================== Payment Events ====================

  /// Log wallet recharge event
  Future<void> logWalletRecharged({
    required double amount,
    required String currency,
    required String paymentMethod, // 'stripe', 'apple_pay', 'google_pay'
    String? transactionId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'wallet_recharged',
        parameters: {
          'amount': amount,
          'currency': currency,
          'payment_method': paymentMethod,
          if (transactionId != null) 'transaction_id': transactionId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      _logger.d('Analytics: Wallet recharged - $amount $currency');
    } catch (e) {
      _logger.e('Failed to log wallet_recharged event', error: e);
    }
  }

  /// Log call charged event
  Future<void> logCallCharged({
    required double amount,
    required String currency,
    required int callDurationSeconds,
    required String callType,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'call_charged',
        parameters: {
          'amount': amount,
          'currency': currency,
          'call_duration_seconds': callDurationSeconds,
          'call_type': callType,
        },
      );
      _logger.d('Analytics: Call charged - $amount $currency');
    } catch (e) {
      _logger.e('Failed to log call_charged event', error: e);
    }
  }

  /// Log transaction completed event
  Future<void> logTransactionCompleted({
    required String transactionId,
    required double amount,
    required String currency,
    required String transactionType, // 'recharge', 'call', 'refund'
    bool? success,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'transaction_completed',
        parameters: {
          'transaction_id': transactionId,
          'amount': amount,
          'currency': currency,
          'transaction_type': transactionType,
          if (success != null) 'success': success,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      _logger.d('Analytics: Transaction completed - $transactionType');
    } catch (e) {
      _logger.e('Failed to log transaction_completed event', error: e);
    }
  }

  // ==================== Engagement Events ====================

  /// Log app opened event
  Future<void> logAppOpened({
    String? source, // 'notification', 'direct', 'deep_link'
  }) async {
    try {
      await _analytics.logAppOpen(
        parameters: {
          if (source != null) 'source': source,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      _logger.d('Analytics: App opened${source != null ? ' from $source' : ''}');
    } catch (e) {
      _logger.e('Failed to log app_opened event', error: e);
    }
  }

  /// Log screen view event
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      _logger.d('Analytics: Screen view - $screenName');
    } catch (e) {
      _logger.e('Failed to log screen_view event', error: e);
    }
  }

  /// Log feature used event
  Future<void> logFeatureUsed({
    required String featureName,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'feature_used',
        parameters: {
          'feature_name': featureName,
          if (parameters != null) ...parameters,
        },
      );
      _logger.d('Analytics: Feature used - $featureName');
    } catch (e) {
      _logger.e('Failed to log feature_used event', error: e);
    }
  }

  /// Log search event
  Future<void> logSearch({
    required String searchTerm,
    String? searchType, // 'contacts', 'messages', 'chats'
    int? resultsCount,
  }) async {
    try {
      await _analytics.logSearch(
        searchTerm: searchTerm,
        parameters: {
          if (searchType != null) 'search_type': searchType,
          if (resultsCount != null) 'results_count': resultsCount,
        },
      );
      _logger.d('Analytics: Search performed - $searchType');
    } catch (e) {
      _logger.e('Failed to log search event', error: e);
    }
  }

  /// Log share event
  Future<void> logShare({
    required String contentType, // 'message', 'media', 'contact'
    required String method, // 'native_share', 'copy_link'
  }) async {
    try {
      await _analytics.logShare(
        contentType: contentType,
        itemId: null,
        method: method,
      );
      _logger.d('Analytics: Content shared - $contentType via $method');
    } catch (e) {
      _logger.e('Failed to log share event', error: e);
    }
  }

  // ==================== Error Events ====================

  /// Log API error event
  Future<void> logApiError({
    required String endpoint,
    required int statusCode,
    required String errorMessage,
    String? requestMethod,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'api_error',
        parameters: {
          'endpoint': endpoint,
          'status_code': statusCode,
          'error_message': errorMessage,
          if (requestMethod != null) 'request_method': requestMethod,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      _logger.w('Analytics: API error - $statusCode at $endpoint');
    } catch (e) {
      _logger.e('Failed to log api_error event', error: e);
    }
  }

  /// Log upload failed event
  Future<void> logUploadFailed({
    required String fileType,
    required int fileSizeBytes,
    required String errorReason,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'upload_failed',
        parameters: {
          'file_type': fileType,
          'file_size_bytes': fileSizeBytes,
          'error_reason': errorReason,
        },
      );
      _logger.w('Analytics: Upload failed - $fileType');
    } catch (e) {
      _logger.e('Failed to log upload_failed event', error: e);
    }
  }

  /// Log authentication failed event
  Future<void> logAuthFailed({
    required String method,
    required String errorCode,
    String? errorMessage,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'auth_failed',
        parameters: {
          'method': method,
          'error_code': errorCode,
          if (errorMessage != null) 'error_message': errorMessage,
        },
      );
      _logger.w('Analytics: Auth failed - $method');
    } catch (e) {
      _logger.e('Failed to log auth_failed event', error: e);
    }
  }

  // ==================== User Properties ====================

  /// Set user ID for analytics
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
      _logger.d('Analytics: User ID set - ${userId != null ? 'authenticated' : 'cleared'}');
    } catch (e) {
      _logger.e('Failed to set user ID', error: e);
    }
  }

  /// Set user type property
  Future<void> setUserType(String userType) async {
    try {
      await _analytics.setUserProperty(
        name: 'user_type',
        value: userType, // 'free', 'premium'
      );
      _logger.d('Analytics: User type set - $userType');
    } catch (e) {
      _logger.e('Failed to set user_type property', error: e);
    }
  }

  /// Set total chats property
  Future<void> setTotalChats(int count) async {
    try {
      await _analytics.setUserProperty(
        name: 'total_chats',
        value: count.toString(),
      );
    } catch (e) {
      _logger.e('Failed to set total_chats property', error: e);
    }
  }

  /// Set total messages sent property
  Future<void> setTotalMessagesSent(int count) async {
    try {
      await _analytics.setUserProperty(
        name: 'total_messages_sent',
        value: count.toString(),
      );
    } catch (e) {
      _logger.e('Failed to set total_messages_sent property', error: e);
    }
  }

  /// Set wallet balance tier property
  Future<void> setWalletBalanceTier(String tier) async {
    try {
      await _analytics.setUserProperty(
        name: 'wallet_balance_tier',
        value: tier, // 'empty', 'low', 'medium', 'high'
      );
    } catch (e) {
      _logger.e('Failed to set wallet_balance_tier property', error: e);
    }
  }

  /// Set preferred language property
  Future<void> setPreferredLanguage(String language) async {
    try {
      await _analytics.setUserProperty(
        name: 'preferred_language',
        value: language,
      );
      _logger.d('Analytics: Preferred language set - $language');
    } catch (e) {
      _logger.e('Failed to set preferred_language property', error: e);
    }
  }

  /// Set registration date property
  Future<void> setRegistrationDate(DateTime date) async {
    try {
      await _analytics.setUserProperty(
        name: 'registration_date',
        value: date.toIso8601String().split('T').first, // YYYY-MM-DD
      );
      _logger.d('Analytics: Registration date set');
    } catch (e) {
      _logger.e('Failed to set registration_date property', error: e);
    }
  }

  /// Set multiple user properties at once
  Future<void> setUserProperties({
    String? userType,
    int? totalChats,
    int? totalMessagesSent,
    String? walletBalanceTier,
    String? preferredLanguage,
    DateTime? registrationDate,
  }) async {
    try {
      if (userType != null) await setUserType(userType);
      if (totalChats != null) await setTotalChats(totalChats);
      if (totalMessagesSent != null) await setTotalMessagesSent(totalMessagesSent);
      if (walletBalanceTier != null) await setWalletBalanceTier(walletBalanceTier);
      if (preferredLanguage != null) await setPreferredLanguage(preferredLanguage);
      if (registrationDate != null) await setRegistrationDate(registrationDate);

      _logger.d('Analytics: User properties updated');
    } catch (e) {
      _logger.e('Failed to set user properties', error: e);
    }
  }

  // ==================== Analytics Settings ====================

  /// Enable/disable analytics collection
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(enabled);
      _logger.d('Analytics: Collection ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      _logger.e('Failed to set analytics collection', error: e);
    }
  }

  /// Set session timeout duration
  Future<void> setSessionTimeoutDuration(Duration duration) async {
    try {
      await _analytics.setSessionTimeoutDuration(duration);
      _logger.d('Analytics: Session timeout set to ${duration.inMinutes} minutes');
    } catch (e) {
      _logger.e('Failed to set session timeout', error: e);
    }
  }

  /// Reset analytics data (for testing)
  Future<void> resetAnalyticsData() async {
    try {
      await _analytics.resetAnalyticsData();
      _logger.d('Analytics: Data reset');
    } catch (e) {
      _logger.e('Failed to reset analytics data', error: e);
    }
  }

  // ==================== Custom Events ====================

  /// Log custom event with parameters
  Future<void> logCustomEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
      _logger.d('Analytics: Custom event - $eventName');
    } catch (e) {
      _logger.e('Failed to log custom event', error: e);
    }
  }
}
