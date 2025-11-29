import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

/// Notification type for different channels
enum NotificationType {
  message,
  call,
  system,
}

/// Service for handling local notifications
///
/// Features:
/// - Display notifications when app is in foreground
/// - Custom notification channels (messages, calls, system)
/// - Custom notification sounds
/// - Action buttons (reply, mark as read)
/// - Badge count management
/// - Notification grouping
class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _notifications;

  // Notification IDs
  static const int messageNotificationId = 1000;
  static const int callNotificationId = 2000;
  static const int systemNotificationId = 3000;

  // Channel IDs
  static const String messageChannelId = 'chatz_messages';
  static const String callChannelId = 'chatz_calls';
  static const String systemChannelId = 'chatz_system';

  // Channel Names
  static const String messageChannelName = 'Messages';
  static const String callChannelName = 'Calls';
  static const String systemChannelName = 'System';

  // Channel Descriptions
  static const String messageChannelDescription = 'Notifications for new messages';
  static const String callChannelDescription = 'Notifications for incoming calls';
  static const String systemChannelDescription = 'System notifications';

  LocalNotificationService({
    required FlutterLocalNotificationsPlugin notifications,
  }) : _notifications = notifications;

  /// Initialize local notifications
  Future<void> initialize({
    required Function(String?) onNotificationTap,
  }) async {
    try {
      debugPrint('🔔 Initializing LocalNotificationService...');

      // Android initialization
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization
      final iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: (id, title, body, payload) async {
          // Handle iOS foreground notification
          debugPrint('iOS foreground notification: $title');
        },
      );

      // Combined initialization settings
      final initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize plugin
      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification tapped: ${response.payload}');
          onNotificationTap(response.payload);
        },
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
      );

      // Create notification channels (Android)
      if (Platform.isAndroid) {
        await _createNotificationChannels();
      }

      debugPrint('✅ LocalNotificationService initialized');
    } catch (e) {
      debugPrint('❌ Error initializing LocalNotificationService: $e');
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    try {
      // Message channel
      const messageChannel = AndroidNotificationChannel(
        messageChannelId,
        messageChannelName,
        description: messageChannelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF00C853),
        showBadge: true,
      );

      // Call channel
      const callChannel = AndroidNotificationChannel(
        callChannelId,
        callChannelName,
        description: callChannelDescription,
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('call_ringtone'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        enableLights: true,
        ledColor: Color(0xFF2196F3),
        showBadge: true,
      );

      // System channel
      const systemChannel = AndroidNotificationChannel(
        systemChannelId,
        systemChannelName,
        description: systemChannelDescription,
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: false,
        showBadge: false,
      );

      // Create channels
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(messageChannel);

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(callChannel);

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(systemChannel);

      debugPrint('✅ Notification channels created');
    } catch (e) {
      debugPrint('❌ Error creating notification channels: $e');
    }
  }

  /// Show notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    NotificationType notificationType = NotificationType.message,
    String? largeIconPath,
    String? bigPicturePath,
    List<AndroidNotificationAction>? actions,
  }) async {
    try {
      final notificationId = _getNotificationId(notificationType);
      final channelId = _getChannelId(notificationType);

      // Android notification details
      final androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(notificationType),
        channelDescription: _getChannelDescription(notificationType),
        importance: notificationType == NotificationType.call
            ? Importance.max
            : Importance.high,
        priority: notificationType == NotificationType.call
            ? Priority.max
            : Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: largeIconPath != null
            ? FilePathAndroidBitmap(largeIconPath)
            : null,
        styleInformation: bigPicturePath != null
            ? BigPictureStyleInformation(
                FilePathAndroidBitmap(bigPicturePath),
                contentTitle: title,
                summaryText: body,
              )
            : BigTextStyleInformation(
                body,
                contentTitle: title,
              ),
        actions: actions,
        category: AndroidNotificationCategory.message,
        ticker: body,
        autoCancel: true,
        ongoing: notificationType == NotificationType.call,
        fullScreenIntent: notificationType == NotificationType.call,
      );

      // iOS notification details
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: notificationType == NotificationType.call
            ? 'call_ringtone.aiff'
            : null,
        threadIdentifier: channelId,
        interruptionLevel: notificationType == NotificationType.call
            ? InterruptionLevel.critical
            : InterruptionLevel.active,
      );

      // Combined notification details
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show notification
      await _notifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      debugPrint('✅ Notification shown: $title');
    } catch (e) {
      debugPrint('❌ Error showing notification: $e');
    }
  }

  /// Show message notification with reply action
  Future<void> showMessageNotification({
    required String title,
    required String body,
    required String chatId,
    String? senderAvatar,
    String? messageImageUrl,
  }) async {
    final payload = 'type=message&chatId=$chatId';

    // Android reply action
    final replyAction = AndroidNotificationAction(
      'reply',
      'Reply',
      inputs: [
        const AndroidNotificationActionInput(
          label: 'Type your message...',
        ),
      ],
      icon: DrawableResourceAndroidBitmap('@drawable/ic_reply'),
    );

    // Android mark as read action
    const markReadAction = AndroidNotificationAction(
      'mark_read',
      'Mark as Read',
      icon: DrawableResourceAndroidBitmap('@drawable/ic_check'),
    );

    await showNotification(
      title: title,
      body: body,
      payload: payload,
      notificationType: NotificationType.message,
      largeIconPath: senderAvatar,
      bigPicturePath: messageImageUrl,
      actions: [replyAction, markReadAction],
    );
  }

  /// Show call notification
  Future<void> showCallNotification({
    required String callerName,
    required String callId,
    required bool isVideoCall,
    String? callerAvatar,
  }) async {
    final callType = isVideoCall ? 'Video' : 'Voice';
    final payload = 'type=call&callId=$callId&isVideo=$isVideoCall';

    // Android answer action
    final answerAction = AndroidNotificationAction(
      'answer',
      'Answer',
      icon: DrawableResourceAndroidBitmap('@drawable/ic_call_answer'),
      showsUserInterface: true,
    );

    // Android decline action
    const declineAction = AndroidNotificationAction(
      'decline',
      'Decline',
      icon: DrawableResourceAndroidBitmap('@drawable/ic_call_decline'),
      cancelNotification: true,
    );

    await showNotification(
      title: '$callType Call',
      body: 'Incoming call from $callerName',
      payload: payload,
      notificationType: NotificationType.call,
      largeIconPath: callerAvatar,
      actions: [answerAction, declineAction],
    );
  }

  /// Show group message notification
  Future<void> showGroupMessageNotification({
    required String groupName,
    required String senderName,
    required String body,
    required String groupId,
    String? groupAvatar,
  }) async {
    final payload = 'type=group_message&groupId=$groupId';

    await showNotification(
      title: groupName,
      body: '$senderName: $body',
      payload: payload,
      notificationType: NotificationType.message,
      largeIconPath: groupAvatar,
    );
  }

  /// Cancel notification by ID
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Get active notifications (Android only)
  Future<List<ActiveNotification>> getActiveNotifications() async {
    if (Platform.isAndroid) {
      return await _notifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.getActiveNotifications() ??
          [];
    }
    return [];
  }

  /// Update badge count (iOS only)
  Future<void> updateBadgeCount(int count) async {
    if (Platform.isIOS) {
      // iOS badge update would be done through APNs
      // This is a placeholder for future implementation
      debugPrint('📱 Badge count: $count');
    }
  }

  /// Clear badge (iOS only)
  Future<void> clearBadge() async {
    await updateBadgeCount(0);
  }

  /// Get notification ID based on type
  int _getNotificationId(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return messageNotificationId + DateTime.now().millisecondsSinceEpoch % 1000;
      case NotificationType.call:
        return callNotificationId;
      case NotificationType.system:
        return systemNotificationId + DateTime.now().millisecondsSinceEpoch % 1000;
    }
  }

  /// Get channel ID based on type
  String _getChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return messageChannelId;
      case NotificationType.call:
        return callChannelId;
      case NotificationType.system:
        return systemChannelId;
    }
  }

  /// Get channel name based on type
  String _getChannelName(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return messageChannelName;
      case NotificationType.call:
        return callChannelName;
      case NotificationType.system:
        return systemChannelName;
    }
  }

  /// Get channel description based on type
  String _getChannelDescription(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return messageChannelDescription;
      case NotificationType.call:
        return callChannelDescription;
      case NotificationType.system:
        return systemChannelDescription;
    }
  }

  /// Background notification tap handler
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTap(NotificationResponse response) {
    debugPrint('Background notification tapped: ${response.payload}');
    // This runs in isolate, limited functionality
    // Main handling is done in onDidReceiveNotificationResponse
  }
}
