import 'package:dartz/dartz.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/features/auth/domain/repositories/auth_repository.dart';

/// Use case for signing out the current user
class Logout {
  final AuthRepository repository;

  Logout(this.repository);

  /// Execute the use case
  /// Returns Unit on success
  Future<Either<Failure, Unit>> call() async {
    return await repository.signOut();
  }
}
