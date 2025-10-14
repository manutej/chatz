# Firebase Setup Guide for Chatz

This guide walks you through setting up Firebase for the Chatz application, including Authentication, Firestore, and Storage.

## Prerequisites

- Google account
- Flutter SDK installed
- Firebase CLI installed (optional but recommended)

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or "Create a project"
3. Enter project name: `chatz-app` (or your preferred name)
4. Enable Google Analytics (recommended)
5. Select or create an Analytics account
6. Click "Create project"

## Step 2: Register Your App

### For Web (Current Priority)

1. In Firebase Console, click the Web icon (`</>`)
2. Enter app nickname: `Chatz Web`
3. ✅ Check "Also set up Firebase Hosting"
4. Click "Register app"
5. **Copy the Firebase configuration** - you'll need this for `firebase_options.dart`

The config looks like:
```javascript
const firebaseConfig = {
  apiKey: "AIza...",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abc123",
  measurementId: "G-ABC123"
};
```

### For iOS (Future)

1. Click the iOS icon
2. Enter iOS bundle ID: `com.yourcompany.chatz`
3. Download `GoogleService-Info.plist`
4. Add to `ios/Runner/` directory

### For Android (Future)

1. Click the Android icon
2. Enter Android package name: `com.yourcompany.chatz`
3. Download `google-services.json`
4. Add to `android/app/` directory

## Step 3: Enable Authentication

1. In Firebase Console, go to **Authentication**
2. Click "Get started"
3. Go to **Sign-in method** tab
4. Enable the following providers:

### Phone Authentication
1. Click "Phone"
2. Toggle "Enable"
3. Click "Save"
4. **Add test phone numbers** (for development):
   - Click "Phone numbers for testing"
   - Add: `+1 650 555 1234` with code `123456`
   - This allows testing without SMS costs

### Google Sign-In (Optional)
1. Click "Google"
2. Toggle "Enable"
3. Enter support email
4. Click "Save"

## Step 4: Set Up Firestore Database

1. Go to **Firestore Database**
2. Click "Create database"
3. Select **Start in test mode** (for development)
4. Choose a Cloud Firestore location (e.g., `us-central`)
5. Click "Enable"

### Security Rules (Update Later)

For now, test mode allows all reads/writes. Before production, update rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Chats can be read/written by participants
    match /chats/{chatId} {
      allow read, write: if request.auth != null
        && request.auth.uid in resource.data.participants;
    }

    // Messages within chats
    match /chats/{chatId}/messages/{messageId} {
      allow read: if request.auth != null
        && request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
      allow write: if request.auth != null
        && request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
    }
  }
}
```

## Step 5: Set Up Cloud Storage

1. Go to **Storage**
2. Click "Get started"
3. Select **Start in test mode**
4. Choose a location (same as Firestore)
5. Click "Done"

### Storage Rules (Update Later)

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // User profile images
    match /users/{userId}/profile/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Chat media
    match /chats/{chatId}/media/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## Step 6: Install Firebase CLI (Optional)

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in project
cd /Users/manu/Documents/LUXOR/chatz
firebase init
```

Select:
- ✅ Firestore
- ✅ Storage
- ✅ Hosting

## Step 7: Install FlutterFire CLI

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Add to PATH (if not already)
export PATH="$PATH":"$HOME/.pub-cache/bin"

# Configure Firebase for Flutter
flutterfire configure
```

This will:
1. Connect to your Firebase project
2. Generate `lib/firebase_options.dart` automatically
3. Configure for all platforms (iOS, Android, Web)

## Step 8: Update firebase_options.dart

After running `flutterfire configure`, you'll have a file like:

```dart
// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_AUTH_DOMAIN',
    storageBucket: 'YOUR_STORAGE_BUCKET',
    measurementId: 'YOUR_MEASUREMENT_ID',
  );

  // Add iOS, Android config here later
}
```

## Step 9: Enable Firebase in App

Uncomment the Firebase initialization in `lib/main.dart`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDependencies();
  runApp(const MyApp());
}
```

## Step 10: Enable Firebase Services in DI

Uncomment Firebase instances in `lib/core/di/injection.dart`:

```dart
Future<void> initializeDependencies() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // Firebase instances
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
}
```

## Step 11: Test Firebase Connection

Run the app and check for Firebase initialization:

```bash
flutter run -d chrome
```

Check browser console for:
```
Firebase initialized successfully
```

If you see errors, check:
1. ✅ `firebase_options.dart` has correct config
2. ✅ Firebase project is active in console
3. ✅ Authentication is enabled
4. ✅ Firestore and Storage are set up

## Step 12: Implement Phone Authentication

Update `lib/features/auth/presentation/pages/login_page.dart`:

```dart
Future<void> _handleLogin() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() => _isLoading = true);

  try {
    final auth = FirebaseAuth.instance;

    // Send verification code
    await auth.verifyPhoneNumber(
      phoneNumber: _phoneController.text,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-verification (Android only)
        await auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        throw e.message ?? 'Verification failed';
      },
      codeSent: (String verificationId, int? resendToken) {
        // Navigate to verification screen
        context.push('/verify-phone', extra: {
          'verificationId': verificationId,
          'phoneNumber': _phoneController.text,
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Auto-retrieval timeout
      },
    );
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

## Troubleshooting

### Error: "Firebase not initialized"
**Solution**: Ensure `Firebase.initializeApp()` is called in `main()`

### Error: "Missing Firebase configuration"
**Solution**: Run `flutterfire configure` to generate `firebase_options.dart`

### Error: "Phone auth not enabled"
**Solution**: Enable Phone authentication in Firebase Console

### Error: "Permission denied" in Firestore
**Solution**: Update Firestore security rules in Firebase Console

### Error: "Invalid API key"
**Solution**: Check `firebase_options.dart` has correct API key from Firebase Console

## Production Checklist

Before deploying to production:

- [ ] Update Firestore security rules (remove test mode)
- [ ] Update Storage security rules (remove test mode)
- [ ] Set up proper authentication flow
- [ ] Add error handling and retry logic
- [ ] Set up Firebase Analytics
- [ ] Configure app check for security
- [ ] Set up Cloud Functions for backend logic
- [ ] Add rate limiting for API calls
- [ ] Set up monitoring and alerts
- [ ] Test on all target platforms

## Cost Considerations

Firebase free tier (Spark plan) includes:
- **Authentication**: Unlimited
- **Firestore**: 1GB storage, 10GB/month transfer
- **Storage**: 5GB storage, 1GB/day transfer
- **Hosting**: 10GB/month transfer

For production with expected scale, consider Blaze plan (pay-as-you-go).

## Next Steps

1. Complete phone verification screen
2. Implement user profile creation
3. Set up Firestore data structure
4. Implement real-time chat features
5. Add file upload to Storage
6. Integrate Agora for calling
7. Add Stripe for payments

## Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)

---

**Generated for Chatz App - WhatsApp Clone with Microtransactions**
