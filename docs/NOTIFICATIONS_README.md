# Push Notifications Implementation - Chatz

Complete Firebase Cloud Messaging (FCM) integration for push notifications in the Chatz messaging app.

## Overview

This implementation provides a production-ready push notification system supporting:

- Real-time message notifications
- Incoming call notifications (voice/video)
- Group message notifications
- Message reaction notifications
- Foreground, background, and terminated state handling
- Deep linking to appropriate screens
- Custom notification sounds and channels
- Badge count management
- Multi-device token management

---

## Architecture

### Service Layer

```
shared/services/
├── notification_service.dart           # Main FCM service
├── local_notification_service.dart     # Local notifications
└── permission_service.dart             # Permission handling
```

### Data Layer

```
features/chat/data/datasources/
└── fcm_data_source.dart                # Token management in Firestore
```

### Cloud Functions

```
functions/
├── src/
│   ├── notifications/
│   │   ├── messageNotifications.ts     # Message notifications
│   │   ├── callNotifications.ts        # Call notifications
│   │   ├── groupNotifications.ts       # Group notifications
│   │   └── reactionNotifications.ts    # Reaction notifications
│   └── helpers/
│       ├── fcmHelper.ts                # FCM utilities
│       └── tokenHelper.ts              # Token utilities
```

---

## Features

### 1. NotificationService

**Main FCM service handling:**
- FCM initialization and configuration
- Permission requests (iOS/Android)
- Token retrieval and management
- Token refresh handling
- Message listeners for all app states
- Deep linking navigation
- Background message handler

**Key Methods:**
```dart
// Initialize notification service
await notificationService.initialize();

// Get current FCM token
final token = await notificationService.getToken();

// Delete token on logout
await notificationService.deleteToken();

// Subscribe to topics
await notificationService.subscribeToTopic('news');

// Check if notifications are enabled
final enabled = await notificationService.areNotificationsEnabled();
```

### 2. LocalNotificationService

**Foreground notification display:**
- Custom notification channels (messages, calls, system)
- Notification action buttons (reply, answer, decline)
- Custom sounds and vibration patterns
- Large icons and big pictures
- Badge management (iOS)
- Notification grouping

**Key Methods:**
```dart
// Show message notification
await localNotificationService.showMessageNotification(
  title: 'John Doe',
  body: 'Hey, how are you?',
  chatId: 'chat_123',
  senderAvatar: avatarUrl,
);

// Show call notification
await localNotificationService.showCallNotification(
  callerName: 'Jane Smith',
  callId: 'call_456',
  isVideoCall: true,
  callerAvatar: avatarUrl,
);

// Show group message notification
await localNotificationService.showGroupMessageNotification(
  groupName: 'Team Chat',
  senderName: 'Alice',
  body: 'Meeting at 3 PM',
  groupId: 'group_789',
);

// Cancel all notifications
await localNotificationService.cancelAllNotifications();
```

### 3. FCMDataSource

**Token management in Firestore:**
- Save device tokens with metadata
- Track multiple devices per user
- Auto-cleanup of invalid tokens
- Token refresh synchronization
- Device information tracking

**Firestore Structure:**
```
users/{userId}/deviceTokens/{token}
  - token: string
  - deviceId: string
  - deviceName: string (e.g., "Apple iPhone 14 Pro")
  - platform: string ("iOS" or "Android")
  - createdAt: Timestamp
  - updatedAt: Timestamp
```

**Key Methods:**
```dart
// Save token to Firestore
await fcmDataSource.saveDeviceToken(token);

// Remove token on logout
await fcmDataSource.removeDeviceToken(token);

// Get all tokens for a user (for Cloud Functions)
final tokens = await fcmDataSource.getUserTokens(userId);

// Clean up old tokens (30 days)
await fcmDataSource.cleanupOldTokens(daysOld: 30);
```

---

## Notification Types

### 1. Message Notification

