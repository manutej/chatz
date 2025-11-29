import '../services/analytics_service.dart';
import '../services/crashlytics_service.dart';

/// Helper class for common analytics patterns
/// Provides convenient methods for frequently used analytics operations
class AnalyticsHelper {
  final AnalyticsService _analyticsService;
  final CrashlyticsService _crashlyticsService;

  AnalyticsHelper(
    this._analyticsService,
    this._crashlyticsService,
  );

  // ==================== User Lifecycle ====================

  /// Track user authentication lifecycle
  Future<void> trackUserAuthentication({
    required String userId,
    required String method,
    required bool isSignUp,
    String? email,
  }) async {
    // Set user ID in both services
    await _analyticsService.setUserId(userId);
    await _crashlyticsService.setUserIdentifier(userId);

    // Log appropriate event
    if (isSignUp) {
      await _analyticsService.logSignUp(method: method);
      await _crashlyticsService.logAuthEvent('signup', method: method);
    } else {
      await _analyticsService.logLogin(method: method);
      await _crashlyticsService.logAuthEvent('login', method: method);
    }

    // Set user properties
    await _analyticsService.setUserProperties(
      registrationDate: isSignUp ? DateTime.now() : null,
    );
  }

  /// Track user logout
  Future<void> trackUserLogout() async {
    await _analyticsService.logLogout();
    await _crashlyticsService.logAuthEvent('logout');

    // Clear user identifiers
    await _analyticsService.setUserId(null);
    await _crashlyticsService.setUserIdentifier(null);
  }

  // ==================== Messaging Lifecycle ====================

  /// Track complete message sending flow
  Future<void> trackMessageSent({
    required String chatId,
    required String messageType,
    int? messageLength,
    bool? hasMedia,
    int? fileSizeBytes,
  }) async {
    // Log message sent event
    await _analyticsService.logMessageSent(
      chatId: chatId,
      messageType: messageType,
      messageLength: messageLength,
      hasMedia: hasMedia,
    );

    // Log media if applicable
    if (hasMedia == true && fileSizeBytes != null) {
      await _analyticsService.logMediaShared(
        mediaType: messageType,
        fileSizeBytes: fileSizeBytes,
        chatId: chatId,
      );
    }

    // Log breadcrumb
    await _crashlyticsService.logUserAction(
      'send_message',
      params: {
        'type': messageType,
        'chat_id': chatId,
      },
    );

    // Update user properties
    // Note: In real app, you'd increment total_messages_sent
  }

  /// Track chat creation
  Future<void> trackChatCreated({
    required String chatId,
    required String chatType,
    int? participantCount,
  }) async {
    // Log analytics event
    await _analyticsService.logChatCreated(
      chatId: chatId,
      chatType: chatType,
      participantCount: participantCount,
    );

    // Set crash context
    await _crashlyticsService.setChatContext(
      chatId: chatId,
      chatType: chatType,
      participantCount: participantCount,
    );

    // Log breadcrumb
    await _crashlyticsService.logUserAction(
      'create_chat',
      params: {
        'type': chatType,
        'participants': participantCount ?? 2,
      },
    );
  }

  /// Track entering a chat
  Future<void> trackChatOpened({
    required String chatId,
    required String chatType,
    int? unreadCount,
  }) async {
    // Set crash context
    await _crashlyticsService.setChatContext(
      chatId: chatId,
      chatType: chatType,
    );

    // Log custom event
    await _analyticsService.logCustomEvent(
      eventName: 'chat_opened',
      parameters: {
        'chat_id': chatId,
        'chat_type': chatType,
        if (unreadCount != null) 'unread_count': unreadCount,
      },
    );
  }

  // ==================== Call Lifecycle ====================

  /// Track complete call flow
  Future<void> trackCallInitiated({
    required String callId,
    required String callType,
    required String recipientId,
  }) async {
    // Log analytics event
    await _analyticsService.logCallInitiated(
      callType: callType,
      recipientId: recipientId,
    );

    // Set crash context
    await _crashlyticsService.setCallContext(
      callId: callId,
      callType: callType,
      callStatus: 'initiated',
    );

    // Log breadcrumb
    await _crashlyticsService.logUserAction(
      'initiate_call',
      params: {
        'call_id': callId,
        'type': callType,
      },
    );
  }

  /// Track call answered
  Future<void> trackCallAnswered({
    required String callId,
    required String callType,
    int? ringDurationSeconds,
  }) async {
    await _analyticsService.logCallAnswered(
      callType: callType,
      callId: callId,
      ringDurationSeconds: ringDurationSeconds,
    );

    await _crashlyticsService.setCallContext(
      callId: callId,
      callType: callType,
      callStatus: 'active',
    );
  }

  /// Track call ended with all details
  Future<void> trackCallEnded({
    required String callId,
    required String callType,
    required int durationSeconds,
    required String endReason,
    double? costAmount,
  }) async {
    // Log analytics event
    await _analyticsService.logCallEnded(
      callType: callType,
      callId: callId,
      durationSeconds: durationSeconds,
      endReason: endReason,
      costAmount: costAmount,
    );

    // Log duration separately for better analytics
    await _analyticsService.logCallDuration(
      callType: callType,
      durationSeconds: durationSeconds,
    );

    // Clear call context
    await _crashlyticsService.setCustomKey('current_call_id', 'none');
    await _crashlyticsService.setCustomKey('call_status', 'ended');

    // Log breadcrumb
    await _crashlyticsService.logUserAction(
      'end_call',
      params: {
        'call_id': callId,
        'duration': durationSeconds,
        'reason': endReason,
      },
    );
  }

