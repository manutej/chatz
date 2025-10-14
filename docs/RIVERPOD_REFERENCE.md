# Riverpod State Management Reference

This document provides essential Riverpod patterns and examples for the Chatz application.

## Overview

Riverpod is a reactive caching and data-binding framework for Dart and Flutter that simplifies state management with declarative programming, automatic recomputation, and enhanced tooling.

## Key Concepts

### Provider Types

1. **Provider** - For read-only values that never change
2. **StateProvider** - For simple state that can be modified
3. **StateNotifierProvider** - For complex state with methods
4. **FutureProvider** - For asynchronous operations
5. **StreamProvider** - For continuous data streams
6. **NotifierProvider** - Modern Riverpod provider (recommended)

## Common Patterns for Chatz

### 1. Authentication State

```dart
// User entity provider
final currentUserProvider = StateProvider<UserEntity?>((ref) => null);

// Auth status provider
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
```

### 2. Chat State Management

```dart
// Chats list provider
final chatsProvider = StreamProvider<List<Chat>>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  return FirebaseFirestore.instance
    .collection('chats')
    .where('participants', arrayContains: userId)
    .snapshots()
    .map((snapshot) => snapshot.docs.map((doc) => Chat.fromJson(doc.data())).toList());
});

// Selected chat provider
final selectedChatProvider = StateProvider<Chat?>((ref) => null);

// Messages provider for specific chat
final messagesProvider = StreamProvider.family<List<Message>, String>((ref, chatId) {
  return FirebaseFirestore.instance
    .collection('messages')
    .doc(chatId)
    .collection('messages')
    .orderBy('timestamp', descending: true)
    .snapshots()
    .map((snapshot) => snapshot.docs.map((doc) => Message.fromJson(doc.data())).toList());
});
```

### 3. Wallet/Balance State

```dart
// Wallet balance provider
final walletBalanceProvider = StreamProvider<double>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  return FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .snapshots()
    .map((doc) => doc.data()?['walletBalance'] as double? ?? 0.0);
});

// Transaction history provider
final transactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  return FirebaseFirestore.instance
    .collection('transactions')
    .doc(userId)
    .collection('transactions')
    .orderBy('timestamp', descending: true)
    .snapshots()
    .map((snapshot) => snapshot.docs.map((doc) => Transaction.fromJson(doc.data())).toList());
});
```

### 4. Call State Management

```dart
// Active call provider
final activeCallProvider = StateProvider<Call?>((ref) => null);

// Call cost tracker
final callCostProvider = StateProvider<double>((ref) => 0.0);

// Call duration tracker
final callDurationProvider = StateProvider<Duration>((ref) => Duration.zero);
```

### 5. NotifierProvider Pattern (Modern Approach)

```dart
// Chat notifier
class ChatNotifier extends Notifier<List<Chat>> {
  @override
  List<Chat> build() {
    return [];
  }

  Future<void> loadChats() async {
    state = await _chatRepository.getChats();
  }

  void addChat(Chat chat) {
    state = [...state, chat];
  }

  void removeChat(String chatId) {
    state = state.where((chat) => chat.id != chatId).toList();
  }
}

final chatNotifierProvider = NotifierProvider<ChatNotifier, List<Chat>>(ChatNotifier.new);
```

### 6. AsyncNotifier Pattern

```dart
class AuthNotifier extends AsyncNotifier<UserEntity?> {
  @override
  Future<UserEntity?> build() async {
    // Initialize authentication state
    return await _authRepository.getCurrentUser();
  }

  Future<void> signIn(String phoneNumber) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _authRepository.signInWithPhone(phoneNumber);
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.signOut();
      return null;
    });
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, UserEntity?>(AuthNotifier.new);
```

## Watching Providers in Widgets

### Using ref.watch

```dart
class ChatListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatsProvider);

    return chatsAsync.when(
      data: (chats) => ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) => ChatTile(chat: chats[index]),
      ),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

### Using ref.read

```dart
// Use ref.read in callbacks and event handlers
ElevatedButton(
  onPressed: () {
    ref.read(chatNotifierProvider.notifier).addChat(newChat);
  },
  child: Text('Add Chat'),
)
```

### Using ref.listen

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // Listen for changes and show snackbar
  ref.listen<AsyncValue<UserEntity?>>(authNotifierProvider, (previous, next) {
    next.whenOrNull(
      error: (error, stack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      },
    );
  });

  return Scaffold(...);
}
```

## Provider Families

Use families when you need to pass parameters:

```dart
// Chat messages by ID
final chatMessagesProvider = StreamProvider.family<List<Message>, String>((ref, chatId) {
  return _messageRepository.watchMessages(chatId);
});

// Usage
Widget build(BuildContext context, WidgetRef ref) {
  final messages = ref.watch(chatMessagesProvider('chat123'));
  return messages.when(...);
}
```

## Testing with Riverpod

```dart
testWidgets('Test chat list', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        chatsProvider.overrideWith((ref) => Stream.value([mockChat])),
      ],
      child: MyApp(),
    ),
  );

  expect(find.text('Mock Chat'), findsOneWidget);
});
```

## Best Practices

1. **Use ConsumerWidget** instead of StatelessWidget when you need providers
2. **Use ConsumerStatefulWidget** instead of StatefulWidget when needed
3. **Keep business logic in Notifiers**, not in widgets
4. **Use AsyncValue.guard** for error handling in async operations
5. **Prefer NotifierProvider** over StateNotifierProvider for new code
6. **Use .family** for parameterized providers
7. **Use .autoDispose** for providers that should clean up when not used

## Dependencies Setup

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0

dev_dependencies:
  riverpod_generator: ^2.3.0
  build_runner: ^2.4.0
```

Run code generation:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Resources

- [Official Riverpod Docs](https://riverpod.dev)
- [Riverpod GitHub](https://github.com/rrousselGit/riverpod)
- [Migration Guide](https://riverpod.dev/docs/migration)
