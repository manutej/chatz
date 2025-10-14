# Chatz - Quick Start Guide

Get your Chatz development environment up and running in minutes!

## Prerequisites Checklist

- [ ] macOS, Linux, or Windows
- [ ] Git installed
- [ ] 8GB+ RAM
- [ ] 10GB+ free disk space

## Step 1: Install Flutter (5 minutes)

### macOS

```bash
# Download Flutter
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable

# Add to PATH
export PATH="$PATH:`pwd`/flutter/bin"
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc

# Verify installation
flutter doctor
```

### Linux

```bash
# Download Flutter
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable

# Add to PATH
export PATH="$PATH:`pwd`/flutter/bin"
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.bashrc

# Verify installation
flutter doctor
```

### Windows

1. Download Flutter SDK: https://flutter.dev/docs/get-started/install/windows
2. Extract to `C:\src\flutter`
3. Add `C:\src\flutter\bin` to PATH
4. Run `flutter doctor` in Command Prompt

## Step 2: Install Dependencies (2 minutes)

```bash
cd /Users/manu/Documents/LUXOR/chatz
flutter pub get
```

Expected output:
```
Running "flutter pub get" in chatz...
Resolving dependencies... (2.5s)
Got dependencies!
```

## Step 3: Verify Setup (1 minute)

```bash
# Check for issues
flutter doctor -v

# Analyze code
flutter analyze

# Format code
flutter format .
```

Expected output:
```
Analyzing chatz...
No issues found!
```

## Step 4: Run Tests (1 minute)

### Option A: Run All Tests

```bash
flutter test
```

Expected output:
```
00:02 +30: All tests passed!
```

### Option B: Use Test Runner Script

```bash
./run_tests.sh
```

This will:
- Install dependencies
- Run static analysis
- Check code formatting
- Run all tests
- Generate coverage report
- Open HTML coverage report in browser

## Step 5: Configure Services (15 minutes)

### A. Firebase Setup

1. Create Firebase project: https://console.firebase.google.com/
2. Add Android app:
   - Download `google-services.json`
   - Place in `android/app/`
3. Add iOS app:
   - Download `GoogleService-Info.plist`
   - Place in `ios/Runner/`
4. Enable services:
   - Authentication (Phone, Email/Password, Google)
   - Cloud Firestore
   - Firebase Storage
   - Cloud Messaging

### B. Stripe Setup

1. Create Stripe account: https://dashboard.stripe.com/register
2. Get publishable key from Dashboard
3. Update `lib/core/constants/api_constants.dart`:
   ```dart
   static const String stripePublishableKey = 'pk_test_YOUR_KEY';
   ```

### C. Agora Setup

1. Create Agora account: https://console.agora.io/
2. Create project and get App ID
3. Update `lib/core/constants/api_constants.dart`:
   ```dart
   static const String agoraAppId = 'YOUR_APP_ID';
   ```

## Step 6: Run the App (2 minutes)

### Start iOS Simulator (macOS only)

```bash
open -a Simulator
```

### Start Android Emulator

```bash
flutter emulators
flutter emulators --launch <emulator-id>
```

### Run App

```bash
flutter run
```

Expected output:
```
Launching lib/main.dart on iPhone 15 Pro in debug mode...
Running Gradle task 'assembleDebug'...
✓ Built build/app/outputs/flutter-apk/app-debug.apk.
Installing build/app/outputs/flutter-apk/app.apk...
Syncing files to device iPhone 15 Pro...

🔥  To hot reload changes while running, press "r" or "R".
```

## Common Commands

```bash
# Development
flutter run                  # Run app
flutter run --release        # Run in release mode
flutter run -d chrome        # Run on web

# Testing
flutter test                 # Run all tests
flutter test --coverage      # With coverage
./run_tests.sh              # Full test suite

# Code Quality
flutter analyze             # Static analysis
flutter format .            # Format code

# Build
flutter build apk           # Android APK
flutter build appbundle     # Android Bundle
flutter build ios           # iOS build

# Debugging
flutter logs                # View logs
flutter clean               # Clean build
flutter doctor             # Check setup
```

## Troubleshooting

### Flutter not found

```bash
flutter: command not found
```

**Solution**: Add Flutter to PATH or reinstall

### Dependencies error

```bash
Error: Cannot run with sound null safety
```

**Solution**: Run `flutter pub get`

### Build errors

```bash
FAILURE: Build failed with an exception
```

**Solution**: Run `flutter clean` then `flutter pub get`

### Test failures

```bash
Expected: null
Actual: 'error message'
```

**Solution**: Check test expectations match implementation

## Next Steps

1. ✅ Installed Flutter
2. ✅ Got dependencies
3. ✅ Ran tests
4. ⏳ Configure Firebase
5. ⏳ Configure Stripe
6. ⏳ Configure Agora
7. ⏳ Run the app
8. ⏳ Start implementing features

## Resources

- **Documentation**: See `README.md`, `ARCHITECTURE.md`, `SETUP_GUIDE.md`
- **Testing**: See `TESTING.md`, `docs/TDD_GUIDE.md`
- **Reference**: See `docs/` folder for Riverpod, Agora, Stripe guides
- **Progress**: Track development in `PROGRESS.md`

## Getting Help

1. Check documentation files
2. Review `TESTING.md` for test issues
3. See `TROUBLESHOOTING` section in `README.md`
4. Run `flutter doctor` for system issues
5. Check GitHub issues

## Development Workflow

```bash
# 1. Pull latest changes
git pull origin main

# 2. Create feature branch
git checkout -b feature/my-feature

# 3. Write tests first (TDD)
# Edit test/unit/features/auth/...

# 4. Implement feature
# Edit lib/features/auth/...

# 5. Run tests
flutter test

# 6. Commit changes
git add .
git commit -m "feat: implement my feature"

# 7. Push and create PR
git push origin feature/my-feature
```

## Time to First Run

- **Flutter installation**: 5 minutes
- **Dependencies**: 2 minutes
- **Verification**: 1 minute
- **Run tests**: 1 minute
- **Service config**: 15 minutes (optional)
- **Run app**: 2 minutes

**Total**: ~26 minutes to fully working development environment!

---

**Ready to start?** Run these commands:

```bash
cd /Users/manu/Documents/LUXOR/chatz
flutter pub get
flutter test
flutter run
```

Happy coding! 🚀
