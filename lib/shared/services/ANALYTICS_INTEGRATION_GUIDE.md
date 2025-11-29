# Firebase Analytics & Crashlytics Integration Guide

## Overview

This guide explains how to integrate Firebase Analytics and Crashlytics into the chatz application for comprehensive tracking and crash reporting.

## Architecture

```
shared/
├── services/
│   ├── analytics_service.dart       # Main analytics service
│   ├── crashlytics_service.dart     # Main crashlytics service
│   ├── analytics_module.dart        # DI module
├── observers/
│   └── analytics_route_observer.dart # Auto screen tracking
└── utils/
    ├── analytics_helper.dart        # Helper utilities
    └── error_handler.dart           # Global error handling
```

## Setup

### 1. Add Dependencies to `pubspec.yaml`

```yaml
dependencies:
  firebase_analytics: ^10.8.9
  firebase_crashlytics: ^3.4.9
  logger: ^2.0.2+1
```

### 2. Initialize Services in `main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'shared/services/analytics_service.dart';
import 'shared/services/crashlytics_service.dart';
import 'shared/utils/error_handler.dart';
import 'injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Configure dependency injection
  await configureDependencies();

  // Initialize Crashlytics
  final crashlyticsService = getIt<CrashlyticsService>();
  final analyticsService = getIt<AnalyticsService>();

  await crashlyticsService.initialize();

  // Initialize error handler
  final errorHandler = ErrorHandler(crashlyticsService, analyticsService);
  await errorHandler.initialize();

  // Run app with error boundary
  runApp(
    ErrorBoundary(
      child: MyApp(),
    ),
  );
}
```

### 3. Add Navigation Observer

```dart
// In your MaterialApp/CupertinoApp
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final analyticsService = getIt<AnalyticsService>();
    final routeObserver = getIt<AnalyticsRouteObserver>();

    return MaterialApp(
      navigatorObservers: [
        analyticsService.observer,  // Firebase Analytics observer
        routeObserver,               // Custom route observer
      ],
      // ... rest of your app configuration
    );
  }
}
```

### 4. For GoRouter Integration

```dart
import 'package:go_router/go_router.dart';

final router = GoRouter(
  observers: [
    getIt<AnalyticsRouteObserver>(),
  ],
  routes: [
    // Your routes
  ],
);
```

## Usage Examples

### Authentication Tracking

```dart
// On user login
await analyticsService.logLogin(method: 'google');
await analyticsService.setUserId(user.id);
await analyticsService.setUserType('premium');

// Or use helper
await analyticsHelper.trackUserAuthentication(
  userId: user.id,
  method: 'google',
  isSignUp: false,
);

// On user logout
await analyticsHelper.trackUserLogout();
```

### Messaging Tracking

```dart
// Send a text message
await analyticsService.logMessageSent(
  chatId: chatId,
  messageType: 'text',
  messageLength: message.length,
  hasMedia: false,
);

// Send media message
await analyticsHelper.trackMessageSent(
  chatId: chatId,
  messageType: 'image',
  hasMedia: true,
  fileSizeBytes: imageFile.lengthSync(),
);

// Create new chat
await analyticsHelper.trackChatCreated(
  chatId: newChat.id,
  chatType: 'direct',
  participantCount: 2,
);
```

### Call Tracking

```dart
// Complete call lifecycle
final callId = uuid.v4();

// 1. Call initiated
await analyticsHelper.trackCallInitiated(
  callId: callId,
  callType: 'video',
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
  endReason: 'completed',
  costAmount: 0.30,
);
```

### Payment Tracking

```dart
// Track wallet recharge
await analyticsHelper.trackWalletRecharge(
  amount: 10.0,
  currency: 'USD',
  paymentMethod: 'stripe',
  transactionId: transaction.id,
  success: true,
);

// Track call charge
await analyticsHelper.trackCallCharge(
  amount: 0.10,
  currency: 'USD',
  callDurationSeconds: 60,
  callType: 'voice',
  newBalance: wallet.balance,
);
```

### Feature Usage Tracking

```dart
// Track feature usage
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
```

### Error Tracking

```dart
// API Error
try {
  await apiClient.get('/users/$userId');
} catch (e, stackTrace) {
  await errorHandler.handleApiError(
    e,
    stackTrace,
    endpoint: '/users/$userId',
    method: 'GET',
    statusCode: 404,
  );
}

// Authentication Error
try {
  await firebaseAuth.signInWithGoogle();
} catch (e, stackTrace) {
  await errorHandler.handleAuthError(
    e,
    stackTrace,
    method: 'google',
  );
}

// Upload Error
try {
  await storageService.uploadFile(file);
} catch (e, stackTrace) {
  await errorHandler.handleUploadError(
    e,
    stackTrace,
    fileType: 'image',
    fileSizeBytes: file.lengthSync(),
  );
}

