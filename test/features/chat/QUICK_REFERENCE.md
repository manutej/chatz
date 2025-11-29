# Chat Feature Tests - Quick Reference

## Running Tests

```bash
# All chat tests
flutter test test/features/chat/

# Specific category
flutter test test/features/chat/data/models/
flutter test test/features/chat/data/datasources/
flutter test test/features/chat/data/repositories/
flutter test test/features/chat/domain/usecases/

# Single file
flutter test test/features/chat/data/models/chat_model_test.dart

# With coverage
flutter test --coverage test/features/chat/
```

## Test File Structure

```
test/features/chat/
├── fixtures/
│   ├── chat_fixtures.dart              # Reusable chat test data
│   └── message_fixtures.dart           # Reusable message test data
├── data/
│   ├── models/
│   │   ├── participant_model_test.dart  # JSON ↔ Entity conversion
│   │   ├── message_model_test.dart      # Message serialization
│   │   └── chat_model_test.dart         # Chat serialization
│   ├── datasources/
│   │   ├── chat_remote_data_source_test.dart    # Firestore chat ops
│   │   └── message_remote_data_source_test.dart # Firestore message ops
│   └── repositories/
│       ├── chat_repository_impl_test.dart       # Chat repo logic
│       └── message_repository_impl_test.dart    # Message repo logic
└── domain/
    └── usecases/
        ├── get_user_chats_test.dart             # Stream<Chats>
        ├── get_chat_messages_test.dart          # Stream<Messages>
        ├── send_message_test.dart               # Send message
        ├── create_chat_test.dart                # Create chat
        └── mark_messages_as_read_test.dart      # Mark as read
```

## Key Test Patterns

### 1. Stream Testing
```dart
test('should emit real-time updates', () async {
  final stream = dataSource.getUserChats(userId);

  await expectLater(
    stream,
    emitsInOrder([
      [],  // Initial state
      predicate((chats) => chats.length == 1),  // After update
    ]),
  );
});
```

### 2. Firestore Operations
```dart
test('should create document in Firestore', () async {
  // Arrange
  final fakeFirestore = FakeFirebaseFirestore();
  final dataSource = ChatRemoteDataSourceImpl(fakeFirestore);

  // Act
  final result = await dataSource.createChat(...);

  // Assert
  final doc = await fakeFirestore.collection('chats').doc(result.id).get();
  expect(doc.exists, true);
});
```

### 3. Error Handling
```dart
test('should return Left(Failure) on error', () async {
  // Arrange
  when(() => mockRepo.getChat(any()))
      .thenThrow(FirestoreException('Error'));

  // Act
  final result = await repository.getChat('id');

  // Assert
  expect(result, isA<Left<Failure, ChatEntity>>());
  expect(result.fold((l) => l, (_) => null), isA<FirestoreFailure>());
});
```

### 4. Model Conversion
```dart
test('should convert model to entity', () {
  // Arrange
  final model = ChatFixtures.oneToOneChatModel;

  // Act
  final entity = model.toEntity();

  // Assert
  expect(entity, isA<ChatEntity>());
  expect(entity.id, model.id);
  expect(entity.type, ChatType.oneToOne);
});
```

## Test Data (Fixtures)

### Chat Fixtures
```dart
import '../../fixtures/chat_fixtures.dart';

// Available test data:
ChatFixtures.oneToOneChatEntity
ChatFixtures.oneToOneChatModel
ChatFixtures.groupChatEntity
ChatFixtures.groupChatModel
ChatFixtures.participantEntity1
ChatFixtures.userId1, userId2, userId3
```

### Message Fixtures
```dart
import '../../fixtures/message_fixtures.dart';

// Available test data:
MessageFixtures.textMessageEntity
MessageFixtures.textMessageModel
MessageFixtures.imageMessageEntity
MessageFixtures.replyMessageEntity
MessageFixtures.mediaMetadataModel
```

## Common Assertions

### Stream Assertions
```dart
// Single emission
await expectLater(stream, emits(expectedValue));

// Multiple emissions
await expectLater(stream, emitsInOrder([value1, value2]));

// Predicate check
await expectLater(
  stream,
  emits(predicate((data) => data.length > 0)),
);

// Error emission
await expectLater(stream, emitsError(isA<Exception>()));
```

