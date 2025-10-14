# Chatz

A production-ready Flutter mobile chat application.

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Git

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd chatz
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Project Structure

```
chatz/
├── lib/
│   ├── main.dart
│   ├── core/
│   ├── features/
│   ├── shared/
│   └── config/
├── test/
├── assets/
├── android/
├── ios/
└── pubspec.yaml
```

## Development

### Running Tests

```bash
flutter test
```

### Building for Production

#### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

## Contributing

1. Create a feature branch
2. Make your changes
3. Write tests
4. Submit a pull request

## License

TBD
