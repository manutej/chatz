# Firestore Integration Guide

Complete guide for the Firestore database integration implemented in Chatz.

## Overview

This integration provides a complete, production-ready Firestore implementation with:
- Real-time chat and message streaming
- Offline persistence and sync
- Cursor-based pagination
- Batch operations for performance
- Clean architecture with domain/data/presentation layers
- Riverpod state management
- Comprehensive error handling

## File Structure

```
chatz/
├── docs/
│   ├── FIRESTORE_SCHEMA.md              # Database schema documentation
│   └── FIRESTORE_INTEGRATION_GUIDE.md   # This file
├── lib/features/chat/
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── chat_entity.dart         # Chat business model
│   │   │   ├── message_entity.dart      # Message business model
│   │   │   └── participant_entity.dart  # Participant business model
│   │   ├── repositories/
│   │   │   ├── chat_repository.dart     # Chat repository interface
│   │   │   └── message_repository.dart  # Message repository interface
│   │   └── usecases/
│   │       ├── get_user_chats.dart      # Get user's chats
│   │       ├── get_chat_messages.dart   # Get chat messages
│   │       ├── send_message.dart        # Send message
│   │       ├── create_chat.dart         # Create chat
│   │       └── mark_messages_as_read.dart # Mark messages as read
│   ├── data/
│   │   ├── models/
│   │   │   ├── chat_model.dart          # Chat Firestore model
│   │   │   ├── message_model.dart       # Message Firestore model
│   │   │   └── participant_model.dart   # Participant Firestore model
│   │   ├── datasources/
│   │   │   ├── chat_remote_data_source.dart    # Chat Firestore queries
│   │   │   └── message_remote_data_source.dart # Message Firestore queries
│   │   └── repositories/
│   │       ├── chat_repository_impl.dart        # Chat repository implementation
│   │       └── message_repository_impl.dart     # Message repository implementation
│   └── presentation/
│       └── providers/
│           └── chat_providers.dart      # Riverpod providers
├── firestore.indexes.json               # Firestore composite indexes
├── firestore.rules                      # Firestore security rules
└── generate_code.sh                     # Code generation script
```

## Setup Instructions

### 1. Enable Firestore Offline Persistence

Add to `lib/main.dart` before `runApp()`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await initializeDependencies();
  runApp(const ProviderScope(child: MyApp()));
}
```

### 2. Deploy Firestore Indexes

```bash
# Deploy indexes to Firebase
firebase deploy --only firestore:indexes

# Or manually create in Firebase Console using firestore.indexes.json
```

### 3. Deploy Security Rules

```bash
# Deploy security rules to Firebase
firebase deploy --only firestore:rules

# Or manually copy from firestore.rules to Firebase Console
```

### 4. Generate Model Code

```bash
# Run code generation for JSON serialization
./generate_code.sh

# Or manually:
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates:
- `lib/features/chat/data/models/chat_model.g.dart`
- `lib/features/chat/data/models/message_model.g.dart`
- `lib/features/chat/data/models/participant_model.g.dart`

## Usage Examples

### Get User's Chats (Real-time)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatz/features/chat/presentation/providers/chat_providers.dart';

class ChatsListScreen extends ConsumerWidget {
  final String userId;

  const ChatsListScreen({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsyncValue = ref.watch(userChatsStreamProvider(userId));

    return chatsAsyncValue.when(
      data: (chatsResult) => chatsResult.fold(
        (failure) => ErrorWidget(failure.message),
        (chats) => ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            return ChatListItem(chat: chat);
          },
        ),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error.toString()),
    );
  }
}
```

### Get Chat Messages (Real-time)

```dart
class ChatScreen extends ConsumerWidget {
  final String chatId;

