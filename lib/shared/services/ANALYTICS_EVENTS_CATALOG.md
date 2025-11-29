# Analytics Events Catalog

Complete reference of all analytics events tracked in the chatz application.

## Event Categories

### Authentication Events

#### `login`
User successfully logged into the application.

**Parameters:**
- `login_method` (string): Authentication method used
  - Values: `google`, `apple`, `phone`, `email`

**Example:**
```dart
await analyticsService.logLogin(method: 'google');
```

**Triggers:**
- User completes Google Sign-In
- User completes Apple Sign-In
- User logs in with phone number
- User logs in with email/password

---

#### `signup`
New user created an account.

**Parameters:**
- `sign_up_method` (string): Registration method used
  - Values: `google`, `apple`, `phone`, `email`

**Example:**
```dart
await analyticsService.logSignUp(method: 'apple');
```

**Triggers:**
- User completes first-time Google Sign-In
- User completes first-time Apple Sign-In
- User registers with phone number
- User registers with email/password

---

#### `logout`
User logged out of the application.

**Parameters:** None

**Example:**
```dart
await analyticsService.logLogout();
```

**Triggers:**
- User taps logout button
- Session expires and user is logged out

---

#### `auth_failed`
Authentication attempt failed.

**Parameters:**
- `method` (string): Authentication method attempted
- `error_code` (string): Error code from auth provider
- `error_message` (string, optional): Human-readable error message

**Example:**
```dart
await analyticsService.logAuthFailed(
  method: 'google',
  errorCode: 'user_cancelled',
);
```

**Triggers:**
- User cancels OAuth flow
- Invalid credentials provided
- Network error during authentication
- Provider-specific error

---

### Messaging Events

#### `message_sent`
User sent a message in a chat.

**Parameters:**
- `chat_id` (string): Unique identifier of the chat
- `message_type` (string): Type of message
  - Values: `text`, `image`, `video`, `audio`, `document`
- `message_length` (int, optional): Character count for text messages
- `has_media` (bool, optional): Whether message includes media
- `timestamp` (int): Unix timestamp in milliseconds

**Example:**
```dart
await analyticsService.logMessageSent(
  chatId: 'chat_123',
  messageType: 'text',
  messageLength: 42,
  hasMedia: false,
);
```

**Triggers:**
- User sends text message
- User sends image
- User sends video
- User sends audio recording
- User sends document

---

#### `message_read`
User read a message in a chat.

**Parameters:**
- `chat_id` (string): Unique identifier of the chat
- `message_id` (string): Unique identifier of the message

**Example:**
```dart
await analyticsService.logMessageRead(
  chatId: 'chat_123',
  messageId: 'msg_456',
);
```

**Triggers:**
- User opens chat with unread messages
- Message becomes visible in chat view

---

#### `chat_created`
New chat was created.

**Parameters:**
- `chat_id` (string): Unique identifier of the new chat
- `chat_type` (string): Type of chat
  - Values: `direct`, `group`
- `participant_count` (int, optional): Number of participants
- `timestamp` (int): Unix timestamp in milliseconds

**Example:**
```dart
await analyticsService.logChatCreated(
  chatId: 'chat_789',
  chatType: 'group',
  participantCount: 5,
);
```

**Triggers:**
- User creates new direct chat
- User creates new group chat
- User is added to new group

---

#### `media_shared`
User shared media in a chat.

**Parameters:**
- `media_type` (string): Type of media
  - Values: `image`, `video`, `audio`, `document`
- `file_size_bytes` (int): File size in bytes
- `file_size_mb` (string): File size in MB (formatted)
- `chat_id` (string, optional): Chat where media was shared

**Example:**
```dart
await analyticsService.logMediaShared(
  mediaType: 'image',
  fileSizeBytes: 2048576,
  chatId: 'chat_123',
);
```

**Triggers:**
- User sends photo from gallery
- User sends photo from camera
- User sends video
- User sends audio recording
- User sends document

---

### Call Events

#### `call_initiated`
User started a call.

**Parameters:**
- `call_type` (string): Type of call
  - Values: `voice`, `video`
