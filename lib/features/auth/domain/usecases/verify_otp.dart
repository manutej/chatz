import 'package:dartz/dartz.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/features/auth/domain/entities/user_entity.dart';
import 'package:chatz/features/auth/domain/repositories/auth_repository.dart';

/// Parameters for OTP verification
class VerifyOtpParams {
  final String verificationId;
  final String smsCode;

  const VerifyOtpParams({
    required this.verificationId,
    required this.smsCode,
  });
}

/// Use case for verifying OTP code
/// Completes phone authentication flow
class VerifyOtp {
  final AuthRepository repository;

  VerifyOtp(this.repository);

  /// Execute the use case
  /// Returns authenticated user entity on success
  Future<Either<Failure, UserEntity>> call(VerifyOtpParams params) async {
    // Validate OTP code
    if (params.smsCode.isEmpty) {
      return const Left(ValidationFailure('OTP code cannot be empty'));
    }

    if (params.smsCode.length != 6) {
      return const Left(ValidationFailure('OTP code must be 6 digits'));
    }

    if (params.verificationId.isEmpty) {
      return const Left(ValidationFailure('Verification ID is required'));
    }

    return await repository.verifyOtp(
      verificationId: params.verificationId,
      smsCode: params.smsCode,
    );
  }
}
