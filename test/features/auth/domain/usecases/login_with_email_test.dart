import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/features/auth/domain/entities/user_entity.dart';
import 'package:chatz/features/auth/domain/repositories/auth_repository.dart';
import 'package:chatz/features/auth/domain/usecases/login_with_email.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginWithEmail useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginWithEmail(mockRepository);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'Password123!';
  final tUser = UserEntity(
    id: 'user_123',
    email: tEmail,
    createdAt: DateTime(2024, 1, 1),
    isEmailVerified: true,
  );

  group('LoginWithEmail', () {
    test(
      'should return UserEntity when login is successful',
      () async {
        // arrange
        const params = LoginWithEmailParams(email: tEmail, password: tPassword);
        when(() => mockRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => Right(tUser));

        // act
        final result = await useCase(params);

        // assert
        expect(result, Right(tUser));
        verify(() => mockRepository.signInWithEmail(
              email: tEmail,
              password: tPassword,
            )).called(1);
        verifyNoMoreInteractions(mockRepository);
      },
    );

    test(
      'should return ValidationFailure when email is empty',
      () async {
        // arrange
        const params = LoginWithEmailParams(email: '', password: tPassword);

        // act
        final result = await useCase(params);

        // assert
        expect(
          result,
          const Left(ValidationFailure('Email cannot be empty')),
        );
        verifyZeroInteractions(mockRepository);
      },
    );

    test(
      'should return ValidationFailure when password is empty',
      () async {
        // arrange
        const params = LoginWithEmailParams(email: tEmail, password: '');

        // act
        final result = await useCase(params);

        // assert
        expect(
          result,
          const Left(ValidationFailure('Password cannot be empty')),
        );
        verifyZeroInteractions(mockRepository);
      },
    );

    test(
      'should return ValidationFailure when email format is invalid',
      () async {
        // arrange
        const invalidEmails = [
          'invalid',
          'invalid@',
          '@invalid.com',
          'invalid@.com',
          'invalid.com',
        ];

        // act & assert
        for (final email in invalidEmails) {
          final params = LoginWithEmailParams(email: email, password: tPassword);
          final result = await useCase(params);
          expect(
            result,
            const Left(ValidationFailure('Invalid email format')),
          );
        }

        verifyZeroInteractions(mockRepository);
      },
    );

    test(
      'should return ValidationFailure when password is too short',
      () async {
        // arrange
        const params = LoginWithEmailParams(email: tEmail, password: '12345');

        // act
        final result = await useCase(params);

        // assert
        expect(
          result,
          const Left(ValidationFailure('Password must be at least 6 characters')),
        );
        verifyZeroInteractions(mockRepository);
      },
    );

    test(
      'should accept valid email formats',
      () async {
        // arrange
        const validEmails = [
          'user@example.com',
          'user.name@example.com',
          'user+tag@example.co.uk',
          'user_name@sub.example.com',
        ];

        when(() => mockRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => Right(tUser));

        // act & assert
        for (final email in validEmails) {
          final params = LoginWithEmailParams(email: email, password: tPassword);
          final result = await useCase(params);
          expect(result, Right(tUser));
        }

        verify(() => mockRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).called(validEmails.length);
      },
    );

    test(
      'should return AuthFailure when credentials are incorrect',
      () async {
        // arrange
        const params = LoginWithEmailParams(email: tEmail, password: tPassword);
        when(() => mockRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => const Left(AuthFailure('Invalid password')));

        // act
        final result = await useCase(params);

        // assert
        expect(result, const Left(AuthFailure('Invalid password')));
      },
    );

    test(
      'should return AuthFailure when user does not exist',
      () async {
        // arrange
        const params = LoginWithEmailParams(email: tEmail, password: tPassword);
        when(() => mockRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer(
          (_) async => const Left(AuthFailure('No user found with this email')),
        );

        // act
        final result = await useCase(params);

        // assert
        expect(result, const Left(AuthFailure('No user found with this email')));
      },
    );

    test(
      'should return NetworkFailure when there is no internet connection',
      () async {
        // arrange
        const params = LoginWithEmailParams(email: tEmail, password: tPassword);
        when(() => mockRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => const Left(NetworkFailure()));

        // act
        final result = await useCase(params);

        // assert
        expect(result, const Left(NetworkFailure()));
      },
    );
  });
}