- `recipient_id` (string): ID of the call recipient
- `timestamp` (int): Unix timestamp in milliseconds

**Example:**
```dart
await analyticsService.logCallInitiated(
  callType: 'video',
  recipientId: 'user_789',
);
```

**Triggers:**
- User taps voice call button
- User taps video call button

---

#### `call_answered`
Call was answered by recipient.

**Parameters:**
- `call_type` (string): Type of call
- `call_id` (string): Unique call identifier
- `ring_duration_seconds` (int, optional): Time taken to answer

**Example:**
```dart
await analyticsService.logCallAnswered(
  callType: 'voice',
  callId: 'call_123',
  ringDurationSeconds: 5,
);
```

**Triggers:**
- Recipient accepts incoming call
- Connection established

---

#### `call_ended`
Call was terminated.

**Parameters:**
- `call_type` (string): Type of call
- `call_id` (string): Unique call identifier
- `duration_seconds` (int): Total call duration
- `duration_minutes` (string): Duration in minutes (formatted)
- `end_reason` (string): Reason for call ending
  - Values: `completed`, `cancelled`, `failed`, `rejected`, `insufficient_balance`
- `cost_amount` (double, optional): Cost charged for the call

**Example:**
```dart
await analyticsService.logCallEnded(
  callType: 'video',
  callId: 'call_123',
  durationSeconds: 180,
  endReason: 'completed',
  costAmount: 0.30,
);
```

**Triggers:**
- User ends call
- Recipient ends call
- Call fails due to network
- Call rejected by recipient
- Insufficient wallet balance

---

#### `call_duration`
Tracks call duration for analytics aggregation.

**Parameters:**
- `call_type` (string): Type of call
- `duration_seconds` (int): Call duration

**Example:**
```dart
await analyticsService.logCallDuration(
  callType: 'voice',
  durationSeconds: 120,
);
```

**Triggers:**
- Automatically logged when call ends

---

### Payment Events

#### `wallet_recharged`
User added funds to wallet.

**Parameters:**
- `amount` (double): Recharge amount
- `currency` (string): Currency code (e.g., `USD`, `EUR`)
- `payment_method` (string): Payment method used
  - Values: `stripe`, `apple_pay`, `google_pay`, `paypal`
- `transaction_id` (string, optional): Payment transaction ID
- `timestamp` (int): Unix timestamp in milliseconds

**Example:**
```dart
await analyticsService.logWalletRecharged(
  amount: 10.0,
  currency: 'USD',
  paymentMethod: 'stripe',
  transactionId: 'txn_abc123',
);
```

**Triggers:**
- Successful payment processed
- Wallet balance updated

---

#### `call_charged`
Call cost deducted from wallet.

**Parameters:**
- `amount` (double): Charge amount
- `currency` (string): Currency code
- `call_duration_seconds` (int): Call duration
- `call_type` (string): Type of call

**Example:**
```dart
await analyticsService.logCallCharged(
  amount: 0.10,
  currency: 'USD',
  callDurationSeconds: 60,
  callType: 'voice',
);
```

**Triggers:**
- Call ends and charge is applied
- Real-time charging during call

---

#### `transaction_completed`
Payment transaction completed.

**Parameters:**
- `transaction_id` (string): Transaction identifier
- `amount` (double): Transaction amount
- `currency` (string): Currency code
- `transaction_type` (string): Type of transaction
  - Values: `recharge`, `call`, `refund`
- `success` (bool, optional): Transaction success status
- `timestamp` (int): Unix timestamp in milliseconds

**Example:**
```dart
await analyticsService.logTransactionCompleted(
  transactionId: 'txn_xyz',
  amount: 5.0,
  currency: 'USD',
  transactionType: 'recharge',
  success: true,
);
```

**Triggers:**
- Payment processed
- Refund processed
- Call charge applied

---

### Engagement Events

#### `app_open`
Application was opened.

**Parameters:**
- `source` (string, optional): How app was opened
  - Values: `notification`, `direct`, `deep_link`
- `timestamp` (int): Unix timestamp in milliseconds

**Example:**
```dart
await analyticsService.logAppOpened(source: 'notification');
```

