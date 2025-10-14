# Testing Guide for Chatz

This document provides instructions for testing the Chatz application.

## Prerequisites

Before running tests, ensure you have:

1. **Flutter SDK** installed (version 3.0.0 or higher)
2. **Dart SDK** (comes with Flutter)
3. **Dependencies installed**

## Setup

### 1. Install Flutter

If Flutter is not installed, follow the [official installation guide](https://flutter.dev/docs/get-started/install).

Verify installation:
```bash
flutter --version
flutter doctor
```

### 2. Install Dependencies

Navigate to the project directory and run:

```bash
cd /Users/manu/Documents/LUXOR/chatz
flutter pub get
```

This will install all dependencies defined in `pubspec.yaml`.

### 3. Verify Setup

Check for any issues:

```bash
flutter doctor -v
```

Fix any reported issues before proceeding.

## Running Tests

### Run All Tests

Execute all unit, widget, and integration tests:

```bash
flutter test
```

Expected output:
```
00:02 +42: All tests passed!
```

### Run Specific Test File

Run a single test file:

```bash
# Unit test
flutter test test/unit/core/utils/validators_test.dart

# Widget test
flutter test test/widget/shared/custom_button_test.dart
```

### Run Tests by Pattern

Run tests matching a name pattern:

```bash
flutter test --name "validators"
flutter test --name "CustomButton"
```

### Run Tests with Coverage

Generate code coverage report:

```bash
flutter test --coverage
```

View coverage report:

```bash
# Install lcov if not already installed (macOS)
brew install lcov

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html
```

### Watch Mode

Automatically re-run tests on file changes:

```bash
flutter test --watch
```

### Verbose Output

Show detailed test execution information:

```bash
flutter test --verbose
```

## Code Analysis

### Run Static Analysis

Check for code issues:

```bash
flutter analyze
```

Expected output:
```
Analyzing chatz...
No issues found!
```

### Format Code

Auto-format all Dart files:

```bash
flutter format .
```

Format and check:

```bash
flutter format --set-exit-if-changed .
```

## Testing Examples

### Example 1: Run Validator Tests

```bash
cd /Users/manu/Documents/LUXOR/chatz
flutter test test/unit/core/utils/validators_test.dart
```

Expected output:
```
00:01 +20: All tests passed!
```

### Example 2: Run Widget Tests

```bash
flutter test test/widget/shared/custom_button_test.dart
```

Expected output:
```
00:02 +10: All tests passed!
```

### Example 3: Run Tests with Coverage

```bash
# Generate coverage
flutter test --coverage

# View coverage percentage
lcov --summary coverage/lcov.info
```

Expected output:
```
Summary coverage rate:
  lines......: 85.2% (1234 of 1448 lines)
  functions..: 90.1% (234 of 260 functions)
```

## Integration Tests

### Run Integration Tests

```bash
flutter test integration_test/
```

Or run on a specific device:

```bash
# iOS Simulator
flutter test integration_test/ -d iPhone

# Android Emulator
flutter test integration_test/ -d Android

# Real device
flutter test integration_test/ -d <device-id>
```

List available devices:

```bash
flutter devices
```

## Continuous Integration

### GitHub Actions

Tests run automatically on push/PR. See workflow: `.github/workflows/test.yml`

Manually trigger tests:

```bash
gh workflow run test.yml
```

### Local CI Simulation

Simulate CI environment locally:

```bash
#!/bin/bash
# run_tests.sh

echo "🔍 Running static analysis..."
flutter analyze || exit 1

echo "🧪 Running tests with coverage..."
flutter test --coverage || exit 1

echo "📊 Generating coverage report..."
genhtml coverage/lcov.info -o coverage/html

echo "✅ All checks passed!"
```

Make executable and run:

```bash
chmod +x run_tests.sh
./run_tests.sh
```

## Debugging Tests

### Run Single Test

Run a specific test by name:

```bash
flutter test --name "should return null for valid phone number"
```

### Print Debug Information

Add print statements in tests:

```dart
test('should validate phone', () {
  print('Testing phone: $phoneNumber');
  final result = Validators.validatePhoneNumber(phoneNumber);
  print('Result: $result');
  expect(result, null);
});
```

### Use Debugger

Run tests with debugger (VS Code):

1. Set breakpoint in test file
2. Press F5 or Run > Start Debugging
3. Select "Dart & Flutter" configuration

### Test with Real Devices

Run tests on connected device:

```bash
flutter test integration_test/ -d <device-id>
```

## Test Coverage Goals

Current coverage targets:

| Layer | Target | Current |
|-------|--------|---------|
| Overall | 80%+ | 0% (not started) |
| Domain | 90%+ | 0% |
| Data | 85%+ | 0% |
| Presentation | 70%+ | 0% |
| Core/Shared | 90%+ | 0% |

## Common Issues

### Issue 1: Flutter Not Found

```bash
(eval):1: command not found: flutter
```

**Solution**: Install Flutter SDK from https://flutter.dev/docs/get-started/install

### Issue 2: Dependencies Not Found

```bash
Error: Cannot run with sound null safety...
```

**Solution**: Run `flutter pub get` to install dependencies

### Issue 3: Import Errors

```bash
Error: Not found: 'package:chatz/...'
```

**Solution**: Ensure you're in the correct directory and dependencies are installed

### Issue 4: Test Failures

```bash
Expected: null
  Actual: 'Please enter a valid phone number'
```

**Solution**: Check test expectations match implementation. Update either test or code.

### Issue 5: Coverage Not Generated

```bash
genhtml: command not found
```

**Solution**: Install lcov:
```bash
# macOS
brew install lcov

# Ubuntu/Debian
sudo apt-get install lcov

# Windows
# Download from http://ltp.sourceforge.net/coverage/lcov.php
```

## Testing Workflow

### TDD Workflow (Recommended)

1. **Write failing test** (Red)
   ```bash
   flutter test test/unit/features/auth/domain/usecases/sign_in_test.dart
   ```

2. **Write minimal code** to pass test (Green)

3. **Refactor** while keeping tests green

4. **Repeat** for next feature

### Pre-Commit Workflow

Before committing code:

```bash
# Format code
flutter format .

# Analyze code
flutter analyze

# Run tests
flutter test

# Check coverage
flutter test --coverage
lcov --summary coverage/lcov.info
```

### Pre-Push Workflow

Before pushing to remote:

```bash
# Run full test suite
flutter test

# Run integration tests
flutter test integration_test/

# Verify no issues
flutter analyze
```

## Test Reports

### Generate Test Report

```bash
# Run tests with JSON output
flutter test --machine > test_results.json

# Or use test reporter package
flutter pub global activate junitreport
flutter test --machine | tojunit > test_results.xml
```

### View Coverage in Browser

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Performance Testing

### Measure Test Performance

```bash
# Time test execution
time flutter test

# Profile specific test
flutter test --profile test/unit/features/auth/domain/usecases/sign_in_test.dart
```

### Optimize Slow Tests

If tests are slow:

1. Use `setUp`/`tearDown` to share setup code
2. Mock expensive operations
3. Avoid unnecessary `pumpAndSettle`
4. Use `pumpFrames` instead of `pumpAndSettle` when possible

## Resources

- [Flutter Testing Documentation](https://flutter.dev/docs/testing)
- [Widget Testing](https://flutter.dev/docs/cookbook/testing/widget/introduction)
- [Integration Testing](https://flutter.dev/docs/testing/integration-tests)
- [Mocktail Package](https://pub.dev/packages/mocktail)
- [Test Coverage](https://flutter.dev/docs/testing/code-coverage)

## Quick Reference

```bash
# Setup
flutter pub get

# Run tests
flutter test                              # All tests
flutter test test/unit/                   # Unit tests only
flutter test test/widget/                 # Widget tests only
flutter test --coverage                   # With coverage
flutter test --name "pattern"             # By name pattern

# Analysis
flutter analyze                           # Static analysis
flutter format .                          # Format code

# Coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Watch mode
flutter test --watch

# CI simulation
flutter analyze && flutter test --coverage
```

## Next Steps

1. **Install Flutter** if not already installed
2. **Run `flutter pub get`** to install dependencies
3. **Run `flutter analyze`** to check for code issues
4. **Run `flutter test`** to execute test suite
5. **Generate coverage** with `flutter test --coverage`
6. **Review failing tests** and fix issues
7. **Implement remaining features** using TDD

## Support

If you encounter issues:

1. Check [Flutter documentation](https://flutter.dev/docs)
2. Search [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
3. Review test output for specific error messages
4. Ensure all dependencies are up to date: `flutter pub upgrade`

Happy testing! 🧪✅
