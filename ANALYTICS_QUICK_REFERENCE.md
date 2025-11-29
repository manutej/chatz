# Analytics & Crashlytics Quick Reference

Fast reference for common analytics and crashlytics operations.

## Getting Started

```dart
// Get services from DI
final analytics = getIt<AnalyticsService>();
final crashlytics = getIt<CrashlyticsService>();
final analyticsHelper = getIt<AnalyticsHelper>();
final errorHandler = getIt<ErrorHandler>();
```

---

## Authentication

```dart
// Login
await analyticsHelper.trackUserAuthentication(
  userId: user.id,
  method: 'google', // or 'apple', 'phone', 'email'
  isSignUp: false,
);

// Sign up
await analyticsHelper.trackUserAuthentication(
  userId: user.id,
  method: 'google',
  isSignUp: true,
);

// Logout
await analyticsHelper.trackUserLogout();

// Update user profile
await analyticsHelper.updateUserProfile(
  userId: user.id,
  userType: 'premium',
  totalChats: user.chats.length,
  totalMessagesSent: user.messageCount,
  walletBalance: user.wallet.balance,
  currency: 'USD',
);
```

---

## Messaging

```dart
// Send message
await analyticsHelper.trackMessageSent(
  chatId: chat.id,
  messageType: 'text', // or 'image', 'video', 'audio', 'document'
  messageLength: message.length,
  hasMedia: false,
);

// Send media
await analyticsHelper.trackMessageSent(
  chatId: chat.id,
  messageType: 'image',
  hasMedia: true,
  fileSizeBytes: file.lengthSync(),
);

// Create chat
await analyticsHelper.trackChatCreated(
  chatId: chat.id,
  chatType: 'direct', // or 'group'
  participantCount: 2,
);

// Open chat (set context)
await analyticsHelper.trackChatOpened(
  chatId: chat.id,
  chatType: 'direct',
  unreadCount: 5,
);
```

---

## Calls

```dart
final callId = uuid.v4();

// 1. Initiate call
await analyticsHelper.trackCallInitiated(
  callId: callId,
  callType: 'video', // or 'voice'
  recipientId: recipient.id,
);

// 2. Call answered
await analyticsHelper.trackCallAnswered(
  callId: callId,
  callType: 'video',
  ringDurationSeconds: 5,
);

// 3. Call ended
await analyticsHelper.trackCallEnded(
  callId: callId,
  callType: 'video',
  durationSeconds: 180,
  endReason: 'completed', // or 'cancelled', 'failed', 'rejected'
  costAmount: 0.30,
);
```

---

## Payments

```dart
// Wallet recharge
await analyticsHelper.trackWalletRecharge(
  amount: 10.0,
  currency: 'USD',
  paymentMethod: 'stripe', // or 'apple_pay', 'google_pay'
  transactionId: transaction.id,
  success: true,
);

// Call charge
await analyticsHelper.trackCallCharge(
  amount: 0.10,
  currency: 'USD',
  callDurationSeconds: 60,
  callType: 'voice',
  newBalance: wallet.balance,
);
```

---

## Feature Usage

```dart
// Track feature
await analyticsService.logFeatureUsed(
  featureName: 'voice_message',
  parameters: {
    'duration_seconds': 15,
    'chat_id': chatId,
  },
);

// Or use helper
await analyticsHelper.trackFeatureUsage(
  featureName: 'emoji_picker',
  parameters: {'source': 'chat'},
);

// Search
await analyticsService.logSearch(
  searchTerm: 'john',
  searchType: 'contacts',
  resultsCount: 3,
);

// Share
await analyticsService.logShare(
  contentType: 'message',
  method: 'native_share',
);
```

---

## Error Handling