// Generic error with context
try {
  await someOperation();
} catch (e, stackTrace) {
  await crashlyticsService.recordError(
    e,
    stackTrace,
    reason: 'Failed during profile update',
    fatal: false,
  );
}
```

### Crashlytics Context Setting

```dart
// Set chat context when entering chat
await crashlyticsService.setChatContext(
  chatId: chat.id,
  chatType: 'group',
  participantCount: 5,
);

// Set call context during call
await crashlyticsService.setCallContext(
  callId: call.id,
  callType: 'video',
  callStatus: 'active',
);

// Set wallet context
await crashlyticsService.setWalletContext(
  balance: wallet.balance,
  currency: 'USD',
);

// Set network context
await crashlyticsService.setNetworkContext(
  isConnected: true,
  connectionType: 'wifi',
);

// Set custom keys
await crashlyticsService.setCustomKeys({
  'feature_flags': jsonEncode(featureFlags),
  'app_theme': 'dark',
  'notification_enabled': true,
});
```

### Logging Breadcrumbs

```dart
// Log navigation
await crashlyticsService.logNavigation('chats', 'chat_detail');

// Log user actions
await crashlyticsService.logUserAction(
  'send_message',
  params: {'type': 'text', 'chat_id': chatId},
);

// Log API calls
await crashlyticsService.logApiCall('GET', '/api/users', statusCode: 200);

// Log authentication events
await crashlyticsService.logAuthEvent('login', method: 'google');

// Log payment events
await crashlyticsService.logPaymentEvent(
  'recharge_success',
  amount: 10.0,
  currency: 'USD',
);

// Log media events
await crashlyticsService.logMediaEvent(
  'upload_started',
  mediaType: 'image',
  sizeBytes: file.lengthSync(),
);
```

### User Properties

```dart
// Set individual properties
await analyticsService.setUserType('premium');
await analyticsService.setTotalChats(15);
await analyticsService.setTotalMessagesSent(342);
await analyticsService.setWalletBalanceTier('high');
await analyticsService.setPreferredLanguage('en');
await analyticsService.setRegistrationDate(DateTime(2024, 1, 1));

// Set multiple properties at once
await analyticsService.setUserProperties(
  userType: 'free',
  totalChats: 5,
  totalMessagesSent: 100,
  walletBalanceTier: 'medium',
  preferredLanguage: 'en',
  registrationDate: DateTime.now(),
);

// Or use helper for complete profile update
await analyticsHelper.updateUserProfile(
  userId: user.id,
  userType: 'premium',
  totalChats: user.chats.length,
  totalMessagesSent: user.messageCount,
  walletBalance: user.wallet.balance,
  currency: 'USD',
  preferredLanguage: user.language,
  registrationDate: user.createdAt,
);
```

### Automatic Screen Tracking

Screen tracking is automatic when using the route observer. But you can also manually log:

```dart
// Manual screen view
await analyticsService.logScreenView(
  screenName: 'settings_privacy',
  screenClass: 'SettingsScreen',
);
```

### Execute with Error Handling

```dart
// Async operation
final result = await errorHandler.executeWithErrorHandling<User>(
  operation: 'fetch_user_profile',
  task: () => apiClient.getUser(userId),
  onError: (error) {
    // Show error to user
    showErrorSnackbar('Failed to load profile');
  },
  context: {
    'user_id': userId,
    'retry_count': retryCount,
  },
);

