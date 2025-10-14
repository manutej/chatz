# Chatz - Architecture Documentation

## Overview

Chatz follows **Clean Architecture** principles with clear separation of concerns across three main layers: Domain, Data, and Presentation. This architecture ensures maintainability, testability, and scalability.

## Architecture Layers

```
┌─────────────────────────────────────────────┐
│          Presentation Layer                  │
│  (UI, State Management, User Interaction)   │
│                                              │
│  - Pages/Screens                             │
│  - Widgets                                   │
│  - BLoCs/Providers (Riverpod)               │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│            Domain Layer                      │
│      (Business Logic & Entities)            │
│                                              │
│  - Entities                                  │
│  - Repository Interfaces                     │
│  - Use Cases                                 │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│             Data Layer                       │
│    (Data Sources & Implementations)         │
│                                              │
│  - Repository Implementations                │
│  - Data Sources (Remote/Local)              │
│  - Models (DTOs)                             │
└─────────────────────────────────────────────┘
```

## Layer Details

### 1. Presentation Layer

**Responsibility:** Handle user interface and user interactions

**Components:**
- **Pages/Screens:** Full-screen widgets representing app screens
- **Widgets:** Reusable UI components
- **State Management:** Riverpod providers for reactive state

**Rules:**
- Only depends on Domain layer
- No direct dependency on Data layer
- Contains only UI logic, no business logic
- Reacts to state changes from providers

**Example:**
```dart
// features/auth/presentation/pages/login_page.dart
class LoginPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      loading: () => LoadingIndicator(),
      error: (error) => ErrorWidget(error),
      data: (user) => HomeScreen(),
    );
  }
}
```

### 2. Domain Layer

**Responsibility:** Contains business logic and business entities

**Components:**
- **Entities:** Business objects (pure Dart classes)
- **Repository Interfaces:** Abstract contracts for data operations
- **Use Cases:** Single-purpose business operations

**Rules:**
- No dependencies on other layers
- Pure Dart code (no Flutter imports)
- Defines contracts that Data layer implements
- Contains business rules and validation

**Example:**
```dart
// features/auth/domain/entities/user_entity.dart
class UserEntity extends Equatable {
  final String id;
  final String phoneNumber;
  final String displayName;
  // ... business properties
}

// features/auth/domain/repositories/auth_repository.dart
abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login(String phone);
  Future<Either<Failure, void>> logout();
}

// features/auth/domain/usecases/login_usecase.dart
class LoginUseCase {
  final AuthRepository repository;

  Future<Either<Failure, UserEntity>> call(String phone) {
    return repository.login(phone);
  }
}
```

### 3. Data Layer

**Responsibility:** Implement data operations and handle data sources

**Components:**
- **Repository Implementations:** Concrete implementations of domain repositories
- **Data Sources:** Remote (API/Firebase) and Local (Database/Cache)
- **Models (DTOs):** Data Transfer Objects for API/Database

**Rules:**
- Implements Domain layer contracts
- Handles data transformations (Model ↔ Entity)
- Manages data sources (remote, local, cache)
- No UI logic

**Example:**
```dart
// features/auth/data/models/user_model.dart
class UserModel extends UserEntity {
  factory UserModel.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
  UserEntity toEntity() { ... }
}

// features/auth/data/datasources/auth_remote_datasource.dart
abstract class AuthRemoteDataSource {
  Future<UserModel> login(String phone);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;

  @override
  Future<UserModel> login(String phone) async {
    // Firebase API calls
  }
}

// features/auth/data/repositories/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  @override
  Future<Either<Failure, UserEntity>> login(String phone) async {
    try {
      final userModel = await remoteDataSource.login(phone);
      await localDataSource.cacheUser(userModel);
      return Right(userModel.toEntity());
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}
```

## State Management (Riverpod)

### Provider Types

1. **StateProvider:** Simple state (primitive values)
2. **StateNotifierProvider:** Complex state with logic
3. **FutureProvider:** Async operations
4. **StreamProvider:** Real-time data streams

### Example State Management

