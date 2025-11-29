import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/themes/app_theme.dart';
import 'shared/services/notification_service.dart';

/// Main entry point of the application
Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  // NOTE: Before running, configure Firebase:
  // 1. Create Firebase project at https://console.firebase.google.com/
  // 2. Run: dart pub global activate flutterfire_cli
  // 3. Run: flutterfire configure
  // OR manually update lib/firebase_options.dart with your config
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('⚠️  Firebase initialization error: $e');
    debugPrint('💡 To configure Firebase, see docs/FIREBASE_SETUP.md');
    // Continue without Firebase for UI testing
  }

  // Initialize dependency injection
  await initializeDependencies();

  // Initialize notification service after DI is ready
  try {
    final notificationService = sl<NotificationService>();
    await notificationService.initialize();
    debugPrint('✅ Notification service initialized');
  } catch (e) {
    debugPrint('⚠️  Notification service initialization error: $e');
    // Continue without notifications
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Run the app
  runApp(
    const ProviderScope(
      child: ChatzApp(),
    ),
  );
}

/// Main application widget
class ChatzApp extends ConsumerWidget {
  const ChatzApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // You can watch theme mode provider here
    // final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Chatz',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Can be controlled by provider

      // Router configuration
      routerConfig: AppRouter.router,

      // Builder for custom configurations
      builder: (context, child) {
        return MediaQuery(
          // Prevent text scaling beyond reasonable limits
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(
                  0.8,
                  1.3,
                ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
