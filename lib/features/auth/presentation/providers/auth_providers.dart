import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:chatz/core/di/injection.dart';
import 'package:chatz/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:chatz/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:chatz/features/auth/domain/repositories/auth_repository.dart';
import 'package:chatz/features/auth/domain/usecases/login_with_phone.dart';
import 'package:chatz/features/auth/domain/usecases/verify_otp.dart';
import 'package:chatz/features/auth/domain/usecases/login_with_email.dart';
import 'package:chatz/features/auth/domain/usecases/login_with_google.dart';
import 'package:chatz/features/auth/domain/usecases/login_with_apple.dart';
import 'package:chatz/features/auth/domain/usecases/register_user.dart';
import 'package:chatz/features/auth/domain/usecases/logout.dart';
import 'package:chatz/features/auth/domain/usecases/get_current_user.dart';
import 'package:chatz/features/auth/presentation/providers/auth_notifier.dart';
import 'package:chatz/features/auth/presentation/providers/auth_state.dart';

/// Google Sign-In provider
final googleSignInProvider = Provider<GoogleSignIn>(
  (ref) => GoogleSignIn(
    scopes: ['email', 'profile'],
  ),
);

/// Secure Storage provider
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

/// Local Auth provider
final localAuthProvider = Provider<LocalAuthentication>(
  (ref) => LocalAuthentication(),
);

/// Auth Remote Data Source provider
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSourceImpl(
    firebaseAuth: sl(),
    firestore: sl(),
    googleSignIn: ref.watch(googleSignInProvider),
    secureStorage: ref.watch(secureStorageProvider),
    localAuth: ref.watch(localAuthProvider),
  ),
);

/// Auth Repository provider
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
  ),
);

/// Use Cases providers
final loginWithPhoneProvider = Provider<LoginWithPhone>(
  (ref) => LoginWithPhone(ref.watch(authRepositoryProvider)),
);

final verifyOtpProvider = Provider<VerifyOtp>(
  (ref) => VerifyOtp(ref.watch(authRepositoryProvider)),
);

final loginWithEmailProvider = Provider<LoginWithEmail>(
  (ref) => LoginWithEmail(ref.watch(authRepositoryProvider)),
);

final loginWithGoogleProvider = Provider<LoginWithGoogle>(
  (ref) => LoginWithGoogle(ref.watch(authRepositoryProvider)),
);

final loginWithAppleProvider = Provider<LoginWithApple>(
  (ref) => LoginWithApple(ref.watch(authRepositoryProvider)),
);

final registerUserProvider = Provider<RegisterUser>(
  (ref) => RegisterUser(ref.watch(authRepositoryProvider)),
);

final logoutProvider = Provider<Logout>(
  (ref) => Logout(ref.watch(authRepositoryProvider)),
);

final getCurrentUserProvider = Provider<GetCurrentUser>(
  (ref) => GetCurrentUser(ref.watch(authRepositoryProvider)),
);

/// Auth Notifier provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    loginWithPhone: ref.watch(loginWithPhoneProvider),
    verifyOtp: ref.watch(verifyOtpProvider),
    loginWithEmail: ref.watch(loginWithEmailProvider),
    loginWithGoogle: ref.watch(loginWithGoogleProvider),
    loginWithApple: ref.watch(loginWithAppleProvider),
    registerUser: ref.watch(registerUserProvider),
    logout: ref.watch(logoutProvider),
    getCurrentUser: ref.watch(getCurrentUserProvider),
    authRepository: ref.watch(authRepositoryProvider),
  ),
);
