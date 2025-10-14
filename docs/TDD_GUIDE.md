# Test-Driven Development Guide for Chatz

This guide establishes TDD practices and testing patterns for the Chatz application.

## Testing Philosophy

**Test-Driven Development (TDD)** follows the Red-Green-Refactor cycle:

1. **Red**: Write a failing test
2. **Green**: Write minimal code to make the test pass
3. **Refactor**: Improve the code while keeping tests green

## Testing Pyramid

```
        /\
       /  \
      / E2E\ (Few)
     /------\
    / Widget \ (Some)
   /----------\
  / Unit Tests \ (Many)
 /--------------\
```

- **Unit Tests**: Test individual functions/classes (70-80%)
- **Widget Tests**: Test Flutter widgets (15-20%)
- **Integration Tests**: Test complete features (5-10%)

## Project Test Structure

```
test/
├── unit/
│   ├── core/
│   │   ├── utils/
│   │   │   ├── validators_test.dart
│   │   │   └── extensions_test.dart
│   │   └── errors/
│   │       ├── failures_test.dart
│   │       └── exceptions_test.dart
│   └── features/
│       ├── auth/
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   ├── usecases/
│       │   │   └── repositories/
│       │   ├── data/
│       │   │   ├── models/
│       │   │   ├── datasources/
│       │   │   └── repositories/
│       │   └── presentation/
│       │       ├── providers/
│       │       └── pages/
│       ├── chat/
│       ├── calls/
│       └── payments/
├── widget/
│   ├── auth/
│   ├── chat/
│   ├── calls/
│   └── shared/
├── integration/
│   ├── auth_flow_test.dart
│   ├── chat_flow_test.dart
│   └── payment_flow_test.dart
├── fixtures/
│   ├── auth_fixtures.dart
│   ├── chat_fixtures.dart
│   └── payment_fixtures.dart
└── helpers/
    ├── test_helpers.dart
    ├── mock_factories.dart
    └── pump_app.dart
```

## Unit Testing Patterns

### Example 1: Testing Validators

```dart
// test/unit/core/utils/validators_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chatz/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('validatePhoneNumber', () {
      test('should return null for valid phone number', () {
        // Arrange
        const validPhone = '+1234567890';

        // Act
        final result = Validators.validatePhoneNumber(validPhone);

        // Assert
        expect(result, null);
      });

      test('should return error message for invalid phone number', () {
        // Arrange
        const invalidPhone = '123';

        // Act
        final result = Validators.validatePhoneNumber(invalidPhone);

        // Assert
        expect(result, 'Please enter a valid phone number');
      });

      test('should return error message for empty phone number', () {
        // Arrange
        const emptyPhone = '';

        // Act
        final result = Validators.validatePhoneNumber(emptyPhone);

        // Assert
        expect(result, 'Phone number is required');
      });
    });

    group('validateEmail', () {
      test('should return null for valid email', () {
        expect(Validators.validateEmail('test@example.com'), null);
      });

      test('should return error for invalid email format', () {
        expect(
          Validators.validateEmail('invalid-email'),
          'Please enter a valid email',
        );
      });
    });
  });
}
```

### Example 2: Testing Domain Layer (Use Cases)

```dart
// test/unit/features/auth/domain/usecases/sign_in_with_phone_test.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chatz/features/auth/domain/entities/user_entity.dart';
import 'package:chatz/features/auth/domain/repositories/auth_repository.dart';
import 'package:chatz/features/auth/domain/usecases/sign_in_with_phone.dart';
import 'package:chatz/core/errors/failures.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignInWithPhone usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = SignInWithPhone(mockAuthRepository);
  });

  final tPhoneNumber = '+1234567890';
  final tUser = UserEntity(
    id: '1',
    phoneNumber: tPhoneNumber,
    displayName: 'Test User',
  );

  test('should sign in user with valid phone number', () async {
    // Arrange
    when(() => mockAuthRepository.signInWithPhone(any()))
        .thenAnswer((_) async => Right(tUser));

    // Act
    final result = await usecase(tPhoneNumber);

    // Assert
    expect(result, Right(tUser));
    verify(() => mockAuthRepository.signInWithPhone(tPhoneNumber));
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return ServerFailure when sign in fails', () async {
    // Arrange
    when(() => mockAuthRepository.signInWithPhone(any()))
        .thenAnswer((_) async => Left(ServerFailure('Server error')));

    // Act
    final result = await usecase(tPhoneNumber);

    // Assert
    expect(result, Left(ServerFailure('Server error')));
    verify(() => mockAuthRepository.signInWithPhone(tPhoneNumber));
  });
}
```

