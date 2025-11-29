import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'local_notification_service.dart';
import 'permission_service.dart';
import '../../features/chat/data/datasources/fcm_data_source.dart';
import '../../core/router/app_router.dart';

/// Global function for background message handling
/// Must be a top-level or static function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📱 Background message received: ${message.messageId}');
  debugPrint('Background message data: ${message.data}');

  // Handle data-only messages in background
  if (message.data.isNotEmpty) {
    // Process background message
    // You can update local database, sync data, etc.
  }
}

/// Service for handling Firebase Cloud Messaging (FCM) push notifications
///
/// Features:
/// - Initialize FCM and request permissions
/// - Retrieve and manage FCM tokens
/// - Handle foreground, background, and terminated state notifications
/// - Navigate to appropriate screens based on notification payload
/// - Token refresh and synchronization
class NotificationService {
  final FirebaseMessaging _messaging;
  final LocalNotificationService _localNotificationService;
  final PermissionService _permissionService;
  final FCMDataSource _fcmDataSource;

  NotificationService({
    required FirebaseMessaging messaging,
    required LocalNotificationService localNotificationService,
    required PermissionService permissionService,
    required FCMDataSource fcmDataSource,
  })  : _messaging = messaging,
        _localNotificationService = localNotificationService,
        _permissionService = permissionService,
        _fcmDataSource = fcmDataSource;