**Triggers:**
- User opens app from home screen
- User opens app from notification
- User opens app from deep link

---

#### `screen_view`
User navigated to a screen.

**Parameters:**
- `screen_name` (string): Name of the screen
- `screen_class` (string, optional): Screen class name

**Example:**
```dart
await analyticsService.logScreenView(
  screenName: 'chat_detail',
  screenClass: 'ChatDetailScreen',
);
```

**Triggers:**
- Automatically tracked via route observer
- Manual tracking for custom flows

---

#### `feature_used`
User used a specific feature.

**Parameters:**
- `feature_name` (string): Name of the feature
- Additional custom parameters as needed

**Example:**
```dart
await analyticsService.logFeatureUsed(
  featureName: 'voice_message',
  parameters: {
    'duration_seconds': 15,
    'chat_id': 'chat_123',
  },
);
```

**Triggers:**
- User records voice message
- User uses emoji picker
- User uses GIF selector
- User uses location sharing

---

#### `search`
User performed a search.

**Parameters:**
- `search_term` (string): Search query
- `search_type` (string, optional): Type of search
  - Values: `contacts`, `messages`, `chats`
- `results_count` (int, optional): Number of results

**Example:**
```dart
await analyticsService.logSearch(
  searchTerm: 'john',
  searchType: 'contacts',
  resultsCount: 3,
);
```

**Triggers:**
- User searches in contacts
- User searches in messages
- User searches in chats

---

#### `share`
User shared content.

**Parameters:**
- `content_type` (string): Type of content shared
  - Values: `message`, `media`, `contact`, `location`
- `method` (string): Share method
  - Values: `native_share`, `copy_link`, `forward`

**Example:**
```dart
await analyticsService.logShare(
  contentType: 'message',
  method: 'native_share',
);
```

**Triggers:**
- User shares message via system share sheet
- User forwards message to another chat
- User copies message link

---

### Error Events

#### `api_error`
API request failed.

**Parameters:**
- `endpoint` (string): API endpoint path
- `status_code` (int): HTTP status code
- `error_message` (string): Error message
- `request_method` (string, optional): HTTP method (GET, POST, etc.)
- `timestamp` (int): Unix timestamp in milliseconds

**Example:**
```dart
await analyticsService.logApiError(
  endpoint: '/api/users/123',
  statusCode: 404,
  errorMessage: 'User not found',
  requestMethod: 'GET',
);
```

**Triggers:**
- API returns error status code
- Network request fails
- Timeout occurs

---

#### `upload_failed`
File upload failed.

**Parameters:**
- `file_type` (string): Type of file
- `file_size_bytes` (int): File size
- `error_reason` (string): Reason for failure

**Example:**
```dart
await analyticsService.logUploadFailed(
  fileType: 'image',
  fileSizeBytes: 5242880,
  errorReason: 'Network timeout',
);
```

**Triggers:**
- Media upload fails
- Network error during upload
- File too large

---

### Custom Events

#### Custom Event Template

**Parameters:**
- `eventName` (string): Custom event name (snake_case)
- `parameters` (Map<String, dynamic>, optional): Event parameters

**Example:**
```dart
await analyticsService.logCustomEvent(
  eventName: 'profile_picture_changed',
  parameters: {
    'source': 'camera',
    'file_size_bytes': 1024000,
  },
);
```

**Common Custom Events:**
- `profile_picture_changed`
- `status_updated`
- `notification_settings_changed`
- `theme_changed`
- `language_changed`
- `chat_deleted`
- `message_deleted`
- `contact_blocked`
- `contact_unblocked`

---

## User Properties

Properties set on the user for segmentation and analysis.

### `user_type`
User's subscription tier.

**Values:** `free`, `premium`

**Example:**
```dart
await analyticsService.setUserType('premium');
```

---

### `total_chats`
Total number of chats the user has.

**Type:** Integer

**Example:**
```dart
await analyticsService.setTotalChats(15);
```

---

### `total_messages_sent`
Total number of messages the user has sent.

**Type:** Integer

**Example:**
```dart
await analyticsService.setTotalMessagesSent(342);
```