  // ==================== Payment Lifecycle ====================

  /// Track wallet recharge flow
  Future<void> trackWalletRecharge({
    required double amount,
    required String currency,
    required String paymentMethod,
    String? transactionId,
    required bool success,
  }) async {
    if (success) {
      // Log successful recharge
      await _analyticsService.logWalletRecharged(
        amount: amount,
        currency: currency,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
      );

      // Update wallet context
      // Note: In real app, you'd pass actual new balance
      await _crashlyticsService.setWalletContext(
        balance: amount,
        currency: currency,
      );

      // Update user property for wallet tier
      final tier = _getWalletTier(amount);
      await _analyticsService.setWalletBalanceTier(tier);
    } else {
      // Log failed payment
      await _crashlyticsService.recordPaymentError(
        Exception('Payment failed'),
        StackTrace.current,
        operation: 'wallet_recharge',
        amount: amount,
        currency: currency,
        paymentMethod: paymentMethod,
      );
    }

    // Log transaction completion
    await _analyticsService.logTransactionCompleted(
      transactionId: transactionId ?? 'unknown',
      amount: amount,
      currency: currency,
      transactionType: 'recharge',
      success: success,
    );
  }

  /// Track call charge
  Future<void> trackCallCharge({
    required double amount,
    required String currency,
    required int callDurationSeconds,
    required String callType,
    required double newBalance,
  }) async {
    // Log call charged event
    await _analyticsService.logCallCharged(
      amount: amount,
      currency: currency,
      callDurationSeconds: callDurationSeconds,
      callType: callType,
    );

    // Update wallet context with new balance
    await _crashlyticsService.setWalletContext(
      balance: newBalance,
      currency: currency,
    );

    // Update wallet tier
    final tier = _getWalletTier(newBalance);
    await _analyticsService.setWalletBalanceTier(tier);

    // Log breadcrumb
    await _crashlyticsService.logPaymentEvent(
      'call_charged',
      amount: amount,
      currency: currency,
    );
  }

  /// Helper to determine wallet balance tier
  String _getWalletTier(double balance) {
    if (balance == 0) return 'empty';
    if (balance < 5) return 'low';
    if (balance < 20) return 'medium';
    return 'high';
  }

  // ==================== Feature Usage ====================

  /// Track feature usage with context
  Future<void> trackFeatureUsage({
    required String featureName,
    Map<String, dynamic>? parameters,
  }) async {
    await _analyticsService.logFeatureUsed(
      featureName: featureName,
      parameters: parameters,
    );

    await _crashlyticsService.logUserAction(
      'use_feature',
      params: {
        'feature': featureName,
        if (parameters != null) ...parameters,
      },
    );
  }

  /// Track app session
  Future<void> trackAppSession({
    required String source,
    String? notificationId,
    String? deepLink,
  }) async {
    await _analyticsService.logAppOpened(source: source);

    await _crashlyticsService.log(
      'App opened from $source${notificationId != null ? ' (notification: $notificationId)' : ''}',
    );

    if (deepLink != null) {
      await _analyticsService.logCustomEvent(
        eventName: 'deep_link_opened',
        parameters: {
          'deep_link': deepLink,
          'source': source,
        },
      );
    }
  }

  // ==================== Network Context ====================

  /// Update network context for debugging
  Future<void> updateNetworkContext({
    required bool isConnected,
    String? connectionType,
  }) async {
    await _crashlyticsService.setNetworkContext(
      isConnected: isConnected,
      connectionType: connectionType,
    );

    // Log network change events
    await _analyticsService.logCustomEvent(
      eventName: 'network_status_changed',
      parameters: {
        'is_connected': isConnected,
        if (connectionType != null) 'connection_type': connectionType,
      },
    );
  }

  // ==================== User Properties Bulk Update ====================

  /// Update all user properties at once (e.g., on profile load)
  Future<void> updateUserProfile({
    required String userId,
    required String userType,
    required int totalChats,
    required int totalMessagesSent,
    required double walletBalance,
    required String currency,
    String? preferredLanguage,
    DateTime? registrationDate,
  }) async {
    // Set analytics user ID and properties
    await _analyticsService.setUserId(userId);
    await _analyticsService.setUserProperties(
      userType: userType,
      totalChats: totalChats,
      totalMessagesSent: totalMessagesSent,
      walletBalanceTier: _getWalletTier(walletBalance),
      preferredLanguage: preferredLanguage,
      registrationDate: registrationDate,
    );

    // Set crashlytics user ID
    await _crashlyticsService.setUserIdentifier(userId);

    // Set wallet context
    await _crashlyticsService.setWalletContext(
      balance: walletBalance,
      currency: currency,
    );

    // Set additional custom keys
    await _crashlyticsService.setCustomKeys({
      'user_type': userType,
      'total_chats': totalChats,
      'total_messages': totalMessagesSent,
    });
  }
}