```dart
// Auth state
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<UserEntity?> build() {
    // Initial state: check if user is logged in
    return _checkAuthStatus();
  }

  Future<void> login(String phone) async {
    state = const AsyncLoading();

    final result = await ref.read(loginUseCaseProvider).call(phone);

    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (user) => AsyncData(user),
    );
  }

  Future<void> logout() async {
    await ref.read(logoutUseCaseProvider).call();
    state = const AsyncData(null);
  }
}

// Usage in UI
class LoginPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return authState.when(
      loading: () => LoadingIndicator(),
      error: (error, stack) => ErrorWidget(error),
      data: (user) => user == null ? LoginForm() : HomeScreen(),
    );
  }
}
```

## Dependency Injection (GetIt)

All dependencies are registered in `core/di/injection.dart`:

```dart
// Service locator
final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // External
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => prefs);
  sl.registerLazySingleton(() => FirebaseAuth.instance);

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl())
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    )
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));

  // Providers
  sl.registerFactory(() => AuthNotifier(sl(), sl()));
}
```

## Navigation (GoRouter)

Declarative routing with type-safe navigation:

```dart
// core/router/app_router.dart
final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => SplashPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => HomePage(),
      routes: [
        GoRoute(
          path: 'chat/:chatId',
          builder: (context, state) {
            final chatId = state.pathParameters['chatId']!;
            return ChatDetailPage(chatId: chatId);
          },
        ),
      ],
    ),
  ],
);

// Usage
context.go('/home');
context.push('/home/chat/123');
```

## Error Handling

### Failures vs Exceptions

- **Exceptions:** Thrown by data sources (caught at repository level)
- **Failures:** Returned by repositories (handled at presentation level)

```dart
// Exception (Data Layer)
class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

// Failure (Domain Layer)
class ServerFailure extends Failure {
  ServerFailure(super.message);
}

// Repository converts Exception → Failure
class AuthRepositoryImpl {
  Future<Either<Failure, User>> login(String phone) async {
    try {
      final user = await remoteDataSource.login(phone);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return Left(NetworkFailure());
    } catch (e) {
      return Left(UnknownFailure());
    }
  }
}

// UI handles Failure
authState.when(
  error: (failure, _) {
    if (failure is NetworkFailure) {
      showSnackBar('No internet connection');
    } else if (failure is ServerFailure) {
      showSnackBar('Server error occurred');
    }
  },
  // ...
);
```

## Data Flow

### Example: User Login Flow

1. **User Action:** User taps "Login" button
2. **Presentation:** `LoginPage` calls `ref.read(authProvider).login(phone)`
3. **State Management:** `AuthNotifier.login()` executes
4. **Use Case:** `LoginUseCase` is called with phone number
5. **Repository:** `AuthRepository.login()` is invoked
6. **Data Source:** `AuthRemoteDataSource` calls Firebase API
7. **Response Mapping:**
   - `UserModel` (DTO) received from Firebase
   - Converted to `UserEntity` (business object)
   - Cached locally via `AuthLocalDataSource`
8. **Result Handling:**
   - Success: `Either.Right(UserEntity)` returned up the chain
   - Error: `Either.Left(Failure)` returned
9. **State Update:** `AuthNotifier` updates state with result
10. **UI Reaction:** `LoginPage` rebuilds based on new state

```dart
User taps button
       ↓
   LoginPage
       ↓
  AuthNotifier.login()
       ↓
   LoginUseCase
       ↓
  AuthRepository
       ↓
AuthRemoteDataSource → Firebase
       ↓
   UserModel
       ↓
   UserEntity ← Domain Entity
       ↓
 Either<Failure, User>
       ↓
  State Updated
       ↓
  UI Rebuilds
```

## Feature Module Structure

Each feature follows the same structure:

```
features/feature_name/
├── data/
│   ├── models/              # DTOs with JSON serialization
│   ├── datasources/         # Remote and local data sources
│   └── repositories/        # Repository implementations
├── domain/
│   ├── entities/            # Business entities
│   ├── repositories/        # Repository interfaces
│   └── usecases/            # Business logic use cases
└── presentation/
    ├── providers/           # Riverpod providers
    ├── pages/               # Full-screen pages
    └── widgets/             # Feature-specific widgets
```

## Testing Strategy

