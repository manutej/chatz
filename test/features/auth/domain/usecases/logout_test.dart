import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/features/auth/domain/repositories/auth_repository.dart';
import 'package:chatz/features/auth/domain/usecases/logout.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late Logout useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = Logout(mockRepository);
  });

  group('Logout', () {
    test(
      'should return Unit when logout is successful',
      () async {
        // arrange
        when(() => mockRepository.signOut())
            .thenAnswer((_) async => const Right(unit));

        // act
        final result = await useCase();

        // assert
        expect(result, const Right(unit));
        verify(() => mockRepository.signOut()).called(1);
        verifyNoMoreInteractions(mockRepository);
      },
    );

    test(
      'should return AuthFailure when logout fails',
      () async {
        // arrange
        when(() => mockRepository.signOut()).thenAnswer(
          (_) async => const Left(AuthFailure('Failed to sign out')),
        );

        // act
        final result = await useCase();

        // assert
        expect(result, const Left(AuthFailure('Failed to sign out')));
        verify(() => mockRepository.signOut()).called(1);
      },
    );

    test(
      'should return NetworkFailure when there is no internet connection',
      () async {
        // arrange
        when(() => mockRepository.signOut())
            .thenAnswer((_) async => const Left(NetworkFailure()));

        // act
        final result = await useCase();

        // assert
        expect(result, const Left(NetworkFailure()));
      },
    );

    test(
      'should return ServerFailure when server error occurs',
      () async {
        // arrange
        when(() => mockRepository.signOut()).thenAnswer(
          (_) async => const Left(ServerFailure('Server error during logout')),
        );

        // act
        final result = await useCase();

        // assert
        expect(result, const Left(ServerFailure('Server error during logout')));
      },
    );
  });
}