---

### `wallet_balance_tier`
User's wallet balance tier for segmentation.

**Values:** `empty`, `low`, `medium`, `high`

**Calculation:**
- `empty`: balance = 0
- `low`: balance < $5
- `medium`: balance < $20
- `high`: balance >= $20

**Example:**
```dart
await analyticsService.setWalletBalanceTier('high');
```

---

### `preferred_language`
User's preferred language.

**Type:** String (ISO language code)

**Example:**
```dart
await analyticsService.setPreferredLanguage('en');
```

---

### `registration_date`
Date when user registered.

**Type:** Date (YYYY-MM-DD format)

**Example:**
```dart
await analyticsService.setRegistrationDate(DateTime(2024, 1, 15));
```

---

## Event Naming Conventions

### Format
All event names use **snake_case**:
- ✅ `message_sent`
- ✅ `wallet_recharged`
- ❌ `messageSent`
- ❌ `WalletRecharged`

### Structure
Events follow the pattern: `noun_verb`
- `message_sent`
- `call_initiated`
- `chat_created`
- `wallet_recharged`

### Parameter Naming
Parameters also use **snake_case**:
- `chat_id`
- `message_type`
- `file_size_bytes`
- `transaction_id`

### Value Conventions
String values use **lowercase**:
- ✅ `google`, `apple`, `phone`
- ❌ `Google`, `APPLE`, `Phone`

## Parameter Limits

### Firebase Analytics Limits
- **Event name**: Max 40 characters
- **Parameter name**: Max 40 characters
- **Parameter value (string)**: Max 100 characters
- **Parameters per event**: Max 25 parameters
- **Distinct events**: 500 distinct events

### Best Practices
1. Keep event names short and descriptive
2. Use consistent naming across events
3. Don't include timestamps in event names
4. Use parameters for variations, not separate events
5. Avoid PII in event names and parameters

## Event Categories Summary

| Category | Event Count | Primary Use Case |
|----------|-------------|------------------|
| Authentication | 4 | User lifecycle tracking |
| Messaging | 4 | Chat engagement metrics |
| Call | 4 | Call usage and performance |
| Payment | 3 | Revenue and transaction tracking |
| Engagement | 5 | User interaction patterns |
| Error | 3 | Error tracking and debugging |

## Suggested Dashboards

### User Acquisition Dashboard
- `signup` (by method)
- `login` (by method)
- `registration_date` property

### Engagement Dashboard
- `app_open` (by source)
- `screen_view` (by screen_name)
- `message_sent` (by message_type)
- `feature_used` (by feature_name)

### Revenue Dashboard
- `wallet_recharged` (amount, method)
- `call_charged` (amount, duration)
- `transaction_completed` (by type)
- `wallet_balance_tier` property

### Call Analytics Dashboard
- `call_initiated` (by type)
- `call_answered` (ring duration)
- `call_ended` (by end_reason, duration)
- `call_duration` distribution

### Error Monitoring Dashboard
- `api_error` (by endpoint, status_code)
- `upload_failed` (by file_type)
- `auth_failed` (by method)

## Funnels to Track

### Sign-Up Funnel
1. App opened
2. Sign-up initiated
3. Sign-up completed
4. First chat created

### Messaging Funnel
1. Chat opened
2. Message typed
3. Message sent
4. Message delivered

### Wallet Recharge Funnel
1. Wallet viewed
2. Recharge initiated
3. Payment method selected
4. Payment completed
5. Wallet updated

### Call Funnel
1. Call initiated
2. Call ringing
3. Call answered
4. Call active
5. Call ended

## Integration Checklist

- [ ] All authentication flows tracked
- [ ] Message sending tracked
- [ ] Media sharing tracked
- [ ] Chat creation tracked
- [ ] Call lifecycle tracked
- [ ] Payment events tracked
- [ ] Error events tracked
- [ ] User properties set on login
- [ ] User properties updated on changes
- [ ] Screen views automatically tracked
- [ ] Custom events for key features
- [ ] Event parameters validated
- [ ] PII excluded from all events
- [ ] Event naming conventions followed
- [ ] Events tested in DebugView
