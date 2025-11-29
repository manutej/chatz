import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../shared/services/storage_service.dart';
import '../../shared/services/image_picker_service.dart';
import '../../shared/services/file_compression_service.dart';
import '../../shared/services/notification_service.dart';
import '../../shared/services/local_notification_service.dart';
import '../../shared/services/permission_service.dart';
import '../../shared/data/datasources/storage_remote_data_source.dart';
import '../../shared/data/repositories/storage_repository_impl.dart';
import '../../shared/domain/repositories/storage_repository.dart';
import '../../shared/domain/usecases/upload_file_usecase.dart';
import '../../shared/domain/usecases/delete_file_usecase.dart';
import '../../shared/domain/usecases/get_download_url_usecase.dart';
import '../../shared/domain/usecases/pick_media_usecase.dart';
import '../../features/chat/data/datasources/fcm_data_source.dart';

/// Service locator for dependency injection
final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> initializeDependencies() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // Firebase instances
  // These will work once Firebase is configured
  // See docs/FIREBASE_SETUP.md for configuration instructions
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  sl.registerLazySingleton<FirebaseMessaging>(() => FirebaseMessaging.instance);

  // Image Picker
  sl.registerLazySingleton<ImagePicker>(() => ImagePicker());

  // Local Notifications
  sl.registerLazySingleton<FlutterLocalNotificationsPlugin>(
    () => FlutterLocalNotificationsPlugin(),
  );

  // Device Info
  sl.registerLazySingleton<DeviceInfoPlugin>(() => DeviceInfoPlugin());

  // Core services
  // sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  // sl.registerLazySingleton<EncryptionService>(() => EncryptionServiceImpl());

  // Storage services
  sl.registerLazySingleton<StorageService>(() => StorageService(sl()));
  sl.registerLazySingleton<ImagePickerService>(() => ImagePickerService(sl()));
  sl.registerLazySingleton<FileCompressionService>(() => FileCompressionService());

  // Permission service
  sl.registerLazySingleton<PermissionService>(() => PermissionService());

  // Notification services
  sl.registerLazySingleton<LocalNotificationService>(
    () => LocalNotificationService(notifications: sl()),
  );

  sl.registerLazySingleton<NotificationService>(
    () => NotificationService(
      messaging: sl(),
      localNotificationService: sl(),
      permissionService: sl(),
      fcmDataSource: sl(),
    ),
  );

  // Data sources
  // Storage
  sl.registerLazySingleton<StorageRemoteDataSource>(
    () => StorageRemoteDataSource(sl(), sl()),
  );

  // FCM
  sl.registerLazySingleton<FCMDataSource>(
    () => FCMDataSource(
      firestore: sl(),
      auth: sl(),
      deviceInfo: sl(),
    ),
  );

  // Auth (to be implemented)
  // sl.registerLazySingleton<AuthRemoteDataSource>(
  //   () => AuthRemoteDataSourceImpl(sl(), sl()),
  // );
  // sl.registerLazySingleton<AuthLocalDataSource>(
  //   () => AuthLocalDataSourceImpl(sl()),
  // );

  // Repositories
  // Storage
  sl.registerLazySingleton<StorageRepository>(
    () => StorageRepositoryImpl(sl()),
  );

  // Auth (to be implemented)
  // sl.registerLazySingleton<AuthRepository>(
  //   () => AuthRepositoryImpl(
  //     remoteDataSource: sl(),
  //     localDataSource: sl(),
  //     networkInfo: sl(),
  //   ),
  // );

  // Use cases
  // Storage
  sl.registerLazySingleton(() => UploadFileUseCase(sl()));
  sl.registerLazySingleton(() => DeleteFileUseCase(sl()));
  sl.registerLazySingleton(() => DeleteMultipleFilesUseCase(sl()));
  sl.registerLazySingleton(() => GetDownloadUrlUseCase(sl()));
  sl.registerLazySingleton(() => PickImageFromGalleryUseCase(sl()));
  sl.registerLazySingleton(() => PickImageFromCameraUseCase(sl()));
  sl.registerLazySingleton(() => PickMultipleImagesUseCase(sl()));
  sl.registerLazySingleton(() => PickVideoFromGalleryUseCase(sl()));
  sl.registerLazySingleton(() => RecordVideoWithCameraUseCase(sl()));

  // Auth (to be implemented)
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