### Example 3: Testing Data Layer (Repositories)

```dart
// test/unit/features/auth/data/repositories/auth_repository_impl_test.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chatz/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chatz/features/auth/data/models/user_model.dart';
import 'package:chatz/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:chatz/core/errors/exceptions.dart';
import 'package:chatz/core/errors/failures.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(mockRemoteDataSource);
  });

  final tPhoneNumber = '+1234567890';
  final tUserModel = UserModel(
    id: '1',
    phoneNumber: tPhoneNumber,
    displayName: 'Test User',
  );

  group('signInWithPhone', () {
    test('should return user when remote call is successful', () async {
      // Arrange
      when(() => mockRemoteDataSource.signInWithPhone(any()))
          .thenAnswer((_) async => tUserModel);

      // Act
      final result = await repository.signInWithPhone(tPhoneNumber);

      // Assert
      expect(result, Right(tUserModel));
      verify(() => mockRemoteDataSource.signInWithPhone(tPhoneNumber));
    });

    test('should return ServerFailure when remote call throws ServerException', () async {
      // Arrange
      when(() => mockRemoteDataSource.signInWithPhone(any()))
          .thenThrow(ServerException('Server error'));

      // Act
      final result = await repository.signInWithPhone(tPhoneNumber);

      // Assert
      expect(result, Left(ServerFailure('Server error')));
    });

    test('should return NetworkFailure when remote call throws NetworkException', () async {
      // Arrange
      when(() => mockRemoteDataSource.signInWithPhone(any()))
          .thenThrow(NetworkException('No internet connection'));

      // Act
      final result = await repository.signInWithPhone(tPhoneNumber);

      // Assert
      expect(result, Left(NetworkFailure('No internet connection')));
    });
  });
}
```

### Example 4: Testing Riverpod Providers

```dart
// test/unit/features/auth/presentation/providers/auth_provider_test.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:chatz/features/auth/domain/usecases/sign_in_with_phone.dart';
import 'package:chatz/features/auth/domain/entities/user_entity.dart';
import 'package:chatz/features/auth/presentation/providers/auth_provider.dart';
import 'package:chatz/core/errors/failures.dart';

class MockSignInWithPhone extends Mock implements SignInWithPhone {}

void main() {
  late MockSignInWithPhone mockSignInWithPhone;

  setUp(() {
    mockSignInWithPhone = MockSignInWithPhone();
  });

  final tPhoneNumber = '+1234567890';
  final tUser = UserEntity(
    id: '1',
    phoneNumber: tPhoneNumber,
    displayName: 'Test User',
  );

  test('should emit loading then data when sign in succeeds', () async {
    // Arrange
    when(() => mockSignInWithPhone(any()))
        .thenAnswer((_) async => Right(tUser));

    final container = ProviderContainer(
      overrides: [
        signInWithPhoneProvider.overrideWithValue(mockSignInWithPhone),
      ],
    );

    final provider = container.read(authNotifierProvider.notifier);

    // Act
    await provider.signIn(tPhoneNumber);

    // Assert
    final state = container.read(authNotifierProvider);
    expect(state.value, tUser);
  });

  test('should emit loading then error when sign in fails', () async {
    // Arrange
    when(() => mockSignInWithPhone(any()))
        .thenAnswer((_) async => Left(ServerFailure('Server error')));

    final container = ProviderContainer(
      overrides: [
        signInWithPhoneProvider.overrideWithValue(mockSignInWithPhone),
      ],
    );

    final provider = container.read(authNotifierProvider.notifier);

    // Act
    await provider.signIn(tPhoneNumber);

    // Assert
    final state = container.read(authNotifierProvider);
    expect(state.hasError, true);
  });
}
```