**Foreground:**
- Show local notification with sender name and message preview
- Display sender avatar as large icon
- Show message image as big picture (if applicable)
- Reply action button
- Mark as read action button

**Background/Terminated:**
- System displays notification from FCM payload
- Tap opens chat with the sender

**Payload:**
```json
{
  "notification": {
    "title": "John Doe",
    "body": "Hey, how are you?"
  },
  "data": {
    "type": "message",
    "chatId": "chat_123",
    "messageId": "msg_456",
    "senderId": "user_789"
  }
}
```

### 2. Call Notification

**Foreground:**
- Show high-priority notification with caller name
- Display caller avatar
- Answer and Decline action buttons
- Custom call ringtone
- Full-screen intent (Android)

**Background/Terminated:**
- System displays call notification
- Tap opens call screen

**Payload:**
```json
{
  "notification": {
    "title": "Video Call",
    "body": "Incoming call from Jane Smith"
  },
  "data": {
    "type": "call",
    "callId": "call_123",
    "callerId": "user_456",
    "isVideo": "true"
  }
}
```

### 3. Group Message Notification

**Foreground:**
- Show notification with group name as title
- Display "SenderName: Message" as body
- Group avatar as large icon
- Reply action button

**Background/Terminated:**
- System displays group notification
- Tap opens group chat

**Payload:**
```json
{
  "notification": {
    "title": "Team Chat",
    "body": "Alice: Meeting at 3 PM"
  },
  "data": {
    "type": "group_message",
    "groupId": "group_123",
    "chatId": "group_123",
    "messageId": "msg_456",
    "senderId": "user_789"
  }
}
```

### 4. Reaction Notification

**Foreground:**
- Show notification with reactor name
- Display "Reacted [emoji] to your message"
- Normal priority (less intrusive)

**Background/Terminated:**
- System displays reaction notification
- Tap opens chat with the message

**Payload:**
```json
{
  "notification": {
    "title": "Bob",
    "body": "Reacted ❤️ to your message"
  },
  "data": {
    "type": "reaction",
    "chatId": "chat_123",
    "messageId": "msg_456",
    "reactorId": "user_789",
    "emoji": "❤️"
  }
}
```

---

## Setup Instructions

### 1. Firebase Console Setup

See [NOTIFICATION_SETUP.md](./NOTIFICATION_SETUP.md) for detailed Firebase Console configuration.

**Quick Steps:**
1. Enable Cloud Messaging in Firebase Console
2. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
3. Configure APNs for iOS (upload .p8 key)

### 2. iOS Configuration

**a. Enable Push Notifications in Xcode:**
1. Open `ios/Runner.xcworkspace`
2. Select Runner target
3. Go to Signing & Capabilities
4. Add Push Notifications capability
5. Add Background Modes capability (Remote notifications)

**b. Update Info.plist:**
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

**c. Create Runner.entitlements:**
```xml
<key>aps-environment</key>
<string>development</string>
```

Change to `production` for release builds.

### 3. Android Configuration

**a. Update AndroidManifest.xml:**
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="chatz_messages" />
```

**b. Add notification icons:**
- Create `ic_notification.png` in all drawable densities
- White icon with transparent background

**c. Add notification color:**
```xml
<!-- colors.xml -->
<color name="notification_color">#00C853</color>
```

### 4. Cloud Functions Setup

See [CLOUD_FUNCTIONS.md](./CLOUD_FUNCTIONS.md) for complete Cloud Functions implementation.

**Quick Steps:**
```bash
# Initialize Functions
firebase init functions

# Install dependencies
cd functions && npm install

# Deploy
firebase deploy --only functions
```

---

## Usage

### Initialization

Notification service is automatically initialized in `main.dart`:

```dart
// In main.dart
await initializeDependencies();

final notificationService = sl<NotificationService>();
await notificationService.initialize();
```

### Accessing Services

Use dependency injection to access services:

```dart
import 'package:chatz/core/di/injection.dart';

// Get NotificationService
final notificationService = sl<NotificationService>();