```dart
// API Error
try {
  await api.getUser(userId);
} catch (e, stack) {
  await errorHandler.handleApiError(
    e, stack,
    endpoint: '/users/$userId',
    method: 'GET',
    statusCode: 404,
  );
}

// Auth Error
try {
  await firebaseAuth.signIn();
} catch (e, stack) {
  await errorHandler.handleAuthError(
    e, stack,
    method: 'google',
  );
}

// Upload Error
try {
  await storage.upload(file);
} catch (e, stack) {
  await errorHandler.handleUploadError(
    e, stack,
    fileType: 'image',
    fileSizeBytes: file.lengthSync(),
  );
}

// Generic Error
try {
  await someOperation();
} catch (e, stack) {
  await crashlytics.recordError(
    e, stack,
    reason: 'Failed during operation',
    fatal: false,
  );
}
```

---

## Crashlytics Context

```dart
// Set chat context
await crashlytics.setChatContext(
  chatId: chat.id,
  chatType: 'group',
  participantCount: 5,
);

// Set call context
await crashlytics.setCallContext(
  callId: call.id,
  callType: 'video',
  callStatus: 'active',
);

// Set wallet context
await crashlytics.setWalletContext(
  balance: wallet.balance,
  currency: 'USD',
);

// Set network context
await crashlytics.setNetworkContext(
  isConnected: true,
  connectionType: 'wifi',
);

// Custom keys
await crashlytics.setCustomKeys({
  'feature_flags': jsonEncode(flags),
  'app_theme': 'dark',
});
```

---

## Breadcrumbs

```dart
// Navigation
await crashlytics.logNavigation('chats', 'chat_detail');

// User action
await crashlytics.logUserAction(
  'send_message',
  params: {'type': 'text'},
);

// API call
await crashlytics.logApiCall('GET', '/users', statusCode: 200);

// Auth event
await crashlytics.logAuthEvent('login', method: 'google');

// Payment event
await crashlytics.logPaymentEvent(
  'recharge_success',
  amount: 10.0,
  currency: 'USD',
);

// Media event
await crashlytics.logMediaEvent(
  'upload_started',
  mediaType: 'image',
  sizeBytes: file.lengthSync(),
);

// Generic log
await crashlytics.log('Starting important operation');
```

---

## Execute with Error Handling

```dart
// Async
final result = await errorHandler.executeWithErrorHandling<User>(
  operation: 'fetch_user',
  task: () => api.getUser(userId),
  onError: (e) => showError('Failed to load user'),
  context: {'user_id': userId},
);

// Or with Crashlytics
final data = await crashlytics.executeWithCrashReporting<Data>(
  operation: 'load_data',
  task: () => loadData(),
  context: {'source': 'profile'},
);
```

---

## Screen Tracking

```dart
// Automatic (via route observer)
// Just add observer to MaterialApp or GoRouter

// Manual
await analytics.logScreenView(
  screenName: 'settings_privacy',
  screenClass: 'SettingsScreen',
);
```

---

## User Properties

```dart
// Individual
await analytics.setUserType('premium');
await analytics.setTotalChats(15);
await analytics.setWalletBalanceTier('high');

// Bulk
await analytics.setUserProperties(
  userType: 'free',
  totalChats: 5,
  totalMessagesSent: 100,
  walletBalanceTier: 'medium',
);
```

---

## Custom Events

```dart
await analytics.logCustomEvent(
  eventName: 'profile_picture_changed',
  parameters: {
    'source': 'camera',
    'file_size_bytes': 1024000,
  },
);
```

---

## Testing

```dart
// Test non-fatal error
await crashlytics.testNonFatalError();

// Force crash (debug only)
if (kDebugMode) {
  await crashlytics.forceCrash();
}

// Check unsent reports
final hasReports = await crashlytics.checkForUnsentReports();
```

---

## Common Patterns

### Provider/Riverpod