// Or using Crashlytics service
final data = await crashlyticsService.executeWithCrashReporting<UserData>(
  operation: 'load_user_data',
  task: () => loadUserData(),
  context: {
    'user_id': userId,
    'source': 'profile_screen',
  },
);
```

## Events Reference

### Authentication Events

| Event Name | Parameters | Description |
|------------|------------|-------------|
| `login` | `method` | User logged in |
| `signup` | `method` | User signed up |
| `logout` | - | User logged out |
| `auth_failed` | `method`, `error_code`, `error_message` | Auth failed |

### Messaging Events

| Event Name | Parameters | Description |
|------------|------------|-------------|
| `message_sent` | `chat_id`, `message_type`, `message_length`, `has_media` | Message sent |
| `message_read` | `chat_id`, `message_id` | Message read |
| `chat_created` | `chat_id`, `chat_type`, `participant_count` | Chat created |
| `media_shared` | `media_type`, `file_size_bytes`, `chat_id` | Media shared |

### Call Events

| Event Name | Parameters | Description |
|------------|------------|-------------|
| `call_initiated` | `call_type`, `recipient_id` | Call started |
| `call_answered` | `call_type`, `call_id`, `ring_duration_seconds` | Call answered |
| `call_ended` | `call_type`, `call_id`, `duration_seconds`, `end_reason`, `cost_amount` | Call ended |
| `call_duration` | `call_type`, `duration_seconds` | Call duration tracked |

### Payment Events

| Event Name | Parameters | Description |
|------------|------------|-------------|
| `wallet_recharged` | `amount`, `currency`, `payment_method`, `transaction_id` | Wallet recharged |
| `call_charged` | `amount`, `currency`, `call_duration_seconds`, `call_type` | Call charged |
| `transaction_completed` | `transaction_id`, `amount`, `currency`, `transaction_type`, `success` | Transaction completed |

### Engagement Events

| Event Name | Parameters | Description |
|------------|------------|-------------|
| `app_open` | `source` | App opened |
| `screen_view` | `screen_name`, `screen_class` | Screen viewed |
| `feature_used` | `feature_name`, `parameters` | Feature used |
| `search` | `search_term`, `search_type`, `results_count` | Search performed |
| `share` | `content_type`, `method` | Content shared |

### Error Events

| Event Name | Parameters | Description |
|------------|------------|-------------|
| `api_error` | `endpoint`, `status_code`, `error_message`, `request_method` | API error |
| `upload_failed` | `file_type`, `file_size_bytes`, `error_reason` | Upload failed |
| `auth_failed` | `method`, `error_code`, `error_message` | Auth failed |

## User Properties Reference

| Property Name | Type | Description | Example Values |
|---------------|------|-------------|----------------|
| `user_type` | String | User subscription tier | `free`, `premium` |
| `total_chats` | Integer | Total chats user has | `5`, `20` |
| `total_messages_sent` | Integer | Total messages sent | `100`, `5000` |
| `wallet_balance_tier` | String | Wallet balance tier | `empty`, `low`, `medium`, `high` |
| `preferred_language` | String | User's language | `en`, `es`, `fr` |
| `registration_date` | Date | User registration date | `2024-01-15` |

## Crashlytics Custom Keys Reference

| Key Name | Type | Description |
|----------|------|-------------|
| `current_screen` | String | Current screen name |
| `current_chat_id` | String | Active chat ID |
| `chat_type` | String | Type of chat |
| `chat_participant_count` | Integer | Number of participants |
| `current_call_id` | String | Active call ID |
| `call_type` | String | Type of call |
| `call_status` | String | Call status |
| `wallet_balance` | Double | Current balance |
| `wallet_currency` | String | Currency code |
| `network_connected` | Boolean | Network status |
| `network_type` | String | Connection type |

## Best Practices

### 1. Privacy & PII

**DO NOT log personally identifiable information (PII):**
- Email addresses
- Phone numbers
- Full names
- Addresses
- Credit card numbers

**DO log:**
- User IDs (non-identifiable)
- Event types
- Aggregated data
- Technical metadata

```dart
// BAD - Contains PII
await analyticsService.logCustomEvent(
  eventName: 'profile_updated',
  parameters: {
    'email': user.email,  // DON'T
    'phone': user.phone,  // DON'T
  },
);

// GOOD - No PII
await analyticsService.logCustomEvent(
  eventName: 'profile_updated',
  parameters: {
    'user_id': user.id,
    'fields_updated': ['avatar', 'bio'],
  },
);
```

### 2. Event Naming

Use **snake_case** for consistency:

```dart
// GOOD
await analyticsService.logCustomEvent(eventName: 'message_sent');
await analyticsService.logCustomEvent(eventName: 'wallet_recharged');

// BAD
await analyticsService.logCustomEvent(eventName: 'MessageSent');
await analyticsService.logCustomEvent(eventName: 'wallet-recharged');
```

### 3. Breadcrumbs Strategy

Log breadcrumbs before critical operations:

```dart
// Before starting operation
await crashlyticsService.log('Starting file upload');
await crashlyticsService.setCustomKey('file_size', file.lengthSync());

try {
  await uploadFile(file);
  await crashlyticsService.log('File upload successful');
} catch (e, stackTrace) {
  await crashlyticsService.log('File upload failed');
  await crashlyticsService.recordError(e, stackTrace);
}
```

### 4. Context Setting

Set context when entering critical flows:

```dart
// Entering call
await crashlyticsService.setCallContext(
  callId: call.id,
  callType: 'video',
  callStatus: 'connecting',
);

// During call
await crashlyticsService.setCustomKey('call_status', 'active');

// Leaving call
await crashlyticsService.setCustomKey('call_status', 'ended');
```

### 5. Error Handling Hierarchy

```dart
// 1. Specific error handlers when available
await errorHandler.handleApiError(...);
await errorHandler.handleAuthError(...);
await errorHandler.handleUploadError(...);

