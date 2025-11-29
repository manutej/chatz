# Push Notifications Architecture

Visual guide to the Chatz notification system architecture.

---

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         CHATZ APP                               │
│                                                                 │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐ │
│  │ NotificationSvc  │  │LocalNotifSvc     │  │FCMDataSource │ │
│  │                  │  │                  │  │              │ │
│  │ - Init FCM       │  │ - Channels       │  │ - Save token │ │
│  │ - Get token      │  │ - Display notif  │  │ - Query      │ │
│  │ - Handle msgs    │  │ - Actions        │  │ - Cleanup    │ │
│  │ - Navigate       │  │ - Sounds         │  │              │ │
│  └──────────────────┘  └──────────────────┘  └──────────────┘ │
│           │                     │                     │         │
└───────────┼─────────────────────┼─────────────────────┼─────────┘
            │                     │                     │
            ▼                     ▼                     ▼
   ┌────────────────┐    ┌────────────────┐   ┌────────────────┐
   │ Firebase       │    │ Flutter Local  │   │ Firestore      │
   │ Messaging      │    │ Notifications  │   │ (Tokens)       │
   └────────────────┘    └────────────────┘   └────────────────┘
            │                                          ▲
            │                                          │
            ▼                                          │
   ┌─────────────────────────────────────────────────┐│
   │         FIREBASE CLOUD MESSAGING (FCM)          ││
   └─────────────────────────────────────────────────┘│
            │                                          │
            │                                          │
            ▼                                          │
   ┌─────────────────────────────────────────────────┐│
   │         CLOUD FUNCTIONS (Node.js)               ││
   │                                                  ││
   │  ┌──────────────────────────────────────────┐  ││
   │  │ Firestore Triggers                       │  ││
   │  │                                          │  ││
   │  │ • onNewMessage → Send notification      │  ││
   │  │ • onNewCall → Send call notification    │  ││
   │  │ • onNewGroupMessage → Send to group     │  ││
   │  │ • onMessageReaction → Send reaction     │  ││
   │  └──────────────────────────────────────────┘  ││
   │                                                  ││
   │  Gets tokens from Firestore ─────────────────────┘
   │  Sends FCM messages                              │
   └──────────────────────────────────────────────────┘
            │
            ▼
   ┌─────────────────────────────────────────────────┐
   │         APNs (iOS) / FCM (Android)              │
   └─────────────────────────────────────────────────┘
            │
            ▼
   ┌─────────────────────────────────────────────────┐
   │         USER DEVICE(S)                          │
   │  Notification appears on all user's devices     │
   └─────────────────────────────────────────────────┘
```

---

## Message Flow

### 1. User Sends Message

```
User A Device                Firestore              Cloud Functions
     │                          │                         │
     │  1. Create message       │                         │
     │─────────────────────────>│                         │
     │                          │                         │
     │                          │  2. Trigger onCreate    │
     │                          │────────────────────────>│
     │                          │                         │
     │                          │<───── 3. Get recipient ─┤
     │                          │       tokens            │
     │                          │                         │
     │                          │                    4. Send FCM
     │                          │                    notification
     │                          │                         │
     ▼                          ▼                         ▼

User B Devices (All)                              FCM / APNs
     │                                                 │
     │<─────────── 5. Push notification ──────────────┤
     │                                                 │
     │  6. Display notification                       │
     │  (foreground/background/terminated)            │
     │                                                 │
     │  7. User taps notification                     │
     │                                                 │
     │  8. Navigate to chat screen                    │
     ▼                                                 ▼
```

---

## Service Initialization Flow

```
App Startup
    │
    ▼