  const ChatScreen({required this.chatId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsyncValue = ref.watch(chatMessagesStreamProvider(chatId));

    return messagesAsyncValue.when(
      data: (messagesResult) => messagesResult.fold(
        (failure) => ErrorWidget(failure.message),
        (messages) => ListView.builder(
          reverse: true, // Show latest at bottom
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return MessageBubble(message: message);
          },
        ),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error.toString()),
    );
  }
}
```

### Send a Text Message

```dart
Future<void> sendTextMessage({
  required WidgetRef ref,
  required String chatId,
  required String content,
}) async {
  final sendMessage = ref.read(sendMessageProvider);
  final currentUser = ref.read(currentUserProvider);

  final params = SendMessageParams(
    chatId: chatId,
    senderId: currentUser.id,
    senderName: currentUser.displayName ?? 'Unknown',
    senderPhotoUrl: currentUser.photoUrl,
    content: content,
    type: MessageType.text,
  );

  final result = await sendMessage(params);

  result.fold(
    (failure) => showErrorSnackbar(failure.message),
    (message) => print('Message sent: ${message.id}'),
  );
}
```

### Create One-to-One Chat

```dart
Future<void> startChatWithUser({
  required WidgetRef ref,
  required String otherUserId,
  required String otherUserName,
  String? otherUserPhotoUrl,
}) async {
  final createChat = ref.read(createChatProvider);
  final currentUser = ref.read(currentUserProvider);

  final params = CreateOneToOneChatParams(
    currentUserId: currentUser.id,
    otherUserId: otherUserId,
    currentUserName: currentUser.displayName ?? 'You',
    otherUserName: otherUserName,
    currentUserPhotoUrl: currentUser.photoUrl,
    otherUserPhotoUrl: otherUserPhotoUrl,
  );

  final result = await createChat.createOneToOne(params);

  result.fold(
    (failure) => showErrorSnackbar(failure.message),
    (chat) {
      // Navigate to chat screen
      context.push('/chat/${chat.id}');
    },
  );
}
```

### Mark Messages as Read

```dart
Future<void> markChatMessagesAsRead({
  required WidgetRef ref,
  required String chatId,
  required List<String> messageIds,
}) async {
  final markAsRead = ref.read(markMessagesAsReadProvider);
  final currentUser = ref.read(currentUserProvider);

  final params = MarkMessagesAsReadParams(
    chatId: chatId,
    userId: currentUser.id,
    messageIds: messageIds,
  );

  await markAsRead(params);
}
```

### Send Media Message

```dart
Future<void> sendImageMessage({
  required WidgetRef ref,
  required String chatId,
  required String imagePath,
  String? caption,
}) async {
  final repository = ref.read(messageRepositoryProvider);
  final currentUser = ref.read(currentUserProvider);

  final result = await repository.sendMediaMessage(
    chatId: chatId,
    senderId: currentUser.id,
    senderName: currentUser.displayName ?? 'Unknown',
    senderPhotoUrl: currentUser.photoUrl,
    filePath: imagePath,
    type: MessageType.image,
    caption: caption,
  );

  result.fold(
    (failure) => showErrorSnackbar(failure.message),
    (message) => print('Image sent: ${message.mediaUrl}'),
  );
}
```

### Pagination (Load More Messages)

```dart
class ChatMessagesState extends StateNotifier<AsyncValue<List<MessageEntity>>> {
  final MessageRepository repository;
  DocumentSnapshot? _lastDocument;
  final String chatId;
  bool _hasMore = true;

  ChatMessagesState(this.repository, this.chatId) : super(const AsyncValue.loading());

