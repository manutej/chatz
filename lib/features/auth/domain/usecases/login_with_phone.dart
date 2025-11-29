import 'package:dartz/dartz.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/features/auth/domain/repositories/auth_repository.dart';

/// Use case for initiating phone authentication
/// Sends OTP to the provided phone number
class LoginWithPhone {
  final AuthRepository repository;

  LoginWithPhone(this.repository);

  /// Execute the use case
  /// Returns verification ID on success
  Future<Either<Failure, String>> call(String phoneNumber) async {
    // Validate phone number format
    if (phoneNumber.isEmpty) {
      return const Left(ValidationFailure('Phone number cannot be empty'));
    }

    // Phone number should start with + and country code
    if (!phoneNumber.startsWith('+')) {
      return const Left(
        ValidationFailure('Phone number must include country code (e.g., +1)'),
      );
    }

    return await repository.signInWithPhone(phoneNumber);
  }
}