// Get LocalNotificationService
final localNotificationService = sl<LocalNotificationService>();

// Get FCMDataSource
final fcmDataSource = sl<FCMDataSource>();
```

### Handling Logout

Remove FCM token when user logs out:

```dart
// In your logout logic
await notificationService.deleteToken();
```

### Subscribing to Topics

Subscribe users to topics for broadcast notifications:

```dart
// Subscribe to news topic
await notificationService.subscribeToTopic('news');

// Unsubscribe
await notificationService.unsubscribeFromTopic('news');
```

---

## Navigation Handling

### Current Implementation

The `NotificationService._handleNotificationNavigation()` method handles deep linking based on notification type:

```dart
switch (type) {
  case 'message':
    router.push('/home/chat/$chatId');
    break;
  case 'call':
    router.push('/home/call/$callId?video=$isVideo');
    break;
  case 'group_message':
    router.push('/home/chat/$groupId');
    break;
  case 'reaction':
    router.push('/home/chat/$chatId');
    break;
}
```

### Navigation Context Setup

To enable navigation from notifications, you need to provide a global navigation context.

**Option 1: Global Navigation Key**

```dart
// In main.dart
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ChatzApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      navigatorKey: navigatorKey, // Add this
      routerConfig: AppRouter.router,
      // ... other config
    );
  }
}
```

Then update `NotificationService._getNavigationContext()`:

```dart
dynamic _getNavigationContext() {
  return navigatorKey.currentContext!;
}
```

**Option 2: Static Router Reference**

Store router reference globally and access it in notification service.

---

## Testing

### 1. Test Foreground Notifications

```dart
final localNotificationService = sl<LocalNotificationService>();

await localNotificationService.showMessageNotification(
  title: 'Test User',
  body: 'This is a test message',
  chatId: 'test_chat',
);
```

### 2. Test via Firebase Console

1. Go to Firebase Console > Cloud Messaging
2. Click "Send your first message"
3. Add FCM token from app logs
4. Click "Test"

### 3. Test Cloud Functions

```bash
# Start emulators
firebase emulators:start

# Trigger function by creating a document
firebase firestore:write chats/test/messages/test_msg \
  '{"text":"Hello","senderId":"user1","senderName":"John","recipientId":"user2"}'
```

### 4. Check Logs

```
🔔 Initializing NotificationService...
✅ NotificationService initialized successfully
📱 FCM Token: [token]
📬 Foreground message received: [messageId]
🔓 App opened from notification: [messageId]
```

---

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Device tokens - users can only manage their own
    match /users/{userId}/deviceTokens/{token} {
      allow read, write: if request.auth != null
                       && request.auth.uid == userId;
    }
  }
}
```

---

## Troubleshooting

### iOS: Notifications Not Received

**Checklist:**
- [ ] APNs key uploaded to Firebase
- [ ] Push Notifications capability enabled
- [ ] `aps-environment` matches build type (development/production)
- [ ] App has notification permission
- [ ] Device not in Do Not Disturb mode

### Android: Notifications Not Showing

**Checklist:**
- [ ] `google-services.json` in `android/app/`
- [ ] Notification permission granted (Android 13+)
- [ ] Notification channels created
- [ ] Icon exists in drawable folders

### Custom Sounds Not Playing

**iOS:**
- File format must be `.aiff`, `.wav`, or `.caf`
- File must be added to Xcode project
- Duration must be < 30 seconds

**Android:**
- File format should be `.mp3`, `.ogg`, or `.wav`
- File must be in `res/raw/` folder
- Filename must be lowercase, no special characters

### Navigation Not Working

**Issue:** Tapping notification doesn't navigate

**Solution:**
- Implement `_getNavigationContext()` in `NotificationService`
- Ensure global navigation key is set up
- Verify route paths match router configuration

### Tokens Not Saving to Firestore

**Checklist:**
- [ ] User is authenticated
- [ ] Firestore rules allow write to `deviceTokens`
- [ ] FCMDataSource properly initialized
- [ ] Check logs for error messages