## Widget Testing Patterns

### Example 1: Testing Custom Widgets

```dart
// test/widget/shared/custom_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatz/shared/widgets/custom_button.dart';

void main() {
  group('CustomButton', () {
    testWidgets('should render with given text', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Click Me',
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Click Me'), findsOneWidget);
    });

    testWidgets('should call onPressed when tapped', (tester) async {
      // Arrange
      var wasPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Click Me',
              onPressed: () => wasPressed = true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(CustomButton));
      await tester.pumpAndSettle();

      // Assert
      expect(wasPressed, true);
    });

    testWidgets('should show loading indicator when isLoading is true', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Click Me',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Click Me'), findsNothing);
    });

    testWidgets('should be disabled when onPressed is null', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Click Me',
              onPressed: null,
            ),
          ),
        ),
      );

      // Assert
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.enabled, false);
    });
  });
}
```

### Example 2: Testing Pages with Riverpod

```dart
// test/widget/auth/login_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chatz/features/auth/presentation/pages/login_page.dart';
import 'package:chatz/features/auth/presentation/providers/auth_provider.dart';
import '../../../helpers/pump_app.dart';

class MockAuthNotifier extends Mock implements AuthNotifier {}

void main() {
  late MockAuthNotifier mockAuthNotifier;

  setUp(() {
    mockAuthNotifier = MockAuthNotifier();
  });

  testWidgets('should render login form', (tester) async {
    // Arrange & Act
    await tester.pumpApp(
      LoginPage(),
      overrides: [
        authNotifierProvider.overrideWith((ref) => mockAuthNotifier),
      ],
    );

    // Assert
    expect(find.text('Welcome to Chatz'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('should call signIn when button is pressed', (tester) async {
    // Arrange
    when(() => mockAuthNotifier.signIn(any()))
        .thenAnswer((_) async => {});

    await tester.pumpApp(
      LoginPage(),
      overrides: [
        authNotifierProvider.overrideWith((ref) => mockAuthNotifier),
      ],
    );

    // Act
    await tester.enterText(find.byType(TextField), '+1234567890');
    await tester.tap(find.text('Continue'));
    await tester.pump();

    // Assert
    verify(() => mockAuthNotifier.signIn('+1234567890')).called(1);
  });

  testWidgets('should show error message when sign in fails', (tester) async {
    // Arrange
    when(() => mockAuthNotifier.signIn(any()))
        .thenThrow(Exception('Sign in failed'));

    await tester.pumpApp(
      LoginPage(),
      overrides: [
        authNotifierProvider.overrideWith((ref) => mockAuthNotifier),
      ],
    );

    // Act
    await tester.enterText(find.byType(TextField), '+1234567890');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Sign in failed'), findsOneWidget);
  });
}
```

## Integration Testing Patterns

### Example: E2E Authentication Flow

```dart
// test/integration/auth_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chatz/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow', () {
    testWidgets('complete sign up and sign in flow', (tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Should show login screen
      expect(find.text('Welcome to Chatz'), findsOneWidget);

      // Enter phone number
      await tester.enterText(
        find.byKey(Key('phone_input')),
        '+1234567890',
      );
      await tester.pumpAndSettle();

      // Tap continue button
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Should navigate to OTP verification
      expect(find.text('Verify Phone'), findsOneWidget);

      // Enter OTP
      await tester.enterText(
        find.byKey(Key('otp_input')),
        '123456',
      );
      await tester.pumpAndSettle();

      // Tap verify button
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Should navigate to home screen
      expect(find.text('Chats'), findsOneWidget);
      expect(find.byIcon(Icons.chat), findsOneWidget);
    });
  });
}
```

## Test Helpers

### Pump App Helper