  Future<void> loadMore() async {
    if (!_hasMore) return;

    final result = await repository.getMessagesPaginated(
      chatId: chatId,
      limit: 50,
      lastDocument: _lastDocument,
    );

    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (newMessages) {
        if (newMessages.isEmpty) {
          _hasMore = false;
        } else {
          // Update _lastDocument for next pagination
          // Combine with existing messages
          state.whenData((currentMessages) {
            state = AsyncValue.data([...currentMessages, ...newMessages]);
          });
        }
      },
    );
  }
}
```

## Key Features

### 1. Real-time Updates

All streams automatically update when data changes in Firestore:

- **User's chats**: Updates when new messages arrive, chats are archived, etc.
- **Chat messages**: Updates when new messages are sent, edited, deleted, or reactions are added

### 2. Offline Support

Firestore automatically handles offline mode:

- **Reads**: Served from local cache when offline
- **Writes**: Queued and synced when back online
- **Optimistic updates**: UI updates immediately, syncs later

### 3. Pagination

Cursor-based pagination for efficient message loading:

```dart
final messages = await repository.getMessagesPaginated(
  chatId: chatId,
  limit: 50,
  lastDocument: previousLastDocument,
);
```

### 4. Batch Operations

Efficient batch updates for marking messages as read:

```dart
// Marks up to 500 messages in a single batch
await repository.markMessagesAsRead(
  chatId: chatId,
  userId: currentUserId,
  messageIds: messageIds,
);
```

### 5. Error Handling

All operations return `Either<Failure, Success>`:

```dart
result.fold(
  (failure) => handleError(failure),
  (success) => handleSuccess(success),
);
```

Failure types:
- `FirestoreFailure` - Database errors
- `NetworkFailure` - No internet
- `ChatNotFoundFailure` - Chat doesn't exist
- `MessageNotFoundFailure` - Message doesn't exist
- `UnauthorizedChatAccessFailure` - Permission denied
- `MediaUploadFailure` - File upload failed

### 6. Type Safety

All entities are strongly typed with Equatable for value equality:

```dart
class ChatEntity extends Equatable {
  final String id;
  final ChatType type;
  final List<String> participantIds;
  // ... more fields
}
```

## Testing

### Unit Tests

Test use cases in isolation:

```dart
void main() {
  group('GetUserChats', () {
    late MockChatRepository mockRepository;
    late GetUserChats useCase;

    setUp(() {
      mockRepository = MockChatRepository();
      useCase = GetUserChats(mockRepository);
    });

    test('should get chats from repository', () async {
      // Arrange
      when(() => mockRepository.getUserChats(any()))
          .thenAnswer((_) => Stream.value(Right([mockChat])));

      // Act
      final result = useCase('userId');

      // Assert
      expect(result, emits(Right([mockChat])));
    });
  });
}
```

### Integration Tests

Test complete flows:

```dart
void main() {
  testWidgets('should send message and update chat list', (tester) async {
    // Setup
    await tester.pumpWidget(MyApp());

    // Navigate to chat
    await tester.tap(find.byType(ChatListItem).first);
    await tester.pumpAndSettle();

    // Type and send message
    await tester.enterText(find.byType(TextField), 'Hello!');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    // Verify
    expect(find.text('Hello!'), findsOneWidget);
  });
}
```

## Performance Optimization

### 1. Limit Query Results

Always limit queries to prevent loading too much data:

```dart
.limit(50) // Get only 50 messages at a time
```

### 2. Use Indexes

All composite queries require indexes (see `firestore.indexes.json`).

### 3. Denormalize Data

Store `lastMessage` in chat document to avoid additional reads:

```dart
'lastMessage': {
  'content': 'Hello!',
  'senderId': 'user123',
  'timestamp': Timestamp.now(),
}
```

### 4. Cache Aggressively

Firestore automatically caches all reads for offline access.

### 5. Batch Operations

Use batched writes for updating multiple documents:

```dart
final batch = firestore.batch();
for (final messageId in messageIds) {
  batch.update(messageRef, {'readBy': FieldValue.arrayUnion([userId])});
}
await batch.commit();
```

## Security Considerations

### 1. Security Rules

All data access is protected by Firestore security rules (see `firestore.rules`):

- Users can only read/write their own data
- Chat participants can only access their chats
- Message senders can edit/delete their messages

### 2. Client-side Validation

Always validate user input before sending to Firestore:

```dart
if (content.trim().isEmpty) {
  return Left(ValidationFailure('Message cannot be empty'));
}
```

### 3. Server-side Operations

Use Cloud Functions for sensitive operations:
- Wallet updates
- Transaction creation
- Admin operations

## Troubleshooting

### Issue: "Missing composite index"

**Solution**: Deploy indexes with:
```bash
firebase deploy --only firestore:indexes
```

### Issue: "Permission denied"

**Solution**: Check Firestore security rules. Ensure user is authenticated and has permission.

### Issue: "Real-time updates not working"

**Solution**:
1. Check Firestore connection
2. Verify stream providers are being watched
3. Ensure offline persistence is enabled

### Issue: "Messages not syncing offline"

**Solution**:
1. Enable offline persistence in `main.dart`
2. Check network connectivity
3. Verify Firestore cache size settings

## Next Steps

1. **Add Message Search**: Integrate Algolia or implement client-side search
2. **Add Media Compression**: Compress images/videos before upload
3. **Add Read Receipts**: Show when messages are read
4. **Add Typing Indicators**: Show when users are typing
5. **Add Push Notifications**: Notify users of new messages
6. **Add Cloud Functions**: Implement server-side logic for sensitive operations

## Resources

- [Firestore Documentation](https://firebase.google.com/docs/firestore)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Clean Architecture Guide](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

---

**Generated for Chatz - Phase 5: Firestore Integration**
