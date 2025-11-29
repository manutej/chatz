import 'package:dartz/dartz.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/features/auth/domain/entities/user_entity.dart';
import 'package:chatz/features/auth/domain/repositories/auth_repository.dart';

/// Parameters for user registration
class RegisterUserParams {
  final String email;
  final String password;
  final String displayName;

  const RegisterUserParams({
    required this.email,
    required this.password,
    required this.displayName,
  });
}

/// Use case for registering a new user with email and password
class RegisterUser {
  final AuthRepository repository;

  RegisterUser(this.repository);

  /// Execute the use case
  /// Returns authenticated user entity on success
  Future<Either<Failure, UserEntity>> call(RegisterUserParams params) async {
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

    // Validate display name
    if (params.displayName.isEmpty) {
      return const Left(ValidationFailure('Display name cannot be empty'));
    }

    if (params.displayName.length < 2) {
      return const Left(
        ValidationFailure('Display name must be at least 2 characters'),
      );
    }

    return await repository.registerWithEmail(
      email: params.email,
      password: params.password,
      displayName: params.displayName,
    );
  }
}
