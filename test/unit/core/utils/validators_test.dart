import 'package:flutter_test/flutter_test.dart';
import 'package:chatz/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('validatePhoneNumber', () {
      test('should return null for valid phone number with country code', () {
        // Arrange
        const validPhone = '+1234567890';

        // Act
        final result = Validators.validatePhoneNumber(validPhone);

        // Assert
        expect(result, null);
      });

      test('should return null for valid phone number with different country code', () {
        // Arrange
        const validPhone = '+442071234567';

        // Act
        final result = Validators.validatePhoneNumber(validPhone);

        // Assert
        expect(result, null);
      });

      test('should return error message for phone number without country code', () {
        // Arrange
        const invalidPhone = '1234567890';

        // Act
        final result = Validators.validatePhoneNumber(invalidPhone);

        // Assert
        expect(result, isNotNull);
        expect(result, contains('valid'));
      });

      test('should return error message for too short phone number', () {
        // Arrange
        const invalidPhone = '+123';

        // Act
        final result = Validators.validatePhoneNumber(invalidPhone);

        // Assert
        expect(result, isNotNull);
      });

      test('should return error message for empty phone number', () {
        // Arrange
        const emptyPhone = '';

        // Act
        final result = Validators.validatePhoneNumber(emptyPhone);

        // Assert
        expect(result, 'Phone number is required');
      });

      test('should return error message for null phone number', () {
        // Act
        final result = Validators.validatePhoneNumber(null);

        // Assert
        expect(result, 'Phone number is required');
      });

      test('should return error message for phone with invalid characters', () {
        // Arrange
        const invalidPhone = '+1234abc567';

        // Act
        final result = Validators.validatePhoneNumber(invalidPhone);

        // Assert
        expect(result, isNotNull);
      });
    });

    group('validateEmail', () {
      test('should return null for valid email', () {
        // Arrange
        const validEmail = 'test@example.com';

        // Act
        final result = Validators.validateEmail(validEmail);

        // Assert
        expect(result, null);
      });

      test('should return null for valid email with subdomain', () {
        // Arrange
        const validEmail = 'user@mail.example.com';

        // Act
        final result = Validators.validateEmail(validEmail);

        // Assert
        expect(result, null);
      });

      test('should return null for valid email with plus sign', () {
        // Arrange
        const validEmail = 'user+tag@example.com';

        // Act
        final result = Validators.validateEmail(validEmail);

        // Assert
        expect(result, null);
      });

      test('should return error for email without @', () {
        // Arrange
        const invalidEmail = 'testexample.com';

        // Act
        final result = Validators.validateEmail(invalidEmail);

        // Assert
        expect(result, 'Please enter a valid email');
      });

      test('should return error for email without domain', () {
        // Arrange
        const invalidEmail = 'test@';

        // Act
        final result = Validators.validateEmail(invalidEmail);

        // Assert
        expect(result, 'Please enter a valid email');
      });

      test('should return error for email without username', () {
        // Arrange
        const invalidEmail = '@example.com';

        // Act
        final result = Validators.validateEmail(invalidEmail);

        // Assert
        expect(result, 'Please enter a valid email');
      });

      test('should return error for empty email', () {
        // Arrange
        const emptyEmail = '';

        // Act
        final result = Validators.validateEmail(emptyEmail);

        // Assert
        expect(result, 'Email is required');
      });

      test('should return error for null email', () {
        // Act
        final result = Validators.validateEmail(null);

        // Assert
        expect(result, 'Email is required');
      });
    });

    group('validatePassword', () {
      test('should return null for valid password', () {
        // Arrange
        const validPassword = 'StrongP@ss123';

        // Act
        final result = Validators.validatePassword(validPassword);

        // Assert
        expect(result, null);
      });

      test('should return null for minimum length password', () {
        // Arrange
        const validPassword = 'Pass123!';

        // Act
        final result = Validators.validatePassword(validPassword);

        // Assert
        expect(result, null);
      });

      test('should return error for password shorter than 8 characters', () {
        // Arrange
        const shortPassword = 'Pass12!';

        // Act
        final result = Validators.validatePassword(shortPassword);

        // Assert
        expect(result, 'Password must be at least 8 characters long');
      });

      test('should return error for empty password', () {
        // Arrange
        const emptyPassword = '';

        // Act
        final result = Validators.validatePassword(emptyPassword);

        // Assert
        expect(result, 'Password is required');
      });

      test('should return error for null password', () {
        // Act
        final result = Validators.validatePassword(null);

        // Assert
        expect(result, 'Password is required');
      });
    });

    group('validateDisplayName', () {
      test('should return null for valid display name', () {
        // Arrange
        const validName = 'John Doe';

        // Act
        final result = Validators.validateDisplayName(validName);

        // Assert
        expect(result, null);
      });

      test('should return null for single word name', () {
        // Arrange
        const validName = 'John';

        // Act
        final result = Validators.validateDisplayName(validName);

        // Assert
        expect(result, null);
      });

      test('should return error for name shorter than 2 characters', () {
        // Arrange
        const shortName = 'J';

        // Act
        final result = Validators.validateDisplayName(shortName);

        // Assert
        expect(result, 'Name must be at least 2 characters long');
      });

      test('should return error for empty name', () {
        // Arrange
        const emptyName = '';

        // Act
        final result = Validators.validateDisplayName(emptyName);

        // Assert
        expect(result, 'Display name is required');
      });

      test('should return error for null name', () {
        // Act
        final result = Validators.validateDisplayName(null);

        // Assert
        expect(result, 'Display name is required');
      });

      test('should trim whitespace from name', () {
        // Arrange
        const nameWithSpaces = '  John Doe  ';

        // Act
        final result = Validators.validateDisplayName(nameWithSpaces);

        // Assert
        expect(result, null);
      });
    });
  });
}
