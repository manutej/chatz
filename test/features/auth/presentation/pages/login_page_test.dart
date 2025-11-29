import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chatz/features/auth/presentation/pages/login_page.dart';
import 'package:chatz/features/auth/presentation/providers/auth_notifier.dart';
import 'package:chatz/features/auth/presentation/providers/auth_state.dart';

// Mock classes
class MockAuthNotifier extends Mock implements AuthNotifier {}

// Example Widget Test for LoginPage
// This demonstrates the structure for testing presentation layer
void main() {
  late MockAuthNotifier mockAuthNotifier;

  setUp(() {
    mockAuthNotifier = MockAuthNotifier();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        // Override providers with mocks here
        // authNotifierProvider.overrideWith((ref) => mockAuthNotifier),
      ],
      child: const MaterialApp(
        home: LoginPage(),
      ),
    );
  }

  group('LoginPage Widget Tests', () {
    testWidgets('should display login page with all required elements',
        (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthNotifier.state).thenReturn(const AuthInitial());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      // Look for key UI elements (adjust based on actual implementation)
      expect(find.text('Login'), findsOneWidget);
      // expect(find.byType(TextField), findsWidgets);
      // expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should show email and password fields',
        (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthNotifier.state).thenReturn(const AuthInitial());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      // Add your assertions based on actual widget implementation
      // expect(find.byKey(const Key('email_field')), findsOneWidget);
      // expect(find.byKey(const Key('password_field')), findsOneWidget);
    });

    testWidgets('should show validation error when email is invalid',
        (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthNotifier.state).thenReturn(const AuthInitial());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter invalid email
      // await tester.enterText(find.byKey(const Key('email_field')), 'invalid');
      // await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Assert
      // expect(find.text('Invalid email format'), findsOneWidget);
    });

    testWidgets('should call login when form is submitted with valid data',
        (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthNotifier.state).thenReturn(const AuthInitial());
      when(() => mockAuthNotifier.loginWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter valid credentials
      // await tester.enterText(
      //   find.byKey(const Key('email_field')),
      //   'test@example.com',
      // );
      // await tester.enterText(
      //   find.byKey(const Key('password_field')),
      //   'password123',
      // );
      // await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Assert
      // verify(() => mockAuthNotifier.loginWithEmail(
      //       email: 'test@example.com',
      //       password: 'password123',
      //     )).called(1);
    });

    testWidgets('should show loading indicator during authentication',
        (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthNotifier.state).thenReturn(const AuthLoading());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error message when authentication fails',
        (WidgetTester tester) async {
      // Arrange
      const errorMessage = 'Invalid credentials';
      when(() => mockAuthNotifier.state)
          .thenReturn(const AuthError(errorMessage));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Assert
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('should navigate to phone verification page',
        (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthNotifier.state).thenReturn(const AuthInitial());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap on phone login button
      // await tester.tap(find.byKey(const Key('phone_login_button')));
      await tester.pumpAndSettle();

      // Assert - verify navigation occurred
      // expect(find.byType(PhoneVerificationPage), findsOneWidget);
    });

    testWidgets('should show social login buttons',
        (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthNotifier.state).thenReturn(const AuthInitial());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      // expect(find.byKey(const Key('google_login_button')), findsOneWidget);
      // expect(find.byKey(const Key('apple_login_button')), findsOneWidget);
    });

    testWidgets('should call Google login when Google button is tapped',
        (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthNotifier.state).thenReturn(const AuthInitial());
      when(() => mockAuthNotifier.loginWithGoogle())
          .thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // await tester.tap(find.byKey(const Key('google_login_button')));
      await tester.pumpAndSettle();

      // Assert
      // verify(() => mockAuthNotifier.loginWithGoogle()).called(1);
    });
  });
}

/*
NOTE: The commented-out code shows the structure of widget tests.
Uncomment and adapt based on your actual LoginPage implementation.
Add keys to your widgets for easier testing:

Example:
TextField(
  key: const Key('email_field'),
  decoration: const InputDecoration(labelText: 'Email'),
)

ElevatedButton(
  key: const Key('login_button'),
  onPressed: () => {},
  child: const Text('Login'),
)
*/
