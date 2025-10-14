import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatz/shared/widgets/custom_button.dart';

void main() {
  group('CustomButton Widget Tests', () {
    testWidgets('should render button with given text', (tester) async {
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
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should call onPressed callback when tapped', (tester) async {
      // Arrange
      var wasPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Click Me',
              onPressed: () {
                wasPressed = true;
              },
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
      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.enabled, false);
    });

    testWidgets('should be disabled when isLoading is true', (tester) async {
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
      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.enabled, false);
    });

    testWidgets('should apply custom styling when provided', (tester) async {
      // Arrange
      const customColor = Colors.red;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Click Me',
              onPressed: () {},
              backgroundColor: customColor,
            ),
          ),
        ),
      );

      // Act
      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );

      // Assert
      expect(
        button.style?.backgroundColor?.resolve({}),
        customColor,
      );
    });

    testWidgets('should not call onPressed when loading', (tester) async {
      // Arrange
      var pressCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Click Me',
              onPressed: () {
                pressCount++;
              },
              isLoading: true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(CustomButton));
      await tester.pumpAndSettle();

      // Assert
      expect(pressCount, 0);
    });

    testWidgets('should have correct default padding', (tester) async {
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
      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.style?.padding, isNotNull);
    });

    testWidgets('should render icon when provided', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Click Me',
              onPressed: () {},
              icon: Icons.send,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.text('Click Me'), findsOneWidget);
    });

    testWidgets('should apply full width when specified', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Click Me',
              onPressed: () {},
              fullWidth: true,
            ),
          ),
        ),
      );

      // Assert
      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(ElevatedButton),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, double.infinity);
    });
  });
}
