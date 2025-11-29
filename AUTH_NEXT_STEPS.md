# Authentication Feature - Next Steps

## Immediate Actions Required

### 1. Run Code Generation (CRITICAL)
```bash
cd /Users/manu/Documents/LUXOR/chatz
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate:
- `user_model.freezed.dart`
- `user_model.g.dart`
- `auth_state.freezed.dart`

### 2. Update App Router
Add these routes to `/lib/core/router/app_router.dart`:

```dart
import 'package:chatz/features/auth/presentation/pages/login_page.dart';
import 'package:chatz/features/auth/presentation/pages/phone_verification_page.dart';
import 'package:chatz/features/auth/presentation/pages/otp_verification_page.dart';
import 'package:chatz/features/auth/presentation/pages/register_page.dart';
import 'package:chatz/features/auth/presentation/pages/profile_setup_page.dart';

// Add routes:
GoRoute(
  path: '/login',
  builder: (context, state) => const LoginPage(),
),
GoRoute(
  path: '/phone-verification',
  builder: (context, state) => const PhoneVerificationPage(),
),
GoRoute(
  path: '/otp-verification',
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>;
    return OtpVerificationPage(
      verificationId: extra['verificationId'] as String,
      phoneNumber: extra['phoneNumber'] as String,
    );
  },
),
GoRoute(
  path: '/register',
  builder: (context, state) => const RegisterPage(),
),
GoRoute(
  path: '/profile-setup',
  builder: (context, state) => const ProfileSetupPage(),
),
```

### 3. Add Auth Guard
Add this redirect logic to protect routes:

```dart
redirect: (context, state) {
  final container = ProviderContainer();
  final authState = container.read(authNotifierProvider);
  
  final isAuthenticated = authState.maybeWhen(
    authenticated: (_) => true,
    orElse: () => false,
  );
  
  final isOnAuthPage = [
    '/login',
    '/phone-verification',
    '/otp-verification',
    '/register',
    '/profile-setup',
  ].contains(state.location);
  
  if (!isAuthenticated && !isOnAuthPage) {
    return '/login';
  }
  
  if (isAuthenticated && isOnAuthPage) {
    return '/home';
  }
  
  return null;
},
```

### 4. Update main.dart
Wrap your app with ProviderScope:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDependencies();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

### 5. Add Google Sign-In Assets
Create `assets/icons/google.png` or update SocialLoginButtons to use a different icon.

### 6. Firebase Console Setup

#### Enable Authentication Methods:
1. Go to Firebase Console → Authentication → Sign-in method
2. Enable:
   - Email/Password
   - Phone
   - Google
   - Apple (iOS only)

#### Configure OAuth Providers:

**Google Sign-In:**
- Add your app's SHA-1 fingerprint (Android)
- Configure OAuth consent screen
- Add authorized domains

**Apple Sign-In (iOS):**
- Add your Apple Team ID
- Add your App ID
- Configure Sign in with Apple capability in Xcode

### 7. Platform-Specific Configuration

#### iOS (ios/Runner/Info.plist):
```xml
<!-- Google Sign-In URL Scheme -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>

<!-- Apple Sign-In capability -->
Add in Xcode: Signing & Capabilities → + Capability → Sign in with Apple
```

#### Android (android/build.gradle):
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}
```

#### Android (android/app/build.gradle):
```gradle
apply plugin: 'com.google.gms.google-services'
```

### 8. Test the Implementation

1. **Email/Password Flow:**
   - Register new user
   - Sign in with credentials
   - Password reset

2. **Phone Authentication:**
   - Send OTP
   - Verify OTP
   - Complete profile

3. **Social Sign-In:**
   - Google Sign-In
   - Apple Sign-In (iOS)
   - Profile completion if needed

4. **Navigation:**
   - Login → Home
   - Register → Home
   - Protected routes redirect to login
   - Authenticated users can't access auth pages

### 9. Firestore Security Rules
Add these rules to Firebase Console → Firestore → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own document
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 10. Testing Checklist

- [ ] Code generation runs successfully
- [ ] App builds without errors
- [ ] Email login works
- [ ] Email registration works
- [ ] Phone login sends OTP
- [ ] OTP verification works
- [ ] Google Sign-In works
- [ ] Apple Sign-In works (iOS)
- [ ] Profile setup works
- [ ] Navigation flows correctly
- [ ] Auth guard protects routes
- [ ] Sign out works
- [ ] Error messages display
- [ ] Loading states show
- [ ] Form validation works

## Common Issues and Solutions

### Issue: Build runner fails
**Solution:** Delete generated files and try again:
```bash
find . -name "*.g.dart" -delete
find . -name "*.freezed.dart" -delete
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: Google Sign-In returns null
**Solution:** 
- Check SHA-1 fingerprint in Firebase
- Ensure google-services.json is up to date
- Verify OAuth client ID is correct

### Issue: Phone auth doesn't work
**Solution:**
- Enable Phone authentication in Firebase Console
- Add test phone numbers in Firebase Console for development
- Check Firebase quota limits

### Issue: Apple Sign-In crashes
**Solution:**
- Verify Sign in with Apple capability is enabled in Xcode
- Check Bundle ID matches Apple Developer Console
- Ensure running on iOS 13+ or macOS 10.15+

## File Locations Quick Reference

```
Domain Layer:
- Entity: /lib/features/auth/domain/entities/user_entity.dart
- Repository: /lib/features/auth/domain/repositories/auth_repository.dart
- Use Cases: /lib/features/auth/domain/usecases/*.dart

Data Layer:
- Model: /lib/features/auth/data/models/user_model.dart
- Data Source: /lib/features/auth/data/datasources/auth_remote_data_source.dart
- Repository Impl: /lib/features/auth/data/repositories/auth_repository_impl.dart

Presentation Layer:
- State: /lib/features/auth/presentation/providers/auth_state.dart
- Notifier: /lib/features/auth/presentation/providers/auth_notifier.dart
- Providers: /lib/features/auth/presentation/providers/auth_providers.dart
- Pages: /lib/features/auth/presentation/pages/*.dart
- Widgets: /lib/features/auth/presentation/widgets/*.dart
```

## Documentation

- Full implementation details: `AUTHENTICATION_IMPLEMENTATION_SUMMARY.md`
- This guide: `AUTH_NEXT_STEPS.md`
