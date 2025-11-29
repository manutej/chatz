# Developer Guide - Chatz Flutter App

Quick reference for developers working on the chatz application.

---

## Project Structure

```
lib/
├── core/                    # Core infrastructure
│   ├── constants/          # App constants (routes, storage keys)
│   ├── di/                 # Dependency injection (GetIt)
│   ├── error/              # Error handling (failures, exceptions)
│   ├── network/            # Connectivity monitoring
│   ├── router/             # Navigation (GoRouter)
│   ├── theme/              # Design system (colors, text, dimensions)
│   ├── utils/              # Utilities (logger, validators, formatters)
│   └── widgets/            # Reusable widgets
│
├── features/               # Feature modules (clean architecture)
│   ├── auth/              # Authentication
│   ├── chat/              # Messaging
│   ├── contacts/          # Contact management
│   ├── calls/             # Voice/video calling
│   ├── wallet/            # Payments
│   ├── status/            # Stories/status updates
│   └── settings/          # App settings
│
├── shared/                # Shared across features
│   └── services/          # Shared services
│
├── main.dart              # Production entry point
├── main_development.dart  # Development entry point
└── main_staging.dart      # Staging entry point
```

---

## Quick Start Commands

### Development
```bash
# Run on connected device
flutter run --target lib/main_development.dart

# Run on iOS simulator
flutter run --target lib/main_development.dart -d "iPhone 15 Pro"

# Run on Android emulator
flutter run --target lib/main_development.dart -d emulator-5554

# Hot reload: Press 'r'
# Hot restart: Press 'R'
# Quit: Press 'q'
```

### Build Release
```bash
# Android APK
flutter build apk --target lib/main.dart --release

# Android App Bundle (for Play Store)
flutter build appbundle --target lib/main.dart --release

# iOS (requires macOS)
flutter build ios --target lib/main.dart --release
```

### Testing
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/features/auth/auth_test.dart
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
flutter format lib/

# Fix analysis issues
dart fix --apply
```

---

## Common Tasks

### 1. Adding a New Feature

Follow clean architecture pattern:

```bash
# Create feature structure
mkdir -p lib/features/my_feature/{data,domain,presentation}/{datasources,models,repositories,entities,usecases,providers,pages,widgets}
```

**Domain Layer** (business logic):
1. Create entity: `lib/features/my_feature/domain/entities/my_entity.dart`
2. Create repository interface: `lib/features/my_feature/domain/repositories/my_repository.dart`
3. Create use case: `lib/features/my_feature/domain/usecases/get_my_data.dart`

**Data Layer** (data access):
1. Create model (DTO): `lib/features/my_feature/data/models/my_model.dart`
2. Create data source: `lib/features/my_feature/data/datasources/my_remote_datasource.dart`
3. Implement repository: `lib/features/my_feature/data/repositories/my_repository_impl.dart`

**Presentation Layer** (UI):
1. Create provider: `lib/features/my_feature/presentation/providers/my_provider.dart`
2. Create page: `lib/features/my_feature/presentation/pages/my_page.dart`
3. Create widgets: `lib/features/my_feature/presentation/widgets/my_widget.dart`

**Register in DI**:
```dart
// lib/core/di/injection_container.dart
void _registerMyFeatureDependencies() {
  // Data sources
  sl.registerLazySingleton<MyRemoteDataSource>(
    () => MyRemoteDataSourceImpl(firestore: sl()),
  );

  // Repositories
  sl.registerLazySingleton<MyRepository>(
    () => MyRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetMyDataUseCase(sl()));
}
```

### 2. Adding a New Route

```dart
// 1. Add route constant
// lib/core/constants/route_constants.dart
static const String myRoute = '/my-route';

// 2. Add route to router
// lib/core/router/app_router.dart
GoRoute(
  path: RouteConstants.myRoute,
  name: RouteConstants.myRoute,
  builder: (context, state) => const MyPage(),
),

// 3. Navigate to route
context.go(RouteConstants.myRoute);
// or
context.push(RouteConstants.myRoute);
```

### 3. Using Services

```dart
import '../core/di/injection_container.dart';

// Local storage
final localStorage = sl<LocalStorageService>();
await localStorage.setString('key', 'value');
final value = localStorage.getString('key');

// Secure storage
final secureStorage = sl<SecureStorageService>();
await secureStorage.saveAccessToken('token');
final token = await secureStorage.getAccessToken();

// Permissions
final permissionService = sl<PermissionService>();
final granted = await permissionService.requestCamera();

// Network info
final networkInfo = sl<NetworkInfo>();
final isConnected = await networkInfo.isConnected;
networkInfo.onConnectivityChanged.listen((result) {
  print('Connectivity changed: ${result.displayName}');
});
```

### 4. Using Theme

```dart
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';

// Colors
Container(
  color: AppColors.primary,
  child: Text(
    'Hello',
    style: AppTextStyles.headlineMedium(color: AppColors.white),
  ),
)

// Spacing
Padding(
  padding: AppDimensions.screenPadding,
  child: Column(
    spacing: AppDimensions.spaceM,
    children: [...],
  ),
)

