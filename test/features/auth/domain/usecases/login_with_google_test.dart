import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/features/auth/domain/entities/user_entity.dart';
import 'package:chatz/features/auth/domain/repositories/auth_repository.dart';
import 'package:chatz/features/auth/domain/usecases/login_with_google.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginWithGoogle useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginWithGoogle(mockRepository);
  });

  final tUser = UserEntity(
    id: 'user_123',
    email: 'user@gmail.com',
    displayName: 'Test User',
    photoUrl: 'https://example.com/photo.jpg',
    createdAt: DateTime(2024, 1, 1),
    isEmailVerified: true,
  );

  group('LoginWithGoogle', () {
    test(
      'should return UserEntity when Google sign in is successful',
      () async {
        // arrange
        when(() => mockRepository.signInWithGoogle())
            .thenAnswer((_) async => Right(tUser));

        // act
        final result = await useCase();

        // assert
        expect(result, Right(tUser));
        verify(() => mockRepository.signInWithGoogle()).called(1);
        verifyNoMoreInteractions(mockRepository);
      },
    );

    test(
      'should return AuthFailure when user cancels Google sign in',
      () async {
        // arrange
        when(() => mockRepository.signInWithGoogle()).thenAnswer(
          (_) async => const Left(AuthFailure('Google sign in cancelled')),
        );

        // act
        final result = await useCase();

        // assert
        expect(result, const Left(AuthFailure('Google sign in cancelled')));
        verify(() => mockRepository.signInWithGoogle()).called(1);
      },
    );

    test(
      'should return AuthFailure when Google sign in fails',
      () async {
        // arrange
        when(() => mockRepository.signInWithGoogle()).thenAnswer(
          (_) async => const Left(AuthFailure('Failed to sign in with Google')),
        );

        // act
        final result = await useCase();

        // assert
        expect(result, const Left(AuthFailure('Failed to sign in with Google')));
      },
    );

    test(
      'should return NetworkFailure when there is no internet connection',
      () async {
        // arrange
        when(() => mockRepository.signInWithGoogle())
            .thenAnswer((_) async => const Left(NetworkFailure()));

        // act
        final result = await useCase();

        // assert
        expect(result, const Left(NetworkFailure()));
      },
    );

    test(
      'should return ServerFailure when Google API fails',
      () async {
        // arrange
        when(() => mockRepository.signInWithGoogle())
            .thenAnswer((_) async => const Left(ServerFailure('Google API error')));

        // act
        final result = await useCase();

        // assert
        expect(result, const Left(ServerFailure('Google API error')));
      },
    );
  });
}