### Either Assertions
```dart
// Success (Right)
expect(result, isA<Right<Failure, Entity>>());
expect(result.isRight(), true);

// Failure (Left)
expect(result, isA<Left<Failure, Entity>>());
expect(result.fold((l) => l, (_) => null), isA<FirestoreFailure>());
```

### Mock Verification
```dart
// Called once
verify(() => mockRepo.getChat(any())).called(1);

// Called n times
verify(() => mockRepo.getChat(any())).called(3);

// Never called
verifyNever(() => mockRepo.deleteChat(any()));
```

## Test Dependencies Setup

```dart
// Use case test
class MockChatRepository extends Mock implements ChatRepository {}

late MockChatRepository mockRepository;
late GetUserChats useCase;

setUp(() {
  mockRepository = MockChatRepository();
  useCase = GetUserChats(mockRepository);
});

// Repository test
class MockChatRemoteDataSource extends Mock implements ChatRemoteDataSource {}

late MockChatRemoteDataSource mockDataSource;
late ChatRepositoryImpl repository;

setUp(() {
  mockDataSource = MockChatRemoteDataSource();
  repository = ChatRepositoryImpl(mockDataSource);
});

// Data source test
late FakeFirebaseFirestore fakeFirestore;
late MockFirebaseStorage mockStorage;
late MessageRemoteDataSourceImpl dataSource;

setUp(() {
  fakeFirestore = FakeFirebaseFirestore();
  mockStorage = MockFirebaseStorage();
  dataSource = MessageRemoteDataSourceImpl(fakeFirestore, mockStorage);
});
```

## Mocking Responses

### Repository Mock
```dart
when(() => mockRepository.getUserChats(any())).thenAnswer(
  (_) => Stream.value(Right([ChatFixtures.oneToOneChatEntity])),
);
```

### Data Source Mock
```dart
when(() => mockDataSource.getChatById(any())).thenAnswer(
  (_) async => ChatFixtures.oneToOneChatModel,
);
```

### Firestore Setup
```dart
await fakeFirestore.collection('chats').doc('chat-id').set({
  'type': 'one-to-one',
  'participants': ['user1', 'user2'],
  ...
});
```

## Test Coverage Commands

```bash
# Generate coverage
flutter test --coverage test/features/chat/

# View coverage HTML
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Check coverage percentage
lcov --summary coverage/lcov.info
```

## Troubleshooting

### Issue: Stream never emits
**Solution**: Add delay or use `pump()` in widget tests
```dart
await Future.delayed(const Duration(milliseconds: 100));
```

### Issue: Mock not being called
**Solution**: Check mock setup and verify method signature matches
```dart
// Ensure parameter names match
when(() => mock.method(
  param1: any(named: 'param1'),
  param2: any(named: 'param2'),
))
```

### Issue: Timestamp conversion fails
**Solution**: Use proper conversion in fixtures
```dart
static final firestoreTimestamp = Timestamp.fromDate(testDateTime);
```

### Issue: Batch test fails
**Solution**: Verify batch commit happens
```dart
if (operationCount > 0) {
  await batch.commit();
}
```

## Best Practices

1. **Arrange-Act-Assert**: Structure all tests clearly
2. **One assertion per test**: Focus on single behavior
3. **Descriptive names**: `should return X when Y`
4. **Use fixtures**: Reuse test data
5. **Mock external deps**: Isolate unit under test
6. **Test edge cases**: Empty lists, null values, errors
7. **Fast tests**: No real network or Firebase calls

## Quick Test Template

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDependency extends Mock implements Dependency {}

void main() {
  late MockDependency mockDep;
  late ClassUnderTest sut;  // System Under Test

  setUp(() {
    mockDep = MockDependency();
    sut = ClassUnderTest(mockDep);
  });

  group('MethodName', () {
    test('should do X when condition Y', () {
      // Arrange
      when(() => mockDep.method()).thenReturn(value);

      // Act
      final result = sut.methodUnderTest();

      // Assert
      expect(result, expectedValue);
      verify(() => mockDep.method()).called(1);
    });
  });
}
```

## Test Metrics

- **Total Tests**: 200+
- **Target Coverage**: >90%
- **Execution Time**: <5 seconds
- **Files**: 12+
- **Lines of Test Code**: ~5000

## Resources

- [Flutter Testing Guide](https://flutter.dev/docs/testing)
- [Mocktail Documentation](https://pub.dev/packages/mocktail)
- [fake_cloud_firestore](https://pub.dev/packages/fake_cloud_firestore)
