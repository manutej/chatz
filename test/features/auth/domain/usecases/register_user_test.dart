import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/features/auth/domain/entities/user_entity.dart';
import 'package:chatz/features/auth/domain/repositories/auth_repository.dart';
import 'package:chatz/features/auth/domain/usecases/register_user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late RegisterUser useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = RegisterUser(mockRepository);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'Password123!';
  const tDisplayName = 'Test User';
  final tUser = UserEntity(
    id: 'user_123',
    email: tEmail,
    displayName: tDisplayName,
    createdAt: DateTime(2024, 1, 1),
    isEmailVerified: false,
  );

  group('RegisterUser', () {
    test(
      'should return UserEntity when registration is successful',
      () async {
        // arrange
        const params = RegisterUserParams(
          email: tEmail,
          password: tPassword,
          displayName: tDisplayName,
        );
        when(() => mockRepository.registerWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
              displayName: any(named: 'displayName'),
            )).thenAnswer((_) async => Right(tUser));

        // act
        final result = await useCase(params);

        // assert
        expect(result, Right(tUser));
        verify(() => mockRepository.registerWithEmail(
              email: tEmail,
              password: tPassword,
              displayName: tDisplayName,
            )).called(1);
        verifyNoMoreInteractions(mockRepository);
      },
    );

    test(
      'should return ValidationFailure when email is empty',
      () async {
        // arrange
        const params = RegisterUserParams(
          email: '',
          password: tPassword,
          displayName: tDisplayName,
        );

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
        const params = RegisterUserParams(
          email: tEmail,
          password: '',
          displayName: tDisplayName,
        );

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
      'should return ValidationFailure when display name is empty',
      () async {
        // arrange
        const params = RegisterUserParams(
          email: tEmail,
          password: tPassword,
          displayName: '',
        );

        // act
        final result = await useCase(params);

        // assert
        expect(
          result,
          const Left(ValidationFailure('Display name cannot be empty')),
        );
        verifyZeroInteractions(mockRepository);
      },
    );

    test(
      'should return ValidationFailure when email format is invalid',
      () async {
        // arrange
        const params = RegisterUserParams(
          email: 'invalid-email',
          password: tPassword,
          displayName: tDisplayName,
        );

        // act
        final result = await useCase(params);

        // assert
        expect(
          result,
          const Left(ValidationFailure('Invalid email format')),
        );
        verifyZeroInteractions(mockRepository);
      },
    );

    test(
      'should return ValidationFailure when password is too short',
      () async {
        // arrange
        const params = RegisterUserParams(
          email: tEmail,
          password: '12345',
          displayName: tDisplayName,
        );

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
      'should return ValidationFailure when display name is too short',
      () async {
        // arrange
        const params = RegisterUserParams(
          email: tEmail,
          password: tPassword,
          displayName: 'A',
        );

        // act
        final result = await useCase(params);

        // assert
        expect(
          result,
          const Left(
            ValidationFailure('Display name must be at least 2 characters'),
          ),
        );
        verifyZeroInteractions(mockRepository);
      },
    );

    test(
      'should return AuthFailure when email is already registered',
      () async {
        // arrange
        const params = RegisterUserParams(
          email: tEmail,
          password: tPassword,
          displayName: tDisplayName,
        );
        when(() => mockRepository.registerWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
              displayName: any(named: 'displayName'),
            )).thenAnswer(
          (_) async => const Left(AuthFailure('Email is already registered')),
        );

        // act
        final result = await useCase(params);

        // assert
        expect(result, const Left(AuthFailure('Email is already registered')));
      },
    );

    test(
      'should return AuthFailure when password is too weak',
      () async {
        // arrange
        const params = RegisterUserParams(
          email: tEmail,
          password: 'simple',
          displayName: tDisplayName,
        );
        when(() => mockRepository.registerWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
              displayName: any(named: 'displayName'),
            )).thenAnswer(
          (_) async => const Left(AuthFailure('Password is too weak')),
        );

        // act
        final result = await useCase(params);

        // assert
        expect(result, const Left(AuthFailure('Password is too weak')));
      },
    );

    test(
      'should return NetworkFailure when there is no internet connection',
      () async {
        // arrange
        const params = RegisterUserParams(
          email: tEmail,
          password: tPassword,
          displayName: tDisplayName,
        );
        when(() => mockRepository.registerWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
              displayName: any(named: 'displayName'),
            )).thenAnswer((_) async => const Left(NetworkFailure()));

        // act
        final result = await useCase(params);

        // assert
        expect(result, const Left(NetworkFailure()));
      },
    );
  });
}
