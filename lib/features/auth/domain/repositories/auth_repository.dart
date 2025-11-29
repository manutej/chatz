import 'package:dartz/dartz.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/features/auth/domain/entities/user_entity.dart';

/// Authentication repository interface
/// Defines all authentication operations following repository pattern
/// Implementations will handle Firebase Auth, local storage, etc.
abstract class AuthRepository {
  /// Sign in with phone number (sends OTP)
  /// Returns verification ID for OTP verification
  Future<Either<Failure, String>> signInWithPhone(String phoneNumber);

  /// Verify OTP code
  /// Returns authenticated user entity
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String verificationId,
    required String smsCode,
  });

  /// Sign in with email and password
  /// Returns authenticated user entity
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign in with Google
  /// Returns authenticated user entity
  Future<Either<Failure, UserEntity>> signInWithGoogle();

  /// Sign in with Apple
  /// Returns authenticated user entity
  Future<Either<Failure, UserEntity>> signInWithApple();

  /// Register new user with email and password
  /// Returns authenticated user entity
  Future<Either<Failure, UserEntity>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  /// Sign out current user
  /// Returns Unit on success
  Future<Either<Failure, Unit>> signOut();

  /// Get current authenticated user
  /// Returns user entity or null if not authenticated
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Update user profile
  /// Returns updated user entity
  Future<Either<Failure, UserEntity>> updateProfile({
    String? displayName,
    String? photoUrl,
    String? bio,
  });

  /// Send password reset email
  /// Returns Unit on success
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email);

  /// Check if user is authenticated
  /// Returns true if user is signed in
  Future<Either<Failure, bool>> isAuthenticated();

  /// Enable biometric authentication
  /// Returns Unit on success
  Future<Either<Failure, Unit>> enableBiometric();

  /// Authenticate with biometric
  /// Returns authenticated user entity
  Future<Either<Failure, UserEntity>> authenticateWithBiometric();

  /// Stream of authentication state changes
  Stream<UserEntity?> get authStateChanges;
}
