# Chatz - Quick Setup Guide

This guide will help you get the Chatz application up and running on your local machine.

## Prerequisites Checklist

Before you begin, ensure you have the following installed:

- [ ] Flutter SDK (3.0.0 or higher) - [Install Flutter](https://docs.flutter.dev/get-started/install)
- [ ] Dart SDK (3.0.0 or higher) - Comes with Flutter
- [ ] Android Studio (for Android development)
- [ ] Xcode (for iOS development, macOS only)
- [ ] VS Code or Android Studio (IDE)
- [ ] Git

## Step 1: Verify Flutter Installation

```bash
flutter doctor
```

Ensure all required items are checked. Fix any issues before proceeding.

## Step 2: Install Dependencies

Navigate to the project directory and run:

```bash
cd /Users/manu/Documents/LUXOR/chatz
flutter pub get
```

## Step 3: Firebase Configuration

### 3.1 Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Follow the wizard to create your project
4. Enable Google Analytics (optional)

### 3.2 Configure Android App

1. In Firebase Console, click "Add app" > Android icon
2. Register app:
   - Android package name: `com.chatz.app.chatz`
   - App nickname: `Chatz Android`
   - Debug signing certificate (optional for development)
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`

### 3.3 Configure iOS App

1. In Firebase Console, click "Add app" > iOS icon
2. Register app:
   - iOS bundle ID: `com.chatz.app.chatz`
   - App nickname: `Chatz iOS`
3. Download `GoogleService-Info.plist`
4. Place it in: `ios/Runner/GoogleService-Info.plist`

### 3.4 Enable Firebase Services

In Firebase Console, enable the following:

1. **Authentication**
   - Go to Authentication > Sign-in method
   - Enable: Phone, Email/Password, Google Sign-In

2. **Cloud Firestore**
   - Go to Firestore Database
   - Create database (start in test mode for development)
   - Choose a location close to your users

3. **Firebase Storage**
   - Go to Storage
   - Get Started
   - Start in test mode for development

4. **Cloud Messaging (FCM)**
   - Should be enabled by default
   - Note: You may need additional setup for iOS notifications

5. **Firebase Analytics** (optional but recommended)
   - Should be enabled by default

### 3.5 Security Rules (Important for Production)

After setting up, update your Firestore Security Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }

    match /chats/{chatId} {
      allow read, write: if request.auth != null;
    }

    match /messages/{chatId}/messages/{messageId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Step 4: Configure Stripe Payment

1. Create account at [Stripe Dashboard](https://dashboard.stripe.com/)
2. Get your publishable key from Dashboard > Developers > API keys
3. Update `lib/core/constants/api_constants.dart`:
   ```dart
   static const String stripePublishableKey = 'pk_test_YOUR_ACTUAL_KEY_HERE';
   ```

For testing, use test mode keys (they start with `pk_test_`).

## Step 5: Configure Agora for Calls

1. Create account at [Agora Console](https://console.agora.io/)
2. Create a new project
3. Get your App ID
4. Update `lib/core/constants/api_constants.dart`:
   ```dart
   static const String agoraAppId = 'YOUR_ACTUAL_APP_ID_HERE';
   ```

## Step 6: Android-Specific Setup

1. Open `android/app/build.gradle`
2. Ensure `minSdkVersion` is at least 21:
   ```gradle
   minSdkVersion 21
   ```

3. Add permissions to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.CAMERA"/>
   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
   <uses-permission android:name="android.permission.READ_CONTACTS"/>
   ```

## Step 7: iOS-Specific Setup

1. Open `ios/Runner/Info.plist`
2. Add required permissions:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>We need access to your camera for video calls</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>We need access to your microphone for calls</string>
   <key>NSPhotoLibraryUsageDescription</key>
   <string>We need access to your photos to share images</string>
   <key>NSContactsUsageDescription</key>
   <string>We need access to your contacts to find friends</string>
   ```

3. Install CocoaPods dependencies:
   ```bash
   cd ios
   pod install
   cd ..
   ```

## Step 8: Run the Application

### For Android:

```bash
flutter run
```

Or select an Android device/emulator in your IDE and run.

### For iOS:

```bash
flutter run
```

Or open `ios/Runner.xcworkspace` in Xcode and run from there.

## Step 9: Run Code Generation (When Needed)

When you add new models or make changes that require code generation:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Troubleshooting

### Issue: Firebase not initialized

**Solution:**
- Verify `google-services.json` is in `android/app/`
- Verify `GoogleService-Info.plist` is in `ios/Runner/`
- Run `flutter clean` then rebuild

### Issue: Build errors

**Solution:**
```bash
flutter clean
flutter pub get
flutter run
```

### Issue: iOS CocoaPods errors

**Solution:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter run
```

### Issue: Android Gradle errors

**Solution:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter run
```

### Issue: Permission errors (Android)

**Solution:**
- Check that permissions are added to `AndroidManifest.xml`
- For Android 13+, you may need to request permissions at runtime

## Development Workflow

1. **Make changes** to your code
2. **Hot reload** by pressing `r` in the terminal or using IDE shortcuts
3. **Hot restart** by pressing `R` for full restart
4. **Test** your changes thoroughly
5. **Commit** your changes to Git

## Next Steps

After successful setup:

1. Explore the codebase structure in `lib/`
2. Review the architecture in `README.md`
3. Start implementing features:
   - Complete authentication flows
   - Implement chat functionality
   - Add calling features
   - Integrate payment system

## Useful Commands

```bash
# Run app
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format lib/

# Build for Android
flutter build apk --release
flutter build appbundle --release

# Build for iOS
flutter build ios --release

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Clean project
flutter clean

# Update dependencies
flutter pub upgrade
```

## Getting Help

- Check the main [README.md](./README.md) for detailed documentation
- Review Flutter docs: https://docs.flutter.dev/
- Firebase docs: https://firebase.google.com/docs
- Stripe docs: https://stripe.com/docs
- Agora docs: https://docs.agora.io/

## Project Status

Current implementation includes:
- ✅ Project structure and folder organization
- ✅ Core infrastructure (themes, constants, utilities)
- ✅ Navigation setup with GoRouter
- ✅ Dependency injection setup
- ✅ Error handling framework
- ✅ Shared widgets (buttons, text fields, loading indicators)
- ✅ Sample authentication and home pages
- ⏳ Complete feature implementations (to be developed)

The project is set up as a skeleton with all the foundational code in place. You can now start implementing the complete features based on your requirements.

---

Happy Coding! 🚀