### Unit Tests
- Test use cases in isolation
- Test repositories with mocked data sources
- Test data source implementations

```dart
// test/unit/auth/login_usecase_test.dart
void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });

  test('should return UserEntity when login succeeds', () async {
    // Arrange
    when(() => mockRepository.login(any()))
        .thenAnswer((_) async => Right(tUserEntity));

    // Act
    final result = await useCase('+1234567890');

    // Assert
    expect(result, Right(tUserEntity));
    verify(() => mockRepository.login('+1234567890'));
  });
}
```

### Widget Tests
- Test UI components in isolation
- Verify widget behavior and interactions

```dart
// test/widget/login_page_test.dart
void main() {
  testWidgets('should show loading indicator when logging in', (tester) async {
    // Arrange
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => MockAuthNotifier()),
        ],
        child: MaterialApp(home: LoginPage()),
      ),
    );

    // Act
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Assert
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
```

### Integration Tests
- Test complete user flows
- Verify feature interactions

## Best Practices

### 1. Separation of Concerns
- Each layer has a single responsibility
- No layer bypasses another layer

### 2. Dependency Rule
- Dependencies point inward (Presentation → Domain ← Data)
- Domain layer has no external dependencies

### 3. Immutability
- Use immutable data classes (Equatable, Freezed)
- State changes create new instances

### 4. Error Handling
- Use Either<Failure, Success> for operations that can fail
- Never throw exceptions across layer boundaries

### 5. State Management
- Keep state close to where it's used
- Use providers for shared state
- Avoid global state when possible

### 6. Testing
- Write tests for business logic (use cases)
- Mock dependencies using interfaces
- Test edge cases and error scenarios

## Microtransaction Call System

### Payment Flow Architecture

```
User initiates call
       ↓
Check wallet balance
       ↓
Balance sufficient? ─No→ Show recharge prompt
       │
      Yes
       ↓
Deduct initial amount
       ↓
Start WebRTC call
       ↓
Monitor call duration (every 10s)
       ↓
Deduct per-second cost
       ↓
Balance low? ─Yes→ Warn user
       │
       No
       ↓
Call continues
       ↓
Call ends
       ↓
Final cost calculation
       ↓
Update transaction history
```

### Key Components

1. **Wallet Service:** Manages user balance
2. **Call Service:** Handles call lifecycle
3. **Payment Service:** Processes charges
4. **Transaction Service:** Records payment history

## Firebase Integration

### Firestore Structure

```
users/{userId}
  - profile data
  - walletBalance

chats/{chatId}
  - participants[]
  - lastMessage
  - metadata

  messages/{messageId}
    - content
    - senderId
    - timestamp
    - status

calls/{callId}
  - callerId
  - receiverId
  - duration
  - cost
  - status

transactions/{userId}/transactions/{transactionId}
  - type
  - amount
  - timestamp
```

### Real-time Updates

```dart
// Stream messages
Stream<List<Message>> watchMessages(String chatId) {
  return firestore
    .collection('messages')
    .doc(chatId)
    .collection('messages')
    .orderBy('timestamp', descending: true)
    .snapshots()
    .map((snapshot) => snapshot.docs
      .map((doc) => MessageModel.fromFirestore(doc))
      .toList());
}

// Usage in provider
@riverpod
Stream<List<Message>> chatMessages(ChatMessagesRef ref, String chatId) {
  return ref.watch(messageRepositoryProvider).watchMessages(chatId);
}
```

## Security Considerations

1. **Authentication:** Firebase Auth with phone verification
2. **Authorization:** Firestore security rules
3. **Encryption:** End-to-end encryption for messages
4. **Secure Storage:** Sensitive data in flutter_secure_storage
5. **API Keys:** Never commit keys to version control

## Performance Optimization

1. **Lazy Loading:** Load data as needed
2. **Caching:** Cache frequently accessed data
3. **Pagination:** Limit initial data load
4. **Image Optimization:** Compress and cache images
5. **Debouncing:** Limit API calls for search/typing

## Conclusion

This architecture provides:
- Clear separation of concerns
- High testability
- Easy maintainability
- Scalability for future features
- Type safety and null safety

Follow these patterns when implementing new features to maintain consistency and code quality.
