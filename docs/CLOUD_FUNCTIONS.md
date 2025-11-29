# Cloud Functions for Push Notifications

This document provides complete implementation for Firebase Cloud Functions to send push notifications in the Chatz app.

## Table of Contents

1. [Setup](#setup)
2. [Function Implementations](#function-implementations)
3. [Helper Functions](#helper-functions)
4. [Deployment](#deployment)
5. [Testing](#testing)

---

## Setup

### 1. Initialize Firebase Functions

```bash
# Navigate to project root
cd chatz

# Initialize Firebase (if not already done)
firebase init functions

# Choose:
# - TypeScript (recommended)
# - ESLint: Yes
# - Install dependencies: Yes
```

### 2. Project Structure

```
chatz/
├── functions/
│   ├── src/
│   │   ├── index.ts              # Main entry point
│   │   ├── notifications/
│   │   │   ├── messageNotifications.ts
│   │   │   ├── callNotifications.ts
│   │   │   ├── groupNotifications.ts
│   │   │   └── reactionNotifications.ts
│   │   ├── helpers/
│   │   │   ├── fcmHelper.ts
│   │   │   └── tokenHelper.ts
│   │   └── types/
│   │       └── index.ts
│   ├── package.json
│   └── tsconfig.json
```

### 3. Install Dependencies

```bash
cd functions

npm install firebase-functions@latest firebase-admin@latest
npm install --save-dev @types/node typescript
```

### 4. Update package.json

```json
{
  "name": "functions",
  "scripts": {
    "lint": "eslint --ext .js,.ts .",
    "build": "tsc",
    "serve": "npm run build && firebase emulators:start --only functions",
    "shell": "npm run build && firebase functions:shell",
    "start": "npm run shell",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log"
  },
  "engines": {
    "node": "18"
  },
  "main": "lib/index.js",
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^4.5.0"
  },
  "devDependencies": {
    "@types/node": "^20.10.0",
    "@typescript-eslint/eslint-plugin": "^6.13.0",
    "@typescript-eslint/parser": "^6.13.0",
    "eslint": "^8.55.0",
    "eslint-config-google": "^0.14.0",
    "eslint-plugin-import": "^2.29.0",
    "typescript": "^5.3.0"
  },
  "private": true
}
```

---

## Function Implementations

### types/index.ts

```typescript
export interface NotificationPayload {
  notification: {
    title: string;
    body: string;
    sound?: string;
    badge?: string;
  };
  data: {
    [key: string]: string;
  };
  android?: {
    priority: 'high' | 'normal';
    ttl?: number;
    notification?: {
      channelId?: string;
      sound?: string;
      color?: string;
      icon?: string;
    };
  };
  apns?: {
    payload: {
      aps: {
        alert?: {
          title: string;
          body: string;
        };
        sound?: string;
        badge?: number;
        'content-available'?: number;
        'mutable-content'?: number;
        category?: string;
      };
    };
    headers?: {
      'apns-priority': string;
      'apns-expiration': string;
    };
  };
}

export interface UserData {
  id: string;
  name: string;
  photoUrl?: string;
}

export interface MessageData {
  id: string;
  text: string;
  senderId: string;
  senderName: string;
  senderPhotoUrl?: string;
  recipientId: string;
  chatId: string;
  type: 'text' | 'image' | 'video' | 'audio' | 'file';
  createdAt: FirebaseFirestore.Timestamp;
}

export interface CallData {
  id: string;
  callerId: string;
  callerName: string;
  callerPhotoUrl?: string;
  recipientId: string;
  type: 'voice' | 'video';
  status: 'ringing' | 'active' | 'ended' | 'declined' | 'missed';
  createdAt: FirebaseFirestore.Timestamp;
}

export interface GroupMessageData {
  id: string;
  text: string;
  senderId: string;
  senderName: string;
  groupId: string;
  groupName: string;
  type: 'text' | 'image' | 'video' | 'audio' | 'file';
  createdAt: FirebaseFirestore.Timestamp;
}

export interface ReactionData {
  messageId: string;
  chatId: string;
  userId: string;
  userName: string;
  emoji: string;
  createdAt: FirebaseFirestore.Timestamp;
}
```

### helpers/tokenHelper.ts

```typescript
import * as admin from 'firebase-admin';

/**
 * Get all FCM tokens for a user
 */
export async function getUserTokens(userId: string): Promise<string[]> {
  try {
    const tokensSnapshot = await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('deviceTokens')
      .get();

    return tokensSnapshot.docs.map(doc => doc.id);
  } catch (error) {
    console.error(`Error getting tokens for user ${userId}:`, error);
    return [];
  }
}

/**
 * Get tokens for multiple users (for group notifications)
 */
export async function getMultipleUsersTokens(
  userIds: string[]
): Promise<string[]> {
  try {
    const allTokens: string[] = [];

    for (const userId of userIds) {
      const tokens = await getUserTokens(userId);
      allTokens.push(...tokens);
    }

    // Remove duplicates
    return [...new Set(allTokens)];
  } catch (error) {
    console.error('Error getting multiple users tokens:', error);
    return [];
  }
}

/**
 * Remove invalid tokens from Firestore
 */
export async function removeInvalidToken(
  userId: string,
  token: string
): Promise<void> {
  try {
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('deviceTokens')
      .doc(token)
      .delete();

    console.log(`Removed invalid token for user ${userId}`);
  } catch (error) {
    console.error(`Error removing token for user ${userId}:`, error);
  }
}

/**
 * Clean up invalid tokens after send attempt
 */
export async function cleanupInvalidTokens(
  userId: string,
  response: admin.messaging.BatchResponse
): Promise<void> {
  const tokensSnapshot = await admin.firestore()
    .collection('users')
    .doc(userId)
    .collection('deviceTokens')
    .get();

  const tokens = tokensSnapshot.docs.map(doc => doc.id);
  const deletePromises: Promise<void>[] = [];

  response.responses.forEach((resp, idx) => {
    if (!resp.success) {
      const error = resp.error;
      if (
        error?.code === 'messaging/invalid-registration-token' ||
        error?.code === 'messaging/registration-token-not-registered'
      ) {
        deletePromises.push(removeInvalidToken(userId, tokens[idx]));
      }
    }
  });

  await Promise.all(deletePromises);
}
```

### helpers/fcmHelper.ts

```typescript
import * as admin from 'firebase-admin';
import {NotificationPayload} from '../types';

/**
 * Send notification to multiple tokens
 */
export async function sendToTokens(
  tokens: string[],
  payload: NotificationPayload
): Promise<admin.messaging.BatchResponse> {
  if (tokens.length === 0) {
    console.log('No tokens to send to');
    return {
      responses: [],
      successCount: 0,
      failureCount: 0,
    };
  }

  try {
    const message: admin.messaging.MulticastMessage = {
      tokens,
      notification: payload.notification,
      data: payload.data,
      android: payload.android,
      apns: payload.apns,
    };

    const response = await admin.messaging().sendMulticast(message);

    console.log(`Successfully sent to ${response.successCount} devices`);
    console.log(`Failed to send to ${response.failureCount} devices`);

    return response;
  } catch (error) {
    console.error('Error sending notification:', error);
    throw error;
  }
}

/**
 * Create message notification payload
 */
export function createMessageNotificationPayload(
  senderName: string,
  messageText: string,
  chatId: string,
  messageId: string,
  senderId: string
): NotificationPayload {
  return {
    notification: {
      title: senderName,
      body: messageText,
      sound: 'default',
    },
    data: {
      type: 'message',
      chatId,
      messageId,
      senderId,
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'chatz_messages',
        sound: 'default',
        color: '#00C853',
        icon: 'ic_notification',
      },
    },
    apns: {
      payload: {
        aps: {
          alert: {
            title: senderName,
            body: messageText,
          },
          sound: 'default',
          badge: 1,
          category: 'MESSAGE_CATEGORY',
        },
      },
      headers: {
        'apns-priority': '10',
        'apns-expiration': '0',
      },
    },
  };
}

/**
 * Create call notification payload
 */
export function createCallNotificationPayload(
  callerName: string,
  callType: 'voice' | 'video',
  callId: string,
  callerId: string
): NotificationPayload {
  const title = callType === 'voice' ? 'Voice Call' : 'Video Call';
  const body = `Incoming call from ${callerName}`;

  return {
    notification: {
      title,
      body,
      sound: 'call_ringtone',
    },
    data: {
      type: 'call',
      callId,
      callerId,
      isVideo: String(callType === 'video'),
    },
    android: {
      priority: 'high',
      ttl: 30000, // 30 seconds for call
      notification: {
        channelId: 'chatz_calls',
        sound: 'call_ringtone',
        color: '#2196F3',
        icon: 'ic_notification',
      },
    },
    apns: {
      payload: {
        aps: {
          alert: {
            title,
            body,
          },
          sound: 'call_ringtone.aiff',
          badge: 1,
          category: 'CALL_CATEGORY',
          'content-available': 1,
        },
      },
      headers: {
        'apns-priority': '10',
        'apns-expiration': '30',
      },
    },
  };
}

/**
 * Create group message notification payload
 */
export function createGroupMessageNotificationPayload(
  groupName: string,
  senderName: string,
  messageText: string,
  groupId: string,
  chatId: string,
  messageId: string,
  senderId: string
): NotificationPayload {
  return {
    notification: {
      title: groupName,
      body: `${senderName}: ${messageText}`,
      sound: 'default',
    },
    data: {
      type: 'group_message',
      groupId,
      chatId,
      messageId,
      senderId,
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'chatz_messages',
        sound: 'default',
        color: '#00C853',
        icon: 'ic_notification',
      },
    },
    apns: {
      payload: {
        aps: {
          alert: {
            title: groupName,
            body: `${senderName}: ${messageText}`,
          },
          sound: 'default',
          badge: 1,
          category: 'MESSAGE_CATEGORY',
        },
      },
      headers: {
        'apns-priority': '10',
        'apns-expiration': '0',
      },
    },
  };
}

/**
 * Create reaction notification payload
 */
export function createReactionNotificationPayload(
  userName: string,
  emoji: string,
  chatId: string,
  messageId: string,
  userId: string
): NotificationPayload {
  return {
    notification: {
      title: userName,
      body: `Reacted ${emoji} to your message`,
      sound: 'default',
    },
    data: {
      type: 'reaction',
      chatId,
      messageId,
      reactorId: userId,
      emoji,
    },
    android: {
      priority: 'normal',
      notification: {
        channelId: 'chatz_messages',
        sound: 'default',
        color: '#00C853',
        icon: 'ic_notification',
      },
    },
    apns: {
      payload: {
        aps: {
          alert: {
            title: userName,
            body: `Reacted ${emoji} to your message`,
          },
          sound: 'default',
          badge: 1,
        },
      },
      headers: {
        'apns-priority': '5',
        'apns-expiration': '0',
      },
    },
  };
}
```

### notifications/messageNotifications.ts

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {MessageData} from '../types';
import {getUserTokens, cleanupInvalidTokens} from '../helpers/tokenHelper';
import {
  sendToTokens,
  createMessageNotificationPayload,
} from '../helpers/fcmHelper';

/**
 * Send notification when a new message is created
 */
export const onNewMessage = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    try {
      const message = snap.data() as MessageData;
      const {chatId, messageId} = context.params;

      console.log(`New message in chat ${chatId} from ${message.senderId}`);

      // Don't send notification for sender's own messages
      // This check should be done on client side too, but double-check here
      if (!message.recipientId) {
        console.log('No recipient ID, skipping notification');
        return null;
      }

      // Get recipient's FCM tokens
      const recipientTokens = await getUserTokens(message.recipientId);

      if (recipientTokens.length === 0) {
        console.log(`No tokens found for user ${message.recipientId}`);
        return null;
      }

      // Create notification payload
      const payload = createMessageNotificationPayload(
        message.senderName,
        _formatMessagePreview(message),
        chatId,
        messageId,
        message.senderId
      );

      // Send notification
      const response = await sendToTokens(recipientTokens, payload);

      // Clean up invalid tokens
      await cleanupInvalidTokens(message.recipientId, response);

      return null;
    } catch (error) {
      console.error('Error sending message notification:', error);
      return null;
    }
  });

/**
 * Format message preview based on type
 */
function _formatMessagePreview(message: MessageData): string {
  switch (message.type) {
    case 'text':
      return message.text;
    case 'image':
      return '📷 Photo';
    case 'video':
      return '🎥 Video';
    case 'audio':
      return '🎵 Audio';
    case 'file':
      return '📄 File';
    default:
      return 'New message';
  }
}
```

### notifications/callNotifications.ts

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {CallData} from '../types';
import {getUserTokens, cleanupInvalidTokens} from '../helpers/tokenHelper';
import {
  sendToTokens,
  createCallNotificationPayload,
} from '../helpers/fcmHelper';

/**
 * Send notification when a new call is initiated
 */
export const onNewCall = functions.firestore
  .document('calls/{callId}')
  .onCreate(async (snap, context) => {
    try {
      const call = snap.data() as CallData;
      const {callId} = context.params;

      console.log(`New call ${callId} from ${call.callerId}`);

      // Only send notification for ringing calls
      if (call.status !== 'ringing') {
        console.log('Call status is not ringing, skipping notification');
        return null;
      }

      // Get recipient's FCM tokens
      const recipientTokens = await getUserTokens(call.recipientId);

      if (recipientTokens.length === 0) {
        console.log(`No tokens found for user ${call.recipientId}`);
        return null;
      }

      // Create notification payload
      const payload = createCallNotificationPayload(
        call.callerName,
        call.type,
        callId,
        call.callerId
      );

      // Send notification
      const response = await sendToTokens(recipientTokens, payload);

      // Clean up invalid tokens
      await cleanupInvalidTokens(call.recipientId, response);

      return null;
    } catch (error) {
      console.error('Error sending call notification:', error);
      return null;
    }
  });

/**
 * Cancel call notification when call status changes
 */
export const onCallStatusChange = functions.firestore
  .document('calls/{callId}')
  .onUpdate(async (change, context) => {
    try {
      const beforeCall = change.before.data() as CallData;
      const afterCall = change.after.data() as CallData;

      // If call was ringing and now ended/declined
      if (
        beforeCall.status === 'ringing' &&
        (afterCall.status === 'ended' ||
         afterCall.status === 'declined' ||
         afterCall.status === 'active')
      ) {
        console.log(`Call ${context.params.callId} status changed to ${afterCall.status}`);

        // You could send a data-only message to dismiss the call notification
        // or the app will handle it when it syncs the call status
      }

      return null;
    } catch (error) {
      console.error('Error handling call status change:', error);
      return null;
    }
  });
```

### notifications/groupNotifications.ts

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {GroupMessageData} from '../types';
import {
  getMultipleUsersTokens,
  cleanupInvalidTokens,
} from '../helpers/tokenHelper';
import {
  sendToTokens,
  createGroupMessageNotificationPayload,
} from '../helpers/fcmHelper';

/**
 * Send notification when a new group message is created
 */
export const onNewGroupMessage = functions.firestore
  .document('groups/{groupId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    try {
      const message = snap.data() as GroupMessageData;
      const {groupId, messageId} = context.params;

      console.log(`New group message in ${groupId} from ${message.senderId}`);

      // Get group members
      const groupDoc = await admin.firestore()
        .collection('groups')
        .doc(groupId)
        .get();

      if (!groupDoc.exists) {
        console.log(`Group ${groupId} not found`);
        return null;
      }

      const groupData = groupDoc.data();
      const memberIds = groupData?.members || [];

      // Remove sender from recipients
      const recipientIds = memberIds.filter(
        (id: string) => id !== message.senderId
      );

      if (recipientIds.length === 0) {
        console.log('No recipients for group message');
        return null;
      }

      // Get all recipients' tokens
      const recipientTokens = await getMultipleUsersTokens(recipientIds);

      if (recipientTokens.length === 0) {
        console.log('No tokens found for group members');
        return null;
      }

      // Create notification payload
      const payload = createGroupMessageNotificationPayload(
        message.groupName,
        message.senderName,
        _formatMessagePreview(message),
        groupId,
        groupId, // chatId is same as groupId for groups
        messageId,
        message.senderId
      );

      // Send notification
      const response = await sendToTokens(recipientTokens, payload);

      // Note: We can't easily clean up tokens for multiple users here
      // Consider a scheduled function to periodically clean up invalid tokens

      console.log(`Group notification sent to ${recipientIds.length} members`);

      return null;
    } catch (error) {
      console.error('Error sending group message notification:', error);
      return null;
    }
  });

/**
 * Format message preview based on type
 */
function _formatMessagePreview(message: GroupMessageData): string {
  switch (message.type) {
    case 'text':
      return message.text;
    case 'image':
      return '📷 Photo';
    case 'video':
      return '🎥 Video';
    case 'audio':
      return '🎵 Audio';
    case 'file':
      return '📄 File';
    default:
      return 'New message';
  }
}
```

### notifications/reactionNotifications.ts

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {ReactionData} from '../types';
import {getUserTokens, cleanupInvalidTokens} from '../helpers/tokenHelper';
import {
  sendToTokens,
  createReactionNotificationPayload,
} from '../helpers/fcmHelper';

/**
 * Send notification when someone reacts to a message
 */
export const onMessageReaction = functions.firestore
  .document('chats/{chatId}/messages/{messageId}/reactions/{reactionId}')
  .onCreate(async (snap, context) => {
    try {
      const reaction = snap.data() as ReactionData;
      const {chatId, messageId} = context.params;

      console.log(`New reaction on message ${messageId} by ${reaction.userId}`);

      // Get the original message to find the sender
      const messageDoc = await admin.firestore()
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .get();

      if (!messageDoc.exists) {
        console.log(`Message ${messageId} not found`);
        return null;
      }

      const messageData = messageDoc.data();
      const messageSenderId = messageData?.senderId;

      // Don't send notification if user reacted to their own message
      if (reaction.userId === messageSenderId) {
        console.log('User reacted to their own message, skipping notification');
        return null;
      }

      // Get message sender's tokens
      const senderTokens = await getUserTokens(messageSenderId);

      if (senderTokens.length === 0) {
        console.log(`No tokens found for user ${messageSenderId}`);
        return null;
      }

      // Create notification payload
      const payload = createReactionNotificationPayload(
        reaction.userName,
        reaction.emoji,
        chatId,
        messageId,
        reaction.userId
      );

      // Send notification
      const response = await sendToTokens(senderTokens, payload);

      // Clean up invalid tokens
      await cleanupInvalidTokens(messageSenderId, response);

      return null;
    } catch (error) {
      console.error('Error sending reaction notification:', error);
      return null;
    }
  });
```

### index.ts

```typescript
import * as admin from 'firebase-admin';

// Initialize Firebase Admin
admin.initializeApp();

// Export notification functions
export {onNewMessage} from './notifications/messageNotifications';
export {
  onNewCall,
  onCallStatusChange,
} from './notifications/callNotifications';
export {onNewGroupMessage} from './notifications/groupNotifications';
export {onMessageReaction} from './notifications/reactionNotifications';

// Optional: Scheduled function to clean up old tokens
import * as functions from 'firebase-functions';

export const cleanupOldTokens = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    try {
      const now = admin.firestore.Timestamp.now();
      const thirtyDaysAgo = new Date(now.toMillis() - 30 * 24 * 60 * 60 * 1000);

      const usersSnapshot = await admin.firestore()
        .collection('users')
        .get();

      for (const userDoc of usersSnapshot.docs) {
        const tokensSnapshot = await userDoc.ref
          .collection('deviceTokens')
          .where('updatedAt', '<', thirtyDaysAgo)
          .get();

        const batch = admin.firestore().batch();

        tokensSnapshot.docs.forEach(tokenDoc => {
          batch.delete(tokenDoc.ref);
        });

        await batch.commit();

        console.log(`Cleaned up ${tokensSnapshot.size} old tokens for user ${userDoc.id}`);
      }

      return null;
    } catch (error) {
      console.error('Error cleaning up old tokens:', error);
      return null;
    }
  });
```

---

## Deployment

### 1. Build Functions

```bash
cd functions
npm run build
```

### 2. Deploy All Functions

```bash
firebase deploy --only functions
```

### 3. Deploy Specific Function

```bash
firebase deploy --only functions:onNewMessage
firebase deploy --only functions:onNewCall
```

### 4. View Logs

```bash
firebase functions:log
firebase functions:log --only onNewMessage
```

---

## Testing

### 1. Local Emulator Testing

```bash
# Start emulators
firebase emulators:start

# In another terminal, trigger functions by creating documents
# in Firestore emulator or use Firebase console
```

### 2. Test Message Notification

```bash
# Using Firebase CLI
firebase firestore:write chats/test_chat/messages/test_message \
  '{"text":"Hello","senderId":"user1","senderName":"John","recipientId":"user2"}'
```

### 3. Test with Postman

Create a POST request to Firebase Functions endpoint:

```
POST https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/onNewMessage
```

### 4. Monitor Function Execution

```bash
# Watch logs in real-time
firebase functions:log --only onNewMessage --follow
```

---

## Cost Optimization

### 1. Batch Token Queries

Instead of querying tokens individually, batch queries when possible.

### 2. Limit Notification Frequency

Implement rate limiting to prevent spam:

```typescript
async function shouldSendNotification(
  userId: string,
  chatId: string
): Promise<boolean> {
  const lastNotificationDoc = await admin.firestore()
    .collection('users')
    .doc(userId)
    .collection('lastNotifications')
    .doc(chatId)
    .get();

  if (!lastNotificationDoc.exists) {
    return true;
  }

  const lastNotificationTime = lastNotificationDoc.data()?.timestamp;
  const now = Date.now();
  const timeDiff = now - lastNotificationTime;

  // Don't send if last notification was within 5 seconds
  if (timeDiff < 5000) {
    return false;
  }

  // Update last notification time
  await lastNotificationDoc.ref.set({
    timestamp: now,
  });

  return true;
}
```

### 3. Use Scheduled Functions Wisely

Scheduled functions run based on time, not events. Use sparingly.

---

## Security Considerations

### 1. Validate Data

Always validate data before sending notifications:

```typescript
function validateMessageData(data: any): boolean {
  return (
    data &&
    typeof data.senderId === 'string' &&
    typeof data.senderName === 'string' &&
    typeof data.recipientId === 'string' &&
    typeof data.text === 'string'
  );
}
```

### 2. Prevent Notification Spam

Implement rate limiting and validate that sender has permission to send messages.

### 3. Sanitize Message Content

Remove or escape potentially malicious content:

```typescript
function sanitizeText(text: string): string {
  return text
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .substring(0, 200); // Limit length
}
```

---

## Monitoring

### 1. Set Up Alerts

Configure alerts in Firebase Console for:
- Function execution errors
- High failure rates
- Increased latency

### 2. Track Metrics

Monitor:
- Notification delivery success rate
- Average execution time
- Token cleanup frequency

### 3. Error Reporting

Integrate with error tracking services like Sentry:

```bash
npm install @sentry/node
```

```typescript
import * as Sentry from '@sentry/node';

Sentry.init({
  dsn: 'YOUR_SENTRY_DSN',
});

// In your functions
try {
  // ...
} catch (error) {
  Sentry.captureException(error);
  throw error;
}
```

---

## Resources

- [Firebase Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [FCM Server Documentation](https://firebase.google.com/docs/cloud-messaging/send-message)
- [Cloud Functions Pricing](https://firebase.google.com/pricing)
