# Firestore Database Schema

This document defines the Firestore database structure for the Chatz application, including collections, fields, indexes, and security rules.

## Collections Overview

```
firestore/
├── users/
│   └── {userId}
├── chats/
│   ├── {chatId}
│   └── {chatId}/messages/
│       └── {messageId}
├── wallets/
│   └── {userId}
└── transactions/
    └── {transactionId}
```

## Collection: `users`

Stores user profile information and presence status.

### Document Structure

```json
{
  "id": "string (userId)",
  "phoneNumber": "string (+1234567890)",
  "displayName": "string?",
  "email": "string?",
  "photoUrl": "string? (Firebase Storage URL)",
  "about": "string? (status message)",
  "isOnline": "boolean",
  "lastSeen": "timestamp?",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Indexes

- `phoneNumber` (ascending) - for user lookup
- `isOnline` (ascending), `lastSeen` (descending) - for active users query

### Security Rules

```javascript
match /users/{userId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null && request.auth.uid == userId;
  allow update: if request.auth != null && request.auth.uid == userId;
  allow delete: if request.auth != null && request.auth.uid == userId;
}
```

---

## Collection: `chats`

Stores chat metadata and participant information.

### Document Structure

```json
{
  "id": "string (chatId)",
  "type": "string (one-to-one | group)",
  "name": "string? (group name, null for one-to-one)",
  "description": "string? (group description)",
  "photoUrl": "string? (group photo URL)",
  "participants": "array<string> (userId[])",
  "participantDetails": "map<string, object> ({userId: {displayName, photoUrl}})",
  "createdBy": "string (userId)",
  "admins": "array<string> (userId[] - for group chats)",
  "lastMessage": {
    "content": "string",
    "senderId": "string (userId)",
    "senderName": "string",
    "timestamp": "timestamp",
    "type": "string (text | image | video | audio | file)"
  },
  "unreadCount": "map<string, number> ({userId: count})",
  "isArchived": "map<string, boolean> ({userId: boolean})",
  "isPinned": "map<string, boolean> ({userId: boolean})",
  "isMuted": "map<string, boolean> ({userId: boolean})",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Indexes

- `participants` (array-contains), `updatedAt` (descending) - for user's chat list
- `participants` (array-contains), `isPinned.{userId}` (descending), `updatedAt` (descending) - for pinned chats
- `type` (ascending), `updatedAt` (descending) - for filtering by chat type

### Security Rules

```javascript
match /chats/{chatId} {
  allow read: if request.auth != null
    && request.auth.uid in resource.data.participants;
  allow create: if request.auth != null
    && request.auth.uid in request.resource.data.participants;
  allow update: if request.auth != null
    && request.auth.uid in resource.data.participants;
  allow delete: if request.auth != null
    && request.auth.uid == resource.data.createdBy;
}
```

---

## Subcollection: `chats/{chatId}/messages`

Stores individual messages within a chat.

### Document Structure

```json
{
  "id": "string (messageId)",
  "chatId": "string (parent chatId)",
  "senderId": "string (userId)",
  "senderName": "string",
  "senderPhotoUrl": "string?",
  "content": "string",
  "type": "string (text | image | video | audio | file | location)",
  "mediaUrl": "string? (Firebase Storage URL)",
  "mediaMetadata": {
    "fileName": "string?",
    "fileSize": "number? (bytes)",
    "duration": "number? (seconds for audio/video)",
    "mimeType": "string?",
    "thumbnailUrl": "string? (for video)"
  },
  "replyTo": {
    "messageId": "string",
    "content": "string",
    "senderName": "string"
  },
  "readBy": "array<string> (userId[] who read the message)",
  "deliveredTo": "array<string> (userId[] who received the message)",
  "reactions": "map<string, string> ({userId: emoji})",
  "isDeleted": "boolean",
  "deletedFor": "array<string> (userId[] - for delete for me)",
  "isEdited": "boolean",
  "editedAt": "timestamp?",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Indexes

- `chatId` (ascending), `createdAt` (descending) - for message pagination
- `chatId` (ascending), `senderId` (ascending), `createdAt` (descending) - for sender's messages
- `chatId` (ascending), `type` (ascending), `createdAt` (descending) - for media messages

### Security Rules

```javascript
match /chats/{chatId}/messages/{messageId} {
  allow read: if request.auth != null
    && request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
  allow create: if request.auth != null
    && request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants
    && request.resource.data.senderId == request.auth.uid;
  allow update: if request.auth != null
    && request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants
    && (request.resource.data.senderId == request.auth.uid ||
        request.auth.uid in request.resource.data.readBy ||
        request.auth.uid in request.resource.data.deliveredTo);
  allow delete: if request.auth != null
    && request.resource.data.senderId == request.auth.uid;
}
```

---

## Collection: `wallets`

Stores user wallet balance for microtransactions.

### Document Structure

```json
{
  "userId": "string",
  "balance": "number (credits)",
  "currency": "string (USD)",
  "lastRechargedAt": "timestamp?",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Security Rules

```javascript
match /wallets/{userId} {
  allow read: if request.auth != null && request.auth.uid == userId;
  allow create: if request.auth != null && request.auth.uid == userId;
  allow update: if false; // Only Cloud Functions can update wallet balance
  allow delete: if false;
}
```

---

## Collection: `transactions`

Stores all wallet transactions (recharges and deductions).

### Document Structure

```json
{
  "id": "string (transactionId)",
  "userId": "string",
  "type": "string (recharge | call_deduction | refund)",
  "amount": "number (credits)",
  "description": "string",
  "balanceBefore": "number",
  "balanceAfter": "number",
  "metadata": {
    "callId": "string? (for call deductions)",
    "callDuration": "number? (seconds)",
    "stripePaymentId": "string? (for recharges)"
  },
  "status": "string (pending | completed | failed | refunded)",
  "createdAt": "timestamp"
}
```

### Indexes

- `userId` (ascending), `createdAt` (descending) - for user transaction history
- `userId` (ascending), `type` (ascending), `createdAt` (descending) - for filtering by type

### Security Rules

```javascript
match /transactions/{transactionId} {
  allow read: if request.auth != null
    && request.auth.uid == resource.data.userId;
  allow create: if false; // Only Cloud Functions can create transactions
  allow update: if false;
  allow delete: if false;
}
```

---

## Firestore Composite Indexes

These indexes need to be created manually in Firebase Console or via `firestore.indexes.json`.

### Required Composite Indexes

1. **User Chats Query**
   - Collection: `chats`
   - Fields:
     - `participants` (array-contains)
     - `updatedAt` (descending)

2. **Pinned Chats Query**
   - Collection: `chats`
   - Fields:
     - `participants` (array-contains)
     - `isPinned.{userId}` (descending)
     - `updatedAt` (descending)

3. **Chat Messages Pagination**
   - Collection: `chats/{chatId}/messages`
   - Fields:
     - `chatId` (ascending)
     - `createdAt` (descending)

4. **Media Messages Query**
   - Collection: `chats/{chatId}/messages`
   - Fields:
     - `chatId` (ascending)
     - `type` (ascending)
     - `createdAt` (descending)

5. **User Transactions**
   - Collection: `transactions`
   - Fields:
     - `userId` (ascending)
     - `createdAt` (descending)

---

## Offline Persistence

Firestore offline persistence is enabled by default for mobile apps. For web:

```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

### Offline Behavior

1. **Reads**: Served from local cache when offline
2. **Writes**: Queued and synced when back online
3. **Real-time Listeners**: Continue working with cached data
4. **Optimistic Updates**: UI updates immediately, syncs later

---

## Query Patterns

### Get User's Chats (with pagination)

```dart
FirebaseFirestore.instance
  .collection('chats')
  .where('participants', arrayContains: currentUserId)
  .orderBy('updatedAt', descending: true)
  .limit(20)
  .get();
```

### Get Chat Messages (with pagination)

```dart
FirebaseFirestore.instance
  .collection('chats')
  .doc(chatId)
  .collection('messages')
  .orderBy('createdAt', descending: true)
  .limit(50)
  .get();
```

### Real-time Chat Updates

```dart
FirebaseFirestore.instance
  .collection('chats')
  .where('participants', arrayContains: currentUserId)
  .orderBy('updatedAt', descending: true)
  .snapshots();
```

### Real-time Message Updates

```dart
FirebaseFirestore.instance
  .collection('chats')
  .doc(chatId)
  .collection('messages')
  .orderBy('createdAt', descending: true)
  .limit(50)
  .snapshots();
```

### Mark Messages as Read

```dart
final batch = FirebaseFirestore.instance.batch();
for (final messageDoc in unreadMessages) {
  batch.update(messageDoc.reference, {
    'readBy': FieldValue.arrayUnion([currentUserId]),
  });
}
await batch.commit();
```

---

## Best Practices

### 1. Pagination
- Always use cursor-based pagination with `startAfter()` for infinite scroll
- Limit query results (20-50 documents per page)

### 2. Batch Operations
- Use batched writes for updating multiple documents (up to 500 operations)
- Use transactions for atomic operations (e.g., wallet deductions)

### 3. Real-time Listeners
- Clean up listeners when widgets are disposed
- Use `StreamBuilder` or Riverpod `StreamProvider` for automatic cleanup

### 4. Offline Support
- Design UI to handle cached data gracefully
- Show pending state for optimistic updates
- Queue operations when offline

### 5. Security
- Never trust client input
- Use Cloud Functions for sensitive operations (wallet updates)
- Implement rate limiting in security rules

### 6. Performance
- Minimize document reads (use caching)
- Denormalize data when appropriate (e.g., `lastMessage` in chat)
- Use subcollections for scalability (messages under chats)

---

## Migration Strategy

### Phase 1: Initial Setup
1. Create collections and security rules
2. Enable offline persistence
3. Create composite indexes

### Phase 2: Data Population
1. Create user documents on first login
2. Create chat documents for new conversations
3. Add messages to subcollections

### Phase 3: Testing
1. Test offline mode
2. Test real-time updates
3. Test pagination
4. Test security rules

### Phase 4: Production
1. Update security rules (remove test mode)
2. Enable App Check for abuse prevention
3. Set up Cloud Functions for wallet operations
4. Monitor Firestore usage and costs

---

**Generated for Chatz - WhatsApp Clone with Microtransactions**
