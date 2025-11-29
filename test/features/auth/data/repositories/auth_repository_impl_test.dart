import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/core/errors/exceptions.dart';
import 'package:chatz/features/auth/domain/entities/user_entity.dart';
import 'package:chatz/features/auth/domain/repositories/auth_repository.dart';
import 'package:chatz/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:chatz/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:chatz/features/auth/data/models/user_model.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late AuthRepository repository;
  late MockAuthRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(remoteDataSource: mockDataSource);
  });

  const tPhoneNumber = '+1234567890';
  const tVerificationId = 'verification_id_123';
  const tSmsCode = '123456';
  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tDisplayName = 'Test User';

  const tUserModel = UserModel(
    id: 'user_123',
    email: tEmail,
    createdAt: DateTime(2024, 1, 1),
    isEmailVerified: true,
  );

  final tUserEntity = UserEntity(
    id: 'user_123',
    email: tEmail,
    createdAt: DateTime(2024, 1, 1),
    isEmailVerified: true,
  );

  group('AuthRepositoryImpl', () {
    group('signInWithPhone', () {
      test('should return verification ID when data source succeeds', () async {
        // arrange
        when(() => mockDataSource.signInWithPhone(any()))
            .thenAnswer((_) async => tVerificationId);

        // act
        final result = await repository.signInWithPhone(tPhoneNumber);

        // assert
        expect(result, const Right(tVerificationId));
        verify(() => mockDataSource.signInWithPhone(tPhoneNumber)).called(1);
      });

      test('should return AuthFailure when AuthException is thrown', () async {
        // arrange
        when(() => mockDataSource.signInWithPhone(any()))
            .thenThrow(const AuthException('Failed to send OTP'));

        // act
        final result = await repository.signInWithPhone(tPhoneNumber);

        // assert
        expect(result, const Left(AuthFailure('Failed to send OTP')));
      });

      test('should return NetworkFailure when NetworkException is thrown', () async {
        // arrange
        when(() => mockDataSource.signInWithPhone(any()))
            .thenThrow(const NetworkException());

        // act
        final result = await repository.signInWithPhone(tPhoneNumber);

        // assert
        expect(result, isA<Left>());
        expect((result as Left).value, isA<NetworkFailure>());
      });
    });

    group('verifyOtp', () {
      test('should return UserEntity when verification succeeds', () async {
        // arrange
        when(() => mockDataSource.verifyOtp(
              verificationId: any(named: 'verificationId'),
              smsCode: any(named: 'smsCode'),
            )).thenAnswer((_) async => tUserModel);

        // act
        final result = await repository.verifyOtp(
          verificationId: tVerificationId,
          smsCode: tSmsCode,
        );

        // assert
        expect(result, isA<Right>());
        final userEntity = (result as Right).value as UserEntity;
        expect(userEntity.id, tUserEntity.id);
        expect(userEntity.email, tUserEntity.email);
        verify(() => mockDataSource.verifyOtp(
              verificationId: tVerificationId,
              smsCode: tSmsCode,
            )).called(1);
      });

      test('should return AuthFailure when verification fails', () async {
        // arrange
        when(() => mockDataSource.verifyOtp(
              verificationId: any(named: 'verificationId'),
              smsCode: any(named: 'smsCode'),
            )).thenThrow(const AuthException('Invalid verification code'));

        // act
        final result = await repository.verifyOtp(
          verificationId: tVerificationId,
          smsCode: tSmsCode,
        );

        // assert
        expect(result, const Left(AuthFailure('Invalid verification code')));
      });
    });

    group('signInWithEmail', () {
      test('should return UserEntity when sign in succeeds', () async {
        // arrange
        when(() => mockDataSource.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => tUserModel);

        // act
        final result = await repository.signInWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // assert
        expect(result, isA<Right>());
        final userEntity = (result as Right).value as UserEntity;
        expect(userEntity.email, tEmail);
        verify(() => mockDataSource.signInWithEmail(
              email: tEmail,
              password: tPassword,
            )).called(1);
      });

      test('should return AuthFailure when credentials are invalid', () async {
        // arrange
        when(() => mockDataSource.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(const AuthException('Invalid password'));

        // act
        final result = await repository.signInWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // assert
        expect(result, const Left(AuthFailure('Invalid password')));
      });
    });

    group('signInWithGoogle', () {
      test('should return UserEntity when Google sign in succeeds', () async {
        // arrange
        when(() => mockDataSource.signInWithGoogle())
            .thenAnswer((_) async => tUserModel);

        // act
        final result = await repository.signInWithGoogle();

        // assert
        expect(result, isA<Right>());
        verify(() => mockDataSource.signInWithGoogle()).called(1);
      });

      test('should return AuthFailure when Google sign in fails', () async {
        // arrange
        when(() => mockDataSource.signInWithGoogle())
            .thenThrow(const AuthException('Google sign in failed'));

        // act
        final result = await repository.signInWithGoogle();

        // assert
        expect(result, const Left(AuthFailure('Google sign in failed')));
      });
    });

    group('registerWithEmail', () {
      test('should return UserEntity when registration succeeds', () async {
        // arrange
        when(() => mockDataSource.registerWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
              displayName: any(named: 'displayName'),
            )).thenAnswer((_) async => tUserModel);

        // act
        final result = await repository.registerWithEmail(
          email: tEmail,
          password: tPassword,
          displayName: tDisplayName,
        );

        // assert
        expect(result, isA<Right>());
        verify(() => mockDataSource.registerWithEmail(
              email: tEmail,
              password: tPassword,
              displayName: tDisplayName,
            )).called(1);
      });

      test('should return AuthFailure when email is already registered', () async {
        // arrange
        when(() => mockDataSource.registerWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
              displayName: any(named: 'displayName'),
            )).thenThrow(const AuthException('Email is already registered'));

        // act
        final result = await repository.registerWithEmail(
          email: tEmail,
          password: tPassword,
          displayName: tDisplayName,
        );

        // assert
        expect(result, const Left(AuthFailure('Email is already registered')));
      });
    });

    group('signOut', () {
      test('should return Unit when sign out succeeds', () async {
        // arrange
        when(() => mockDataSource.signOut()).thenAnswer((_) async {});

        // act
        final result = await repository.signOut();

        // assert
        expect(result, const Right(unit));
        verify(() => mockDataSource.signOut()).called(1);
      });

      test('should return AuthFailure when sign out fails', () async {
        // arrange
        when(() => mockDataSource.signOut())
            .thenThrow(const AuthException('Failed to sign out'));

        // act
        final result = await repository.signOut();

        // assert
        expect(result, const Left(AuthFailure('Failed to sign out')));
      });
    });

    group('getCurrentUser', () {
      test('should return UserEntity when user is signed in', () async {
        // arrange
        when(() => mockDataSource.getCurrentUser())
            .thenAnswer((_) async => tUserModel);

        // act
        final result = await repository.getCurrentUser();

        // assert
        expect(result, isA<Right>());
        verify(() => mockDataSource.getCurrentUser()).called(1);
      });

      test('should return null when no user is signed in', () async {
        // arrange
        when(() => mockDataSource.getCurrentUser())
            .thenAnswer((_) async => null);

        // act
        final result = await repository.getCurrentUser();

        // assert
        expect(result, const Right(null));
      });
    });

    group('isAuthenticated', () {
      test('should return true when user is signed in', () async {
        // arrange
        when(() => mockDataSource.isAuthenticated())
            .thenAnswer((_) async => true);

        // act
        final result = await repository.isAuthenticated();

        // assert
        expect(result, const Right(true));
      });

      test('should return false when no user is signed in', () async {
        // arrange
        when(() => mockDataSource.isAuthenticated())
            .thenAnswer((_) async => false);

        // act
        final result = await repository.isAuthenticated();

        // assert
        expect(result, const Right(false));
      });
    });
  });
}