```dart
// test/helpers/pump_app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatz/core/router/app_router.dart';
import 'package:chatz/core/themes/app_theme.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const [],
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: widget,
        ),
      ),
    );
  }

  Future<void> pumpRouter({
    List<Override> overrides = const [],
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
```

### Mock Factories

```dart
// test/helpers/mock_factories.dart
import 'package:chatz/features/auth/domain/entities/user_entity.dart';
import 'package:chatz/features/chat/domain/entities/chat_entity.dart';
import 'package:chatz/features/chat/domain/entities/message_entity.dart';

class MockFactories {
  static UserEntity createUser({
    String? id,
    String? phoneNumber,
    String? displayName,
  }) {
    return UserEntity(
      id: id ?? '1',
      phoneNumber: phoneNumber ?? '+1234567890',
      displayName: displayName ?? 'Test User',
      email: 'test@example.com',
      photoUrl: null,
      about: 'Hey there! I am using Chatz',
      isOnline: true,
      lastSeen: DateTime.now(),
      walletBalance: 10.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static ChatEntity createChat({
    String? id,
    List<String>? participants,
    String? lastMessage,
  }) {
    return ChatEntity(
      id: id ?? 'chat1',
      participants: participants ?? ['1', '2'],
      type: ChatType.individual,
      lastMessage: lastMessage ?? 'Hello!',
      lastMessageTime: DateTime.now(),
      unreadCount: {'1': 0, '2': 1},
      createdAt: DateTime.now(),
    );
  }

  static MessageEntity createMessage({
    String? id,
    String? senderId,
    String? content,
    MessageType? type,
  }) {
    return MessageEntity(
      id: id ?? 'msg1',
      senderId: senderId ?? '1',
      content: content ?? 'Hello!',
      type: type ?? MessageType.text,
      timestamp: DateTime.now(),
      isRead: false,
      isDelivered: true,
    );
  }
}
```

## Testing Best Practices

### 1. Test Naming Convention

```dart
// Good
test('should return null for valid phone number', () {});
test('should throw ServerException when API call fails', () {});
testWidgets('should display error message when login fails', (tester) async {});

// Bad
test('phone validation', () {});
test('test1', () {});
```

### 2. AAA Pattern (Arrange, Act, Assert)

```dart
test('should validate email correctly', () {
  // Arrange
  const validEmail = 'test@example.com';

  // Act
  final result = Validators.validateEmail(validEmail);

  // Assert
  expect(result, null);
});
```

### 3. Use Descriptive Test Groups

```dart
group('AuthRepository', () {
  group('signInWithPhone', () {
    test('should return user when successful', () {});
    test('should return failure when unsuccessful', () {});
  });

  group('signOut', () {
    test('should clear user data', () {});
  });
});
```

### 4. Mock External Dependencies

```dart
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirestore extends Mock implements FirebaseFirestore {}
class MockStripe extends Mock implements Stripe {}
class MockAgoraEngine extends Mock implements RtcEngine {}
```

### 5. Test Edge Cases

```dart
group('WalletService', () {
  test('should handle zero balance', () {});
  test('should handle negative amounts', () {});
  test('should handle maximum transaction limit', () {});
  test('should handle network timeouts', () {});
});
```

## Running Tests

### Run All Tests

```bash
flutter test
```

### Run Specific Test File

```bash
flutter test test/unit/features/auth/domain/usecases/sign_in_with_phone_test.dart
```

### Run Tests with Coverage

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Run Integration Tests

```bash
flutter test integration_test/
```

## Coverage Goals

- **Overall**: Minimum 80%
- **Domain Layer**: 90%+
- **Data Layer**: 85%+
- **Presentation Layer**: 70%+
- **Shared/Core**: 90%+

## Continuous Integration

Add to `.github/workflows/test.yml`:

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage
      - run: flutter test integration_test/
```

## Resources

- [Flutter Testing Documentation](https://flutter.dev/docs/testing)
- [Riverpod Testing Guide](https://riverpod.dev/docs/essentials/testing)
- [Mocktail Package](https://pub.dev/packages/mocktail)
- [Integration Test Package](https://pub.dev/packages/integration_test)
