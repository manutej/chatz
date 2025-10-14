import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Service locator for dependency injection
final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> initializeDependencies() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // Firebase instances (commented out until Firebase is configured for web)
  // TODO: Uncomment after configuring Firebase
  // sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  // sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  // sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);

  // Core services (to be implemented)
  // sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  // sl.registerLazySingleton<EncryptionService>(() => EncryptionServiceImpl());

  // Data sources (to be implemented)
  // Auth
  // sl.registerLazySingleton<AuthRemoteDataSource>(
  //   () => AuthRemoteDataSourceImpl(sl(), sl()),
  // );
  // sl.registerLazySingleton<AuthLocalDataSource>(
  //   () => AuthLocalDataSourceImpl(sl()),
  // );

  // Repositories (to be implemented)
  // Auth
  // sl.registerLazySingleton<AuthRepository>(
  //   () => AuthRepositoryImpl(
  //     remoteDataSource: sl(),
  //     localDataSource: sl(),
  //     networkInfo: sl(),
  //   ),
  // );

  // Use cases (to be implemented)
  // Auth
  // sl.registerLazySingleton(() => LoginUseCase(sl()));
  // sl.registerLazySingleton(() => RegisterUseCase(sl()));
  // sl.registerLazySingleton(() => LogoutUseCase(sl()));
  // sl.registerLazySingleton(() => VerifyPhoneUseCase(sl()));

  // BLoC / Providers (to be implemented)
  // Auth
  // sl.registerFactory(() => AuthBloc(
  //   loginUseCase: sl(),
  //   registerUseCase: sl(),
  //   logoutUseCase: sl(),
  //   verifyPhoneUseCase: sl(),
  // ));
}

/// Reset all dependencies (useful for testing)
Future<void> resetDependencies() async {
  await sl.reset();
}
