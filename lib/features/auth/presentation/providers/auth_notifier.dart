import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatz/features/auth/presentation/providers/auth_state.dart';
import 'package:chatz/features/auth/domain/usecases/login_with_phone.dart';
import 'package:chatz/features/auth/domain/usecases/verify_otp.dart';
import 'package:chatz/features/auth/domain/usecases/login_with_email.dart';
import 'package:chatz/features/auth/domain/usecases/login_with_google.dart';
import 'package:chatz/features/auth/domain/usecases/login_with_apple.dart';
import 'package:chatz/features/auth/domain/usecases/register_user.dart';
import 'package:chatz/features/auth/domain/usecases/logout.dart';
import 'package:chatz/features/auth/domain/usecases/get_current_user.dart';
import 'package:chatz/features/auth/domain/repositories/auth_repository.dart';

/// Authentication StateNotifier
/// Manages authentication state and operations
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginWithPhone loginWithPhone;
  final VerifyOtp verifyOtp;
  final LoginWithEmail loginWithEmail;
  final LoginWithGoogle loginWithGoogle;
  final LoginWithApple loginWithApple;
  final RegisterUser registerUser;
  final Logout logout;
  final GetCurrentUser getCurrentUser;
  final AuthRepository authRepository;

  AuthNotifier({
    required this.loginWithPhone,
    required this.verifyOtp,
    required this.loginWithEmail,
    required this.loginWithGoogle,
    required this.loginWithApple,
    required this.registerUser,
    required this.logout,
    required this.getCurrentUser,
    required this.authRepository,
  }) : super(const AuthState.initial()) {
    _checkAuthStatus();
    _listenToAuthChanges();
  }

  /// Check initial authentication status
  Future<void> _checkAuthStatus() async {
    state = const AuthState.loading();
    
    final result = await getCurrentUser();
    
    result.fold(
      (failure) => state = const AuthState.unauthenticated(),
      (user) {
        if (user == null) {
          state = const AuthState.unauthenticated();
        } else if (!user.hasCompletedProfile) {
          state = AuthState.profileIncomplete(user);
        } else {
          state = AuthState.authenticated(user);
        }
      },
    );
  }

  /// Listen to auth state changes
  void _listenToAuthChanges() {
    authRepository.authStateChanges.listen((user) {
      if (user == null) {
        state = const AuthState.unauthenticated();
      } else if (!user.hasCompletedProfile) {
        state = AuthState.profileIncomplete(user);
      } else {
        state = AuthState.authenticated(user);
      }
    });
  }

  /// Sign in with phone number
  Future<void> signInWithPhoneNumber(String phoneNumber) async {
    state = const AuthState.loading();
    
    final result = await loginWithPhone(phoneNumber);
    
    result.fold(
      (failure) => state = AuthState.error(failure.message),
      (verificationId) => state = AuthState.verificationCodeSent(verificationId),
    );
  }

  /// Verify OTP code
  Future<void> verifyOtpCode({
    required String verificationId,
    required String smsCode,
  }) async {
    state = const AuthState.loading();
    
    final result = await verifyOtp(
      VerifyOtpParams(
        verificationId: verificationId,
        smsCode: smsCode,
      ),
    );
    
    result.fold(
      (failure) => state = AuthState.error(failure.message),
      (user) {
        if (!user.hasCompletedProfile) {
          state = AuthState.profileIncomplete(user);
        } else {
          state = AuthState.authenticated(user);
        }
      },
    );
  }

  /// Sign in with email and password
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    
    final result = await loginWithEmail(
      LoginWithEmailParams(
        email: email,
        password: password,
      ),
    );
    
    result.fold(
      (failure) => state = AuthState.error(failure.message),
      (user) => state = AuthState.authenticated(user),
    );
  }

  /// Sign in with Google
  Future<void> signInWithGoogleAccount() async {
    state = const AuthState.loading();
    
    final result = await loginWithGoogle();
    
    result.fold(
      (failure) => state = AuthState.error(failure.message),
      (user) {
        if (!user.hasCompletedProfile) {
          state = AuthState.profileIncomplete(user);
        } else {
          state = AuthState.authenticated(user);
        }
      },
    );
  }

  /// Sign in with Apple
  Future<void> signInWithAppleAccount() async {
    state = const AuthState.loading();
    
    final result = await loginWithApple();
    
    result.fold(
      (failure) => state = AuthState.error(failure.message),
      (user) {
        if (!user.hasCompletedProfile) {
          state = AuthState.profileIncomplete(user);
        } else {
          state = AuthState.authenticated(user);
        }
      },
    );
  }

  /// Register new user
  Future<void> registerNewUser({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AuthState.loading();
    
    final result = await registerUser(
      RegisterUserParams(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
    
    result.fold(
      (failure) => state = AuthState.error(failure.message),
      (user) => state = AuthState.authenticated(user),
    );
  }

  /// Sign out
  Future<void> signOutUser() async {
    state = const AuthState.loading();
    
    final result = await logout();
    
    result.fold(
      (failure) => state = AuthState.error(failure.message),
      (_) => state = const AuthState.unauthenticated(),
    );
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
    String? bio,
  }) async {
    state = const AuthState.loading();
    
    final result = await authRepository.updateProfile(
      displayName: displayName,
      photoUrl: photoUrl,
      bio: bio,
    );
    
    result.fold(
      (failure) => state = AuthState.error(failure.message),
      (user) => state = AuthState.authenticated(user),
    );
  }

  /// Send password reset email
  Future<void> sendPasswordReset(String email) async {
    final result = await authRepository.sendPasswordResetEmail(email);
    
    result.fold(
      (failure) => state = AuthState.error(failure.message),
      (_) {}, // Success handled in UI
    );
  }
}
