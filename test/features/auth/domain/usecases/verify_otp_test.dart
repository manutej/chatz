import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/features/auth/domain/entities/user_entity.dart';
import 'package:chatz/features/auth/domain/repositories/auth_repository.dart';
import 'package:chatz/features/auth/domain/usecases/verify_otp.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late VerifyOtp useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = VerifyOtp(mockRepository);
  });

  const tVerificationId = 'verification_id_123';
  const tSmsCode = '123456';
  final tUser = UserEntity(
    id: 'user_123',
    phoneNumber: '+1234567890',
    createdAt: DateTime(2024, 1, 1),
    isPhoneVerified: true,
  );

  group('VerifyOtp', () {
    test(
      'should return UserEntity when OTP verification is successful',
      () async {
        // arrange
        const params = VerifyOtpParams(
          verificationId: tVerificationId,
          smsCode: tSmsCode,
        );
        when(() => mockRepository.verifyOtp(
              verificationId: any(named: 'verificationId'),
              smsCode: any(named: 'smsCode'),
            )).thenAnswer((_) async => Right(tUser));

        // act
        final result = await useCase(params);

        // assert
        expect(result, Right(tUser));
        verify(() => mockRepository.verifyOtp(
              verificationId: tVerificationId,
              smsCode: tSmsCode,
            )).called(1);
        verifyNoMoreInteractions(mockRepository);
      },
    );

    test(
      'should return ValidationFailure when verification ID is empty',
      () async {
        // arrange
        const params = VerifyOtpParams(
          verificationId: '',
          smsCode: tSmsCode,
        );

        // act
        final result = await useCase(params);

        // assert
        expect(
          result,
          const Left(ValidationFailure('Verification ID is required')),
        );
        verifyZeroInteractions(mockRepository);
      },
    );

    test(
      'should return ValidationFailure when SMS code is empty',
      () async {
        // arrange
        const params = VerifyOtpParams(
          verificationId: tVerificationId,
          smsCode: '',
        );

        // act
        final result = await useCase(params);

        // assert
        expect(
          result,
          const Left(ValidationFailure('OTP code cannot be empty')),
        );
        verifyZeroInteractions(mockRepository);
      },
    );

    test(
      'should return ValidationFailure when SMS code is not 6 digits',
      () async {
        // arrange
        const params1 = VerifyOtpParams(
          verificationId: tVerificationId,
          smsCode: '12345',
        );
        const params2 = VerifyOtpParams(
          verificationId: tVerificationId,
          smsCode: '1234567',
        );

        // act
        final result1 = await useCase(params1);
        final result2 = await useCase(params2);

        // assert
        expect(
          result1,
          const Left(ValidationFailure('OTP code must be 6 digits')),
        );
        expect(
          result2,
          const Left(ValidationFailure('OTP code must be 6 digits')),
        );
        verifyZeroInteractions(mockRepository);
      },
    );

    test(
      'should return AuthFailure when OTP is invalid',
      () async {
        // arrange
        const params = VerifyOtpParams(
          verificationId: tVerificationId,
          smsCode: tSmsCode,
        );
        when(() => mockRepository.verifyOtp(
              verificationId: any(named: 'verificationId'),
              smsCode: any(named: 'smsCode'),
            )).thenAnswer(
          (_) async => const Left(AuthFailure('Invalid verification code')),
        );

        // act
        final result = await useCase(params);

        // assert
        expect(result, const Left(AuthFailure('Invalid verification code')));
        verify(() => mockRepository.verifyOtp(
              verificationId: tVerificationId,
              smsCode: tSmsCode,
            )).called(1);
      },
    );

    test(
      'should return AuthFailure when verification session has expired',
      () async {
        // arrange
        const params = VerifyOtpParams(
          verificationId: tVerificationId,
          smsCode: tSmsCode,
        );
        when(() => mockRepository.verifyOtp(
              verificationId: any(named: 'verificationId'),
              smsCode: any(named: 'smsCode'),
            )).thenAnswer(
          (_) async => const Left(AuthFailure('Session expired. Please try again')),
        );

        // act
        final result = await useCase(params);

        // assert
        expect(
          result,
          const Left(AuthFailure('Session expired. Please try again')),
        );
      },
    );

    test(
      'should return NetworkFailure when there is no internet connection',
      () async {
        // arrange
        const params = VerifyOtpParams(
          verificationId: tVerificationId,
          smsCode: tSmsCode,
        );
        when(() => mockRepository.verifyOtp(
              verificationId: any(named: 'verificationId'),
              smsCode: any(named: 'smsCode'),
            )).thenAnswer((_) async => const Left(NetworkFailure()));

        // act
        final result = await useCase(params);

        // assert
        expect(result, const Left(NetworkFailure()));
      },
    );
  });
}