---

## Performance Optimization

### 1. Token Cleanup

Periodically clean up old tokens:

```dart
// Run weekly/monthly
await fcmDataSource.cleanupOldTokens(daysOld: 30);
```

Or use Cloud Functions scheduled task (see CLOUD_FUNCTIONS.md).

### 2. Rate Limiting

Implement rate limiting to prevent notification spam:

```dart
// Example: Don't send if last notification was within 5 seconds
final shouldSend = await _shouldSendNotification(userId, chatId);
if (!shouldSend) return;
```

### 3. Batch Operations

When sending to multiple users (groups), batch token queries:

```dart
final tokens = await fcmDataSource.getMultipleUsersTokens(userIds);
```

---

## Security Considerations

### 1. Token Storage

- Tokens stored in Firestore with user association
- Security rules ensure users only access their own tokens
- Automatic cleanup of invalid tokens

### 2. Payload Validation

Cloud Functions validate all data before sending:

```typescript
if (!message.senderId || !message.recipientId) {
  console.log('Invalid message data');
  return null;
}
```

### 3. Rate Limiting

Implement rate limiting in Cloud Functions to prevent abuse.

---

## Production Checklist

Before deploying to production:

**Firebase:**
- [ ] Cloud Messaging enabled
- [ ] APNs production key configured
- [ ] Cloud Functions deployed
- [ ] Security rules configured

**iOS:**
- [ ] Push Notifications capability enabled
- [ ] Background Modes enabled
- [ ] `aps-environment` set to `production`
- [ ] Notification sounds added
- [ ] Icons and assets added

**Android:**
- [ ] `google-services.json` configured
- [ ] Notification icons in all densities
- [ ] Notification color configured
- [ ] ProGuard rules added
- [ ] Channels configured

**App:**
- [ ] Notification service initialized in main.dart
- [ ] Navigation context properly configured
- [ ] Logout removes FCM tokens
- [ ] Deep linking tested for all types
- [ ] Foreground/background/terminated tested

**Cloud Functions:**
- [ ] All notification triggers deployed
- [ ] Error handling implemented
- [ ] Logging configured
- [ ] Token cleanup scheduled
- [ ] Rate limiting implemented

---

## Monitoring

### 1. Firebase Console

Monitor in Firebase Console:
- Cloud Messaging > Analytics
- Function execution logs
- Crashlytics for errors

### 2. App Logs

Monitor debug logs:
```
flutter logs | grep "🔔\\|📱\\|📬\\|🔓"
```

### 3. Cloud Function Logs

```bash
firebase functions:log --only onNewMessage
```

---

## Future Enhancements

Potential improvements:

1. **Rich Notifications:**
   - Inline reply from notification
   - Quick actions (mark as read, delete)
   - Notification grouping by chat

2. **Advanced Features:**
   - Notification scheduling
   - Do Not Disturb mode
   - Custom notification sounds per contact
   - Notification importance levels

3. **Analytics:**
   - Track notification delivery rate
   - Monitor tap-through rate
   - Analyze notification engagement

4. **Optimization:**
   - Smart notification batching
   - Adaptive notification frequency
   - Context-aware notification delivery

---

## Resources

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging Plugin](https://pub.dev/packages/firebase_messaging)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [iOS Notification Programming Guide](https://developer.apple.com/documentation/usernotifications)
- [Android Notifications Guide](https://developer.android.com/develop/ui/views/notifications)

---

## Support

For issues or questions:

1. Check [NOTIFICATION_SETUP.md](./NOTIFICATION_SETUP.md) for setup instructions
2. See [CLOUD_FUNCTIONS.md](./CLOUD_FUNCTIONS.md) for backend implementation
3. Review troubleshooting section above
4. Check Firebase Console for errors
5. Review app and Cloud Function logs

---

**Implementation completed in Phase 6 as part of the Chatz messaging app architecture.**