// Border radius
Container(
  decoration: BoxDecoration(
    borderRadius: AppDimensions.borderRadiusM,
  ),
)
```

### 5. Logging

```dart
import '../core/utils/logger.dart';

// Info
AppLogger.i('User logged in successfully');

// Debug
AppLogger.d('API response: $response');

// Warning
AppLogger.w('Deprecated method called');

// Error
AppLogger.e('Failed to fetch data', error: error, stackTrace: stackTrace);
```

### 6. Creating a Provider (Riverpod)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simple provider
final myProvider = Provider<MyService>((ref) {
  return MyService();
});

// State provider
final counterProvider = StateProvider<int>((ref) => 0);

// State notifier provider
class MyNotifier extends StateNotifier<MyState> {
  MyNotifier() : super(MyState.initial());

  void doSomething() {
    state = state.copyWith(loading: true);
    // ... async work
    state = state.copyWith(loading: false, data: result);
  }
}

final myNotifierProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier();
});

// Usage in widget
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myNotifierProvider);
    final notifier = ref.read(myNotifierProvider.notifier);

    return ElevatedButton(
      onPressed: () => notifier.doSomething(),
      child: Text('Data: ${state.data}'),
    );
  }
}
```

---

## Best Practices

### 1. Null Safety
```dart
// ✅ Good
String? nullableString;
final nonNullable = nullableString ?? 'default';

// ❌ Bad
String? nullableString;
final nonNullable = nullableString!; // Can crash
```

### 2. Const Constructors
```dart
// ✅ Good - saves memory and improves performance
const Text('Hello');
const SizedBox(height: 16);

// ❌ Bad
Text('Hello');
SizedBox(height: 16);
```

### 3. Widget Composition
```dart
// ✅ Good - break down into smaller widgets
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _Header(),
          _Content(),
          _Footer(),
        ],
      ),
    );
  }
}

// ❌ Bad - monolithic build method
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 100+ lines of widgets...
        ],
      ),
    );
  }
}
```

### 4. Error Handling
```dart
// ✅ Good
try {
  final result = await apiCall();
  return Right(result);
} catch (error, stackTrace) {
  AppLogger.e('API call failed', error: error, stackTrace: stackTrace);
  return Left(ServerFailure(message: error.toString()));
}

// ❌ Bad
final result = await apiCall(); // Can crash
```

### 5. Dependency Injection
```dart
// ✅ Good - inject dependencies
class MyRepository {
  final RemoteDataSource remoteDataSource;
  final LocalDataSource localDataSource;

  MyRepository({
    required this.remoteDataSource,
    required this.localDataSource,
  });
}

// ❌ Bad - hardcoded dependencies
class MyRepository {
  final remoteDataSource = RemoteDataSourceImpl();
  final localDataSource = LocalDataSourceImpl();
}
```

---

## Testing Guidelines

### Unit Tests
```dart
// test/features/my_feature/domain/usecases/my_usecase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMyRepository extends Mock implements MyRepository {}

void main() {
  late MockMyRepository mockRepository;
  late MyUseCase useCase;

  setUp(() {
    mockRepository = MockMyRepository();
    useCase = MyUseCase(mockRepository);
  });

  test('should return data when repository call succeeds', () async {
    // Arrange
    when(() => mockRepository.getData())
        .thenAnswer((_) async => Right(testData));

    // Act
    final result = await useCase();

    // Assert
    expect(result, Right(testData));
    verify(() => mockRepository.getData()).called(1);
  });
}
```

### Widget Tests
```dart
// test/features/my_feature/presentation/widgets/my_widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('MyWidget displays text correctly', (tester) async {
    // Build widget
    await tester.pumpWidget(
      MaterialApp(
        home: MyWidget(text: 'Hello'),
      ),
    );

    // Verify
    expect(find.text('Hello'), findsOneWidget);
  });
}
```

---

## Troubleshooting

### Common Issues

**1. Firebase not initialized**
```
Error: [core/no-app] No Firebase App '[DEFAULT]' has been created
```
**Solution**: Ensure `Firebase.initializeApp()` is called in main.dart

**2. Provider not found**
```
Error: Could not find the correct Provider<MyService> above this MyWidget
```
**Solution**: Wrap app with `ProviderScope` and ensure provider is registered

**3. Route not found**
```
Error: GoRouter: could not match location
```
**Solution**: Check route path in `route_constants.dart` matches router configuration

**4. Dependency not registered**
```
Error: GetIt: Object/factory with type MyService is not registered
```
**Solution**: Register in `injection_container.dart` and call `initializeDependencies()`

---

## Resources

- **Flutter Docs**: https://docs.flutter.dev
- **Riverpod Docs**: https://riverpod.dev
- **GoRouter Docs**: https://pub.dev/packages/go_router
- **Firebase Docs**: https://firebase.google.com/docs/flutter
- **Effective Dart**: https://dart.dev/guides/language/effective-dart

---

## Contact

For questions or issues, please refer to the project documentation or contact the team lead.
