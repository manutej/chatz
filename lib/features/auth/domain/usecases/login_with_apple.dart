import 'package:dartz/dartz.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/features/auth/domain/entities/user_entity.dart';
import 'package:chatz/features/auth/domain/repositories/auth_repository.dart';

/// Use case for Sign in with Apple authentication
class LoginWithApple {
  final AuthRepository repository;

  LoginWithApple(this.repository);

  /// Execute the use case
  /// Returns authenticated user entity on success
  Future<Either<Failure, UserEntity>> call() async {
    return await repository.signInWithApple();
  }
}