// 2. Crashlytics specialized handlers
await crashlyticsService.recordApiError(...);
await crashlyticsService.recordCallError(...);

// 3. Generic error recording
await crashlyticsService.recordError(error, stackTrace, fatal: false);
```

## Testing

### Test Crashlytics Integration

```dart
// Send test non-fatal error
await crashlyticsService.testNonFatalError();

// Force crash (ONLY in debug mode)
if (kDebugMode) {
  await crashlyticsService.forceCrash();
}
```

### Check for Unsent Reports

```dart
final hasReports = await crashlyticsService.checkForUnsentReports();
if (hasReports) {
  await crashlyticsService.sendUnsentReports();
}
```

### Analytics Testing

```dart
// Enable debug mode in Firebase Console
// Then check DebugView in Analytics dashboard

// Reset analytics data for testing
await analyticsService.resetAnalyticsData();
```

## Debugging

### Enable Analytics Debug Logging

```dart
// In main.dart (debug mode only)
if (kDebugMode) {
  await analyticsService.setAnalyticsCollectionEnabled(true);
  Logger().i('Analytics debug mode enabled');
}
```

### Enable Crashlytics Debug Logging

Check console output for Crashlytics logs prefixed with:
- `Crashlytics:`
- `Analytics:`

### View Reports

1. **Analytics**: Firebase Console → Analytics → Events
2. **Crashlytics**: Firebase Console → Crashlytics → Dashboard
3. **Debug View**: Firebase Console → Analytics → DebugView (real-time)

## Common Patterns

### Provider/Riverpod Integration

```dart
// In your providers
@riverpod
class ChatNotifier extends _$ChatNotifier {
  late final AnalyticsHelper _analyticsHelper;

  @override
  Future<Chat?> build() async {
    _analyticsHelper = ref.read(analyticsHelperProvider);
    return null;
  }

  Future<void> sendMessage(String message) async {
    try {
      // Send message logic
      final chat = state.value;

      // Track analytics
      await _analyticsHelper.trackMessageSent(
        chatId: chat.id,
        messageType: 'text',
        messageLength: message.length,
      );
    } catch (e, stackTrace) {
      // Error handling
      await ref.read(errorHandlerProvider).handleError(
        e,
        stackTrace,
        context: 'send_message',
      );
    }
  }
}
```

### Middleware Pattern

```dart
class AnalyticsMiddleware {
  final AnalyticsService _analytics;
  final CrashlyticsService _crashlytics;

  Future<T> execute<T>({
    required String operation,
    required Future<T> Function() task,
    Map<String, dynamic>? analyticsParams,
  }) async {
    // Log start
    await _crashlytics.log('Starting: $operation');

    try {
      final result = await task();

      // Log success
      await _analytics.logCustomEvent(
        eventName: '${operation}_success',
        parameters: analyticsParams,
      );

      return result;
    } catch (e, stackTrace) {
      // Log failure
      await _analytics.logCustomEvent(
        eventName: '${operation}_failed',
        parameters: analyticsParams,
      );

      await _crashlytics.recordError(
        e,
        stackTrace,
        reason: operation,
      );

      rethrow;
    }
  }
}
```

## Performance Considerations

1. **Batch Operations**: Set multiple custom keys at once
2. **Async Logging**: All methods are async, don't block UI
3. **Debug vs Release**: Disable verbose logging in production
4. **Rate Limiting**: Firebase has automatic rate limiting

## Troubleshooting

### Events Not Appearing in Console

1. Wait 24 hours for first appearance
2. Use DebugView for real-time testing
3. Check Analytics is enabled in Firebase Console
4. Verify app is using correct Firebase project

### Crashlytics Not Receiving Reports

1. Verify Crashlytics is enabled: `setCrashlyticsCollectionEnabled(true)`
2. Check app is running in release mode for crashes
3. Send test error: `testNonFatalError()`
4. Check Firebase project configuration

### Missing User Properties

1. Ensure user ID is set: `setUserId(userId)`
2. Properties take time to process
3. Check property name length (max 24 chars)
4. Verify property value length (max 36 chars)

## Migration from Other Analytics

If migrating from other analytics solutions:

1. Map existing events to new event names
2. Update event parameters to match new schema
3. Migrate user properties
4. Test thoroughly in DebugView
5. Run dual analytics for transition period

## Additional Resources

- [Firebase Analytics Documentation](https://firebase.google.com/docs/analytics)
- [Firebase Crashlytics Documentation](https://firebase.google.com/docs/crashlytics)
- [Analytics Events Best Practices](https://firebase.google.com/docs/analytics/events)
- [Crashlytics Reports Guide](https://firebase.google.com/docs/crashlytics/get-started)