main.dart
    │
    ├──> Firebase.initializeApp()
    │
    ├──> initializeDependencies()
    │    │
    │    ├──> Register FirebaseMessaging
    │    ├──> Register FlutterLocalNotifications
    │    ├──> Register DeviceInfoPlugin
    │    ├──> Register NotificationService
    │    ├──> Register LocalNotificationService
    │    └──> Register FCMDataSource
    │
    └──> notificationService.initialize()
         │
         ├──> Set background message handler
         │
         ├──> localNotificationService.initialize()
         │    │
         │    ├──> Initialize Android/iOS settings
         │    └──> Create notification channels (Android)
         │
         ├──> Request permissions
         │    │
         │    └──> iOS: Alert, Badge, Sound
         │         Android: POST_NOTIFICATIONS (13+)
         │
         ├──> Get FCM token
         │
         ├──> Save token to Firestore
         │    │
         │    └──> fcmDataSource.saveDeviceToken()
         │         │
         │         └──> users/{userId}/deviceTokens/{token}
         │
         ├──> Setup token refresh listener
         │    │
         │    └──> On token refresh → Save new token
         │
         └──> Setup message listeners
              │
              ├──> onMessage (foreground)
              ├──> onMessageOpenedApp (background)
              └──> getInitialMessage (terminated)
```

---

## App State Handling

### Foreground State (App Open)

```
FCM Message
    │
    ▼
FirebaseMessaging.onMessage
    │
    ▼
NotificationService._handleForegroundMessage()
    │
    ├──> Parse message data
    │
    └──> LocalNotificationService.showNotification()
         │
         ├──> Determine notification type
         ├──> Build notification with actions
         ├──> Display local notification
         └──> User sees notification in notification tray
              │
              └──> User taps notification
                   │
                   └──> Navigate to screen
```

### Background State (App Minimized)

```
FCM Message
    │
    ▼
firebaseMessagingBackgroundHandler()
    │
    ├──> Process data-only message (if needed)
    └──> System displays notification
         │
         └──> User taps notification
              │
              ▼
         FirebaseMessaging.onMessageOpenedApp
              │
              ▼
         NotificationService._handleMessageOpenedApp()
              │
              └──> Navigate to screen
```

### Terminated State (App Closed)

```
FCM Message
    │
    ▼
System displays notification
    │
    └──> User taps notification
         │
         ▼
    App launches
         │
         ▼
    NotificationService.initialize()
         │
         └──> getInitialMessage()
              │
              └──> Navigate to screen
```

---

## Token Management Flow

### Save Token

```
User Login
    │
    ▼
NotificationService.initialize()
    │
    └──> getToken()
         │
         └──> FCMDataSource.saveDeviceToken(token)
              │
              └──> Firestore.set()
                   │
                   └──> users/{userId}/deviceTokens/{token}
                        {
                          token: "fcm_token_xxx",
                          deviceId: "device_123",
                          deviceName: "iPhone 14 Pro",
                          platform: "iOS",
                          createdAt: Timestamp,
                          updatedAt: Timestamp
                        }
```

### Token Refresh

```
FCM Token Changes
    │
    ▼
FirebaseMessaging.onTokenRefresh
    │
    └──> NotificationService receives new token
         │
         └──> FCMDataSource.saveDeviceToken(newToken)
              │
              └──> Update Firestore with new token
```

### Delete Token

```
User Logout
    │
    └──> NotificationService.deleteToken()
         │
         ├──> FCMDataSource.removeDeviceToken(token)
         │    │
         │    └──> Delete from Firestore
         │
         └──> FirebaseMessaging.deleteToken()
              │
              └──> Unregister from FCM
```

---

## Cloud Functions Flow

### Message Notification

```
User sends message
    │
    ▼
Firestore: chats/{chatId}/messages/{messageId}
    │
    ▼
Cloud Function: onNewMessage
    │
    ├──> Get message data
    ├──> Get recipient ID
    ├──> Query recipient tokens
    │    │
    │    └──> Firestore: users/{recipientId}/deviceTokens
    │
    ├──> Build notification payload
    │    {
    │      notification: { title, body },
    │      data: { type, chatId, messageId, senderId },
    │      android: { ... },
    │      apns: { ... }
    │    }
    │
    ├──> Send to all recipient tokens
    │    │
    │    └──> admin.messaging().sendMulticast()
    │
    └──> Clean up invalid tokens
         │
         └──> If token invalid → Remove from Firestore
```

### Call Notification

```
User initiates call
    │
    ▼
Firestore: calls/{callId}
    │
    ▼
