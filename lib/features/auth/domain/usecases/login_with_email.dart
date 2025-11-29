import 'package:dartz/dartz.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/features/auth/domain/entities/user_entity.dart';
import 'package:chatz/features/auth/domain/repositories/auth_repository.dart';

/// Parameters for email login
class LoginWithEmailParams {
  final String email;
  final String password;

  const LoginWithEmailParams({
    required this.email,
    required this.password,
  });
}

/// Use case for email/password authentication
class LoginWithEmail {
  final AuthRepository repository;

  LoginWithEmail(this.repository);

  /// Execute the use case
  /// Returns authenticated user entity on success
  Future<Either<Failure, UserEntity>> call(LoginWithEmailParams params) async {
    // Validate email
    if (params.email.isEmpty) {
      return const Left(ValidationFailure('Email cannot be empty'));
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(params.email)) {
      return const Left(ValidationFailure('Invalid email format'));
    }

    // Validate password
    if (params.password.isEmpty) {
      return const Left(ValidationFailure('Password cannot be empty'));
    }

    if (params.password.length < 6) {
      return const Left(
        ValidationFailure('Password must be at least 6 characters'),
      );
    }

    return await repository.signInWithEmail(
      email: params.email,
      password: params.password,
    );
  }
}