```dart
@riverpod
class ChatNotifier extends _$ChatNotifier {
  late final AnalyticsHelper _analytics;

  @override
  Future<Chat?> build() async {
    _analytics = ref.read(analyticsHelperProvider);
    return null;
  }

  Future<void> sendMessage(String text) async {
    try {
      // Send logic
      await _analytics.trackMessageSent(
        chatId: state.value!.id,
        messageType: 'text',
        messageLength: text.length,
      );
    } catch (e, stack) {
      await ref.read(errorHandlerProvider).handleError(
        e, stack,
        context: 'send_message',
      );
    }
  }
}
```

### Middleware

```dart
Future<T> trackOperation<T>({
  required String name,
  required Future<T> Function() task,
}) async {
  await crashlytics.log('Starting: $name');

  try {
    final result = await task();
    await analytics.logCustomEvent(
      eventName: '${name}_success',
    );
    return result;
  } catch (e, stack) {
    await crashlytics.recordError(e, stack, reason: name);
    rethrow;
  }
}
```

---

## Event Names Reference

### Authentication
- `login`
- `signup`
- `logout`
- `auth_failed`

### Messaging
- `message_sent`
- `message_read`
- `chat_created`
- `media_shared`

### Calls
- `call_initiated`
- `call_answered`
- `call_ended`
- `call_duration`

### Payments
- `wallet_recharged`
- `call_charged`
- `transaction_completed`

### Engagement
- `app_open`
- `screen_view`
- `feature_used`
- `search`
- `share`

### Errors
- `api_error`
- `upload_failed`
- `auth_failed`

---

## User Property Names

- `user_type` (free/premium)
- `total_chats` (int)
- `total_messages_sent` (int)
- `wallet_balance_tier` (empty/low/medium/high)
- `preferred_language` (ISO code)
- `registration_date` (YYYY-MM-DD)

---

## Parameter Value Conventions

### Message Types
`text`, `image`, `video`, `audio`, `document`

### Call Types
`voice`, `video`

### Chat Types
`direct`, `group`

### Auth Methods
`google`, `apple`, `phone`, `email`

### Payment Methods
`stripe`, `apple_pay`, `google_pay`, `paypal`

### End Reasons
`completed`, `cancelled`, `failed`, `rejected`, `insufficient_balance`

### Wallet Tiers
`empty`, `low`, `medium`, `high`

---

## Best Practices

### ✅ DO
```dart
// Use helpers for complete flows
await analyticsHelper.trackUserAuthentication(...);

// Set context before operations
await crashlytics.setChatContext(...);

// Log breadcrumbs
await crashlytics.log('Starting upload');

// Use specialized error handlers
await errorHandler.handleApiError(...);
```

### ❌ DON'T
```dart
// Don't log PII
await analytics.logCustomEvent(
  eventName: 'user_created',
  parameters: {
    'email': user.email, // DON'T!
  },
);

// Don't use camelCase
await analytics.logCustomEvent(eventName: 'messageSent'); // DON'T!

// Don't block UI
await analytics.logCustomEvent(...); // This is non-blocking, OK
```

---

## Debugging

### Enable Debug View
Check Firebase Console → Analytics → DebugView

### Check Logs
```dart
Logger().d('Analytics: Event logged');
```

### View in Console
- Analytics: Firebase Console → Analytics → Events
- Crashlytics: Firebase Console → Crashlytics → Dashboard

---

## Quick Setup Checklist

- [ ] Add dependencies to pubspec.yaml
- [ ] Initialize Firebase in main.dart
- [ ] Initialize Crashlytics service
- [ ] Add error handler
- [ ] Add route observer to app
- [ ] Register providers in DI
- [ ] Test with DebugView
- [ ] Test crash reporting

---

## Emergency: Disable Analytics

```dart
// Disable analytics
await analytics.setAnalyticsCollectionEnabled(false);

// Disable crashlytics
await crashlytics.setCrashlyticsCollectionEnabled(false);
```

---

**For detailed documentation, see:**
- ANALYTICS_INTEGRATION_GUIDE.md
- ANALYTICS_EVENTS_CATALOG.md
- ANALYTICS_IMPLEMENTATION_SUMMARY.md
