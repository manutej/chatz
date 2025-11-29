# Push Notifications Setup Guide

This guide covers the complete setup for Firebase Cloud Messaging (FCM) push notifications in the Chatz app.

## Table of Contents

1. [Firebase Console Setup](#firebase-console-setup)
2. [iOS Configuration](#ios-configuration)
3. [Android Configuration](#android-configuration)
4. [Testing Notifications](#testing-notifications)
5. [Cloud Functions Setup](#cloud-functions-setup)

## Firebase Console Setup

### 1. Enable Firebase Cloud Messaging

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Build** > **Cloud Messaging**
4. Enable Cloud Messaging API if not already enabled

### 2. Download Configuration Files

**For Android:**
- Download `google-services.json`
- Place in `android/app/google-services.json`

**For iOS:**
- Download `GoogleService-Info.plist`
- Place in `ios/Runner/GoogleService-Info.plist`

---

## iOS Configuration

### 1. APNs Setup

**a. Create APNs Key (Recommended)**

1. Go to [Apple Developer Console](https://developer.apple.com/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Keys** > **+** (Create new key)
4. Name it "Chatz APNs Key"
5. Enable **Apple Push Notifications service (APNs)**
6. Download the key file (.p8)
7. Note the **Key ID** and **Team ID**

**b. Upload APNs Key to Firebase**

1. In Firebase Console, go to **Project Settings** > **Cloud Messaging** > **iOS app configuration**
2. Click **Upload** in the APNs Authentication Key section
3. Upload the .p8 file
4. Enter your **Key ID** and **Team ID**
5. Click **Upload**

### 2. Update Info.plist

Add the following to `ios/Runner/Info.plist` inside the `<dict>` tag:

```xml
<!-- Push Notifications -->
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>

<!-- Notification Sound (Optional) -->
<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>armv7</string>
    <string>pushkit</string>
</array>
```

### 3. Enable Push Notifications Capability

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the **Runner** target
3. Go to **Signing & Capabilities**
4. Click **+ Capability**
5. Add **Push Notifications**
6. Add **Background Modes** (if not already added)
   - Check **Remote notifications**
   - Check **Background fetch**

### 4. Add Notification Sounds (Optional)

If you want custom notification sounds:

1. Add sound files to `ios/Runner/Resources/` (create if doesn't exist)
2. Supported formats: `.aiff`, `.wav`, `.caf`
3. Name example: `call_ringtone.aiff`
4. Add to Xcode:
   - Right-click `Runner` folder in Xcode
   - **Add Files to "Runner"**
   - Select sound files
   - Ensure **Copy items if needed** is checked
   - Add to **Runner** target

### 5. Update Runner.entitlements

Create/update `ios/Runner/Runner.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>aps-environment</key>
    <string>development</string>
    <!-- Change to 'production' for release builds -->
</dict>
</plist>
```

For production builds, change `development` to `production`.

---

## Android Configuration

### 1. Update AndroidManifest.xml

Add the following to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.chatz.app">

    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

    <application
        android:name="${applicationName}"
        android:label="Chatz"
        android:icon="@mipmap/ic_launcher">

        <!-- ... other configurations ... -->

        <!-- FCM Default Channel -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="chatz_messages" />

        <!-- FCM Default Icon -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@drawable/ic_notification" />

        <!-- FCM Default Color -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/notification_color" />

        <!-- Firebase Messaging Service -->
        <service
            android:name="io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>

    </application>
</manifest>
```

### 2. Add Notification Icons

Create notification icons and place them in appropriate drawable folders:

**Icon Sizes:**
- `drawable-mdpi/ic_notification.png` (24x24 dp)
- `drawable-hdpi/ic_notification.png` (36x36 dp)
- `drawable-xhdpi/ic_notification.png` (48x48 dp)
- `drawable-xxhdpi/ic_notification.png` (72x72 dp)
- `drawable-xxxhdpi/ic_notification.png` (96x96 dp)

**Guidelines:**
- Use white icon with transparent background
- Simple, flat design
- Follow Material Design guidelines

**Location:**
```
android/app/src/main/res/
├── drawable-mdpi/ic_notification.png
├── drawable-hdpi/ic_notification.png
├── drawable-xhdpi/ic_notification.png
├── drawable-xxhdpi/ic_notification.png
└── drawable-xxxhdpi/ic_notification.png
```

### 3. Add Action Icons

For notification actions (reply, mark as read, etc.):

```
android/app/src/main/res/drawable/
├── ic_reply.xml
├── ic_check.xml
├── ic_call_answer.xml
└── ic_call_decline.xml
```

Example `ic_reply.xml`:

```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FFFFFF"
        android:pathData="M10,9V5l-7,7 7,7v-4.1c5,0 8.5,1.6 11,5.1 -1,-5 -4,-10 -11,-11z"/>
</vector>
```

### 4. Add Notification Color

Create `android/app/src/main/res/values/colors.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="notification_color">#00C853</color>
</resources>
```

### 5. Add Notification Sounds (Optional)

If you want custom notification sounds:

1. Place sound files in `android/app/src/main/res/raw/`
2. Supported formats: `.mp3`, `.ogg`, `.wav`
3. Name example: `call_ringtone.mp3`
4. File names must be lowercase with no special characters

```
android/app/src/main/res/raw/
└── call_ringtone.mp3
```

### 6. ProGuard Rules (Release Builds)

Add to `android/app/proguard-rules.pro`:

```proguard
# Firebase
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.android.gms.** { *; }

# FCM
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
```

---

## Testing Notifications

### 1. Test Foreground Notifications

```dart
import 'package:chatz/core/di/injection.dart';
import 'package:chatz/shared/services/local_notification_service.dart';

// Get service instance
final localNotificationService = sl<LocalNotificationService>();

// Show test message notification
await localNotificationService.showMessageNotification(
  title: 'John Doe',
  body: 'Hey, how are you?',
  chatId: 'test_chat_123',
);

// Show test call notification
await localNotificationService.showCallNotification(
  callerName: 'Jane Smith',
  callId: 'test_call_456',
  isVideoCall: true,
);
```

### 2. Test via Firebase Console

1. Go to Firebase Console > **Cloud Messaging**
2. Click **Send your first message**
3. Enter notification text
4. Click **Send test message**
5. Add your FCM token (get from logs when app starts)
6. Click **Test**

### 3. Test Background Notifications

Send a notification payload from Firebase Console or your backend:

```json
{
  "notification": {
    "title": "New Message",
    "body": "You have a new message"
  },
  "data": {
    "type": "message",
    "chatId": "chat_123",
    "senderId": "user_456"
  },
  "token": "YOUR_FCM_TOKEN"
}
```

### 4. Check Logs

Monitor debug console for notification-related logs:

```
🔔 Initializing NotificationService...
✅ NotificationService initialized successfully
📱 FCM Token: xxxxxx...
📬 Foreground message received: xxx
🔓 App opened from notification: xxx
```

---

## Cloud Functions Setup

See [CLOUD_FUNCTIONS.md](./CLOUD_FUNCTIONS.md) for detailed Cloud Functions implementation.

### Quick Overview

Cloud Functions will listen for Firestore changes and send notifications:

**Triggers:**
1. **New Message** → Send notification to recipient(s)
2. **New Call** → Send call notification
3. **Message Reaction** → Send reaction notification
4. **Group Message** → Send notification to all group members

**Example Function Structure:**

```typescript
// functions/src/index.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

export const onNewMessage = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();

    // Get recipient tokens
    const recipientId = message.recipientId;
    const tokensSnap = await admin.firestore()
      .collection('users')
      .doc(recipientId)
      .collection('deviceTokens')
      .get();

    const tokens = tokensSnap.docs.map(doc => doc.id);

    // Send notification
    const payload = {
      notification: {
        title: message.senderName,
        body: message.text,
      },
      data: {
        type: 'message',
        chatId: context.params.chatId,
        messageId: context.params.messageId,
      },
    };

    await admin.messaging().sendToDevice(tokens, payload);
  });
```

---

## Notification Payload Structure

### Message Notification

```json
{
  "notification": {
    "title": "Sender Name",
    "body": "Message text"
  },
  "data": {
    "type": "message",
    "chatId": "chat_id",
    "senderId": "sender_id",
    "messageId": "message_id"
  }
}
```

### Call Notification

```json
{
  "notification": {
    "title": "Voice Call",
    "body": "Incoming call from Caller Name"
  },
  "data": {
    "type": "call",
    "callId": "call_id",
    "callerId": "caller_id",
    "isVideo": "false"
  }
}
```

### Group Message Notification

```json
{
  "notification": {
    "title": "Group Name",
    "body": "Sender: Message text"
  },
  "data": {
    "type": "group_message",
    "groupId": "group_id",
    "chatId": "chat_id",
    "senderId": "sender_id",
    "messageId": "message_id"
  }
}
```

### Reaction Notification

```json
{
  "notification": {
    "title": "Reactor Name",
    "body": "Reacted ❤️ to your message"
  },
  "data": {
    "type": "reaction",
    "chatId": "chat_id",
    "messageId": "message_id",
    "reactorId": "reactor_id",
    "emoji": "❤️"
  }
}
```

---

## Troubleshooting

### iOS Issues

**Problem:** Notifications not received on iOS

**Solutions:**
1. Check APNs key is uploaded to Firebase
2. Verify `aps-environment` in entitlements (development/production)
3. Ensure Push Notifications capability is enabled
4. Check device is not in Do Not Disturb mode
5. Verify app has notification permissions

**Problem:** Custom sounds not playing

**Solutions:**
1. Ensure sound files are in correct format (.aiff, .wav, .caf)
2. Verify files are added to Xcode project
3. Check file names match in code
4. Sound duration should be < 30 seconds

### Android Issues

**Problem:** Notifications not showing

**Solutions:**
1. Check `google-services.json` is in `android/app/`
2. Verify notification permission is granted (Android 13+)
3. Check notification channels are created
4. Ensure FCM service is in AndroidManifest.xml

**Problem:** Custom icon not showing

**Solutions:**
1. Verify icon files exist in all drawable folders
2. Check icon is referenced correctly in AndroidManifest.xml
3. Ensure icon is white on transparent background
4. Rebuild app after adding icons

### General Issues

**Problem:** Token not saved to Firestore

**Solutions:**
1. Check user is authenticated
2. Verify Firestore rules allow writing to deviceTokens subcollection
3. Check FCMDataSource is properly initialized
4. Review logs for error messages

**Problem:** Navigation not working from notification

**Solutions:**
1. Implement global navigation key
2. Ensure router context is accessible
3. Check notification payload contains correct data
4. Verify route paths match app router configuration

---

## Security Rules

Add Firestore security rules for device tokens:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Device tokens
    match /users/{userId}/deviceTokens/{token} {
      // Users can only read/write their own tokens
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## Production Checklist

Before releasing to production:

- [ ] APNs production certificate/key configured
- [ ] `aps-environment` set to `production` in iOS entitlements
- [ ] Android release build tested with notifications
- [ ] Cloud Functions deployed and tested
- [ ] Firestore security rules configured
- [ ] ProGuard rules added for Android release builds
- [ ] Notification icons and sounds added
- [ ] Deep linking tested for all notification types
- [ ] Background notification handling tested
- [ ] Token cleanup mechanism implemented
- [ ] Analytics tracking for notification opens
- [ ] Error handling and logging in place

---

## Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging Plugin](https://pub.dev/packages/firebase_messaging)
- [Flutter Local Notifications Plugin](https://pub.dev/packages/flutter_local_notifications)
- [Apple Push Notification Service](https://developer.apple.com/documentation/usernotifications)
- [Android Notification Channels](https://developer.android.com/develop/ui/views/notifications/channels)
