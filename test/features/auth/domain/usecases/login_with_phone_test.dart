import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/features/auth/domain/repositories/auth_repository.dart';
import 'package:chatz/features/auth/domain/usecases/login_with_phone.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginWithPhone useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginWithPhone(mockRepository);
  });

  const tPhoneNumber = '+1234567890';
  const tVerificationId = 'verification_id_123';

  group('LoginWithPhone', () {
    test(
      'should return verification ID when phone number is valid',
      () async {
        // arrange
        when(() => mockRepository.signInWithPhone(any()))
            .thenAnswer((_) async => const Right(tVerificationId));

        // act
        final result = await useCase(tPhoneNumber);

        // assert
        expect(result, const Right(tVerificationId));
        verify(() => mockRepository.signInWithPhone(tPhoneNumber)).called(1);
        verifyNoMoreInteractions(mockRepository);
      },
    );

    test(
      'should return ValidationFailure when phone number is empty',
      () async {
        // arrange
        const emptyPhone = '';

        // act
        final result = await useCase(emptyPhone);

        // assert
        expect(
          result,
          const Left(ValidationFailure('Phone number cannot be empty')),
        );
        verifyZeroInteractions(mockRepository);
      },
    );

    test(
      'should return ValidationFailure when phone number does not start with +',
      () async {
        // arrange
        const invalidPhone = '1234567890';

        // act
        final result = await useCase(invalidPhone);

        // assert
        expect(
          result,
          const Left(
            ValidationFailure('Phone number must include country code (e.g., +1)'),
          ),
        );
        verifyZeroInteractions(mockRepository);
      },
    );

    test(
      'should return AuthFailure when repository fails',
      () async {
        // arrange
        when(() => mockRepository.signInWithPhone(any()))
            .thenAnswer((_) async => const Left(AuthFailure('Failed to send OTP')));

        // act
        final result = await useCase(tPhoneNumber);

        // assert
        expect(result, const Left(AuthFailure('Failed to send OTP')));
        verify(() => mockRepository.signInWithPhone(tPhoneNumber)).called(1);
      },
    );

    test(
      'should return NetworkFailure when there is no internet connection',
      () async {
        // arrange
        when(() => mockRepository.signInWithPhone(any()))
            .thenAnswer((_) async => const Left(NetworkFailure()));

        // act
        final result = await useCase(tPhoneNumber);

        // assert
        expect(result, const Left(NetworkFailure()));
        verify(() => mockRepository.signInWithPhone(tPhoneNumber)).called(1);
      },
    );

    test(
      'should handle various valid phone number formats',
      () async {
        // arrange
        final validPhoneNumbers = [
          '+14155552671',
          '+919876543210',
          '+447700900123',
          '+861234567890',
        ];

        when(() => mockRepository.signInWithPhone(any()))
            .thenAnswer((_) async => const Right(tVerificationId));

        // act & assert
        for (final phoneNumber in validPhoneNumbers) {
          final result = await useCase(phoneNumber);
          expect(result, const Right(tVerificationId));
        }

        verify(() => mockRepository.signInWithPhone(any()))
            .called(validPhoneNumbers.length);
      },
    );
  });
}