Cloud Function: onNewCall
    │
    ├──> Get call data
    ├──> Check status === 'ringing'
    ├──> Get recipient ID
    ├──> Query recipient tokens
    │
    ├──> Build call notification payload
    │    {
    │      notification: { title: "Voice Call", body: "..." },
    │      data: { type: "call", callId, callerId, isVideo },
    │      android: { priority: "high", ttl: 30000 },
    │      apns: { priority: "10" }
    │    }
    │
    └──> Send high-priority notification
```

### Group Message Notification

```
User sends group message
    │
    ▼
Firestore: groups/{groupId}/messages/{messageId}
    │
    ▼
Cloud Function: onNewGroupMessage
    │
    ├──> Get message data
    ├──> Get group data
    ├──> Get group member IDs (except sender)
    ├──> Query all members' tokens
    │
    ├──> Build group notification payload
    │    {
    │      notification: { title: "Group Name", body: "Sender: Message" },
    │      data: { type: "group_message", groupId, chatId, ... }
    │    }
    │
    └──> Send to all member tokens
```

---

## Notification Channel Architecture (Android)

```
┌─────────────────────────────────────────────────────────┐
│                  Notification Channels                  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ MESSAGES CHANNEL (chatz_messages)               │   │
│  │                                                 │   │
│  │ Importance: High                                │   │
│  │ Sound: Default                                  │   │
│  │ Vibration: Yes                                  │   │
│  │ LED: Green (#00C853)                            │   │
│  │ Badge: Yes                                      │   │
│  │                                                 │   │
│  │ Used for: Personal & Group Messages            │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ CALLS CHANNEL (chatz_calls)                     │   │
│  │                                                 │   │
│  │ Importance: Max                                 │   │
│  │ Sound: Custom (call_ringtone)                   │   │
│  │ Vibration: Pattern [0, 1000, 500, 1000]        │   │
│  │ LED: Blue (#2196F3)                             │   │
│  │ Badge: Yes                                      │   │
│  │                                                 │   │
│  │ Used for: Incoming Voice/Video Calls           │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ SYSTEM CHANNEL (chatz_system)                   │   │
│  │                                                 │   │
│  │ Importance: Default                             │   │
│  │ Sound: Default                                  │   │
│  │ Vibration: No                                   │   │
│  │ Badge: No                                       │   │
│  │                                                 │   │
│  │ Used for: App updates, announcements           │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Data Structure

### Firestore Collections

```
firestore
│
├── users
│   └── {userId}
│       ├── deviceTokens
│       │   └── {token}
│       │       ├── token: string
│       │       ├── deviceId: string
│       │       ├── deviceName: string
│       │       ├── platform: string
│       │       ├── createdAt: Timestamp
│       │       └── updatedAt: Timestamp
│       │
│       └── ... (other user data)
│
├── chats
│   └── {chatId}
│       └── messages
│           └── {messageId}
│               ├── text: string
│               ├── senderId: string
│               ├── senderName: string
│               ├── recipientId: string
│               ├── type: string
│               └── createdAt: Timestamp
│
├── groups
│   └── {groupId}
│       ├── name: string
│       ├── members: array
│       └── messages
│           └── {messageId}
│               ├── text: string
│               ├── senderId: string
│               ├── senderName: string
│               └── createdAt: Timestamp
│
└── calls
    └── {callId}
        ├── callerId: string
        ├── callerName: string
        ├── recipientId: string
        ├── type: string (voice/video)
        ├── status: string (ringing/active/ended)
        └── createdAt: Timestamp
```

---

## Security Architecture

```
┌───────────────────────────────────────────────────┐
│              Security Layers                      │
├───────────────────────────────────────────────────┤
│                                                   │
│  1. Firestore Security Rules                     │
│     │                                             │
│     └──> Device Tokens:                          │
│          Only authenticated users can R/W        │
│          Only own tokens accessible              │
│                                                   │
│  2. Cloud Functions Validation                   │
│     │                                             │
│     ├──> Validate sender ID                      │
│     ├──> Validate recipient ID                   │
│     ├──> Validate message data                   │
│     └──> Rate limiting                           │
│                                                   │
│  3. App-Level Security                           │
│     │                                             │
│     ├──> Token deletion on logout                │
│     ├──> Secure token storage                    │
│     └──> Permission checks                       │
│                                                   │
│  4. FCM Security                                 │
│     │                                             │
│     ├──> Token encryption in transit             │
│     ├──> APNs certificate/key validation         │
│     └──> Server key protection                   │
│                                                   │
└───────────────────────────────────────────────────┘
```

---

## Performance Optimization

```
┌───────────────────────────────────────────────────┐
│          Performance Optimizations                │
├───────────────────────────────────────────────────┤
│                                                   │
│  1. Token Management                             │
│     ├──> Batch token queries                     │
│     ├──> Cache tokens in memory (if needed)      │
│     └──> Auto-cleanup invalid tokens             │
│                                                   │
│  2. Cloud Functions                              │
│     ├──> Efficient Firestore queries             │
│     ├──> Batch FCM sends                         │
│     └──> Early return for invalid data           │
│                                                   │
│  3. Notification Display                         │
│     ├──> Lazy initialization                     │
│     ├──> Reuse notification builders             │
│     └──> Optimize image loading                  │
│                                                   │
│  4. Network Efficiency                           │
│     ├──> Minimize payload size                   │
│     ├──> Use data-only messages when possible    │
│     └──> Implement message TTL                   │
│                                                   │
└───────────────────────────────────────────────────┘
```

---

## Error Handling Flow

```
Error Occurs
    │
    ├──> Invalid Token
    │    │
    │    ├──> Log error
    │    ├──> Remove from Firestore
    │    └──> Continue with valid tokens
    │
    ├──> Permission Denied
    │    │
    │    ├──> Log warning
    │    ├──> Show user message
    │    └──> Gracefully degrade
    │
    ├──> Network Error
    │    │
    │    ├──> Log error
    │    ├──> Retry with exponential backoff
    │    └──> Queue for later (if critical)
    │
    └──> Unknown Error
         │
         ├──> Log error with context
         ├──> Send to error tracking (Sentry)
         └──> Display generic error to user
```

---

## Monitoring & Analytics

```
┌───────────────────────────────────────────────────┐
│              Monitoring Points                    │
├───────────────────────────────────────────────────┤
│                                                   │
│  Firebase Console                                │
│  ├──> Cloud Messaging Analytics                  │
│  ├──> Function Execution Logs                    │
│  ├──> Crashlytics Reports                        │
│  └──> Performance Monitoring                     │
│                                                   │
│  App Logs                                        │
│  ├──> 🔔 Initialization status                   │
│  ├──> 📱 Token events                            │
│  ├──> 📬 Message received                        │
│  └──> 🔓 Notification tapped                     │
│                                                   │
│  Cloud Function Logs                             │
│  ├──> Function invocations                       │
│  ├──> Token queries                              │
│  ├──> FCM send results                           │
│  └──> Error rates                                │
│                                                   │
│  Metrics to Track                                │
│  ├──> Notification delivery rate                 │
│  ├──> Average delivery time                      │
│  ├──> Tap-through rate                           │
│  ├──> Token refresh frequency                    │
│  └──> Error rates by type                        │
│                                                   │
└───────────────────────────────────────────────────┘
```

---

## Scalability Considerations

```
┌───────────────────────────────────────────────────┐
│              Scaling Strategy                     │
├───────────────────────────────────────────────────┤
│                                                   │
│  Small Scale (< 10K users)                       │
│  ├──> Single region deployment                   │
│  ├──> Standard Cloud Functions                   │
│  └──> Basic Firestore queries                    │
│                                                   │
│  Medium Scale (10K - 100K users)                 │
│  ├──> Multi-region deployment                    │
│  ├──> Optimized token queries                    │
│  ├──> Scheduled cleanup functions                │
│  └──> Notification batching                      │
│                                                   │
│  Large Scale (> 100K users)                      │
│  ├──> Global CDN distribution                    │
│  ├──> Token caching layer                        │
│  ├──> Advanced rate limiting                     │
│  ├──> Message queue (Pub/Sub)                    │
│  └──> Horizontal function scaling                │
│                                                   │
└───────────────────────────────────────────────────┘
```

---

This architecture provides a complete, scalable, and production-ready push notification system for the Chatz messaging app.