  /// Initialize notification service
  ///
  /// Steps:
  /// 1. Set up background message handler
  /// 2. Initialize local notifications
  /// 3. Request permissions
  /// 4. Get and save FCM token
  /// 5. Set up message listeners
  Future<void> initialize() async {
    try {
      debugPrint('🔔 Initializing NotificationService...');

      // Set background message handler (must be top-level function)
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Initialize local notifications
      await _localNotificationService.initialize(
        onNotificationTap: _handleNotificationTap,
      );

      // Request notification permissions
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        debugPrint('⚠️  Notification permission denied');
        return;
      }

      // Get and save FCM token
      await _getAndSaveToken();

      // Set up token refresh listener
      _setupTokenRefreshListener();

      // Set up message listeners
      _setupMessageListeners();

      debugPrint('✅ NotificationService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing NotificationService: $e');
    }
  }

  /// Request notification permissions from user
  Future<bool> requestPermission() async {
    try {
      // Use PermissionService for consistency
      final hasPermission = await _permissionService.requestNotificationPermission();

      if (!hasPermission) {
        return false;
      }

      // Configure FCM settings
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      return true;
    } catch (e) {
      debugPrint('❌ Error requesting notification permission: $e');
      return false;
    }
  }

  /// Get FCM token and save to Firestore
  Future<String?> _getAndSaveToken() async {
    try {
      final token = await _messaging.getToken();

      if (token != null) {
        debugPrint('📱 FCM Token: $token');

        // Save token to Firestore via FCMDataSource
        await _fcmDataSource.saveDeviceToken(token);

        return token;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Set up token refresh listener
  void _setupTokenRefreshListener() {
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('🔄 FCM token refreshed: $newToken');

      // Save new token to Firestore
      await _fcmDataSource.saveDeviceToken(newToken);
    });
  }

  /// Set up message listeners for different app states
  void _setupMessageListeners() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background/terminated messages that opened the app
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check for initial message (app opened from terminated state)
    _checkInitialMessage();
  }

  /// Handle foreground messages (app is open and visible)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📬 Foreground message received: ${message.messageId}');
    debugPrint('Notification: ${message.notification?.toMap()}');
    debugPrint('Data: ${message.data}');

    // Show local notification when app is in foreground
    if (message.notification != null) {
      await _localNotificationService.showNotification(
        title: message.notification!.title ?? 'New notification',
        body: message.notification!.body ?? '',
        payload: _encodePayload(message.data),
        notificationType: _getNotificationType(message.data),
      );
    }
  }

  /// Handle message when app is opened from background/terminated state
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint('🔓 App opened from notification: ${message.messageId}');
    debugPrint('Data: ${message.data}');

    // Navigate to appropriate screen
    _handleNotificationNavigation(message.data);
  }

  /// Check for initial message when app is launched from terminated state
  Future<void> _checkInitialMessage() async {
    final message = await _messaging.getInitialMessage();

    if (message != null) {
      debugPrint('🚀 App launched from notification: ${message.messageId}');
      debugPrint('Data: ${message.data}');

      // Delay navigation to ensure app is ready
      await Future.delayed(const Duration(milliseconds: 500));
      _handleNotificationNavigation(message.data);
    }
  }

  /// Handle notification tap from local notification service
  void _handleNotificationTap(String? payload) {
    if (payload == null) return;

    final data = _decodePayload(payload);
    _handleNotificationNavigation(data);
  }

  /// Navigate to appropriate screen based on notification data
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    if (type == null) {
      debugPrint('⚠️  Notification type is null');
      return;
    }

    try {
      // Get router from global navigation key or context
      // Note: You may need to adjust this based on your navigation setup
      final router = GoRouter.of(_getNavigationContext());

      switch (type) {
        case 'message':
          final chatId = data['chatId'] as String?;
          if (chatId != null) {
            router.push('/home/chat/$chatId');
          }
          break;

        case 'call':
          final callId = data['callId'] as String?;
          final isVideo = data['isVideo'] == 'true';
          if (callId != null) {
            router.push('/home/call/$callId?video=$isVideo');
          }
          break;

        case 'group_message':
          final groupId = data['groupId'] as String?;
          if (groupId != null) {
            router.push('/home/chat/$groupId');
          }
          break;

        case 'reaction':
          final chatId = data['chatId'] as String?;
          if (chatId != null) {
            router.push('/home/chat/$chatId');
          }
          break;

        default:
          debugPrint('⚠️  Unknown notification type: $type');
      }
    } catch (e) {
      debugPrint('❌ Error navigating from notification: $e');
    }
  }

  /// Get notification type from message data
  NotificationType _getNotificationType(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    switch (type) {
      case 'message':
      case 'group_message':
        return NotificationType.message;
      case 'call':
        return NotificationType.call;
      default:
        return NotificationType.message;
    }
  }

  /// Encode notification payload as JSON string
  String _encodePayload(Map<String, dynamic> data) {
    try {
      return data.entries.map((e) => '${e.key}=${e.value}').join('&');
    } catch (e) {
      return '';
    }
  }

  /// Decode notification payload from string
  Map<String, dynamic> _decodePayload(String payload) {
    try {
      final map = <String, dynamic>{};
      final pairs = payload.split('&');

      for (final pair in pairs) {
        final keyValue = pair.split('=');
        if (keyValue.length == 2) {
          map[keyValue[0]] = keyValue[1];
        }
      }

      return map;
    } catch (e) {
      return {};
    }
  }

  /// Get navigation context (implement based on your navigation setup)
  ///
  /// Option 1: Use global navigation key
  /// Option 2: Use static router reference
  /// Option 3: Use context from MaterialApp builder
  dynamic _getNavigationContext() {
    // This is a placeholder - implement based on your navigation setup
    // You may need to:
    // 1. Create a global navigation key in main.dart
    // 2. Pass it to this service
    // 3. Use it here: return navigatorKey.currentContext!;

    throw UnimplementedError(
      'Implement navigation context retrieval. See comments in NotificationService._getNavigationContext',
    );
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Delete FCM token (call on logout)
  Future<void> deleteToken() async {
    try {
      final token = await _messaging.getToken();

      if (token != null) {
        // Remove token from Firestore
        await _fcmDataSource.removeDeviceToken(token);

        // Delete token from FCM
        await _messaging.deleteToken();

        debugPrint('🗑️  FCM token deleted');
      }
    } catch (e) {
      debugPrint('❌ Error deleting FCM token: $e');
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }

  /// Get notification settings (iOS only)
  Future<NotificationSettings> getNotificationSettings() async {
    return await _messaging.getNotificationSettings();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }
}
