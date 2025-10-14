# Chatz - WhatsApp Clone with Microtransaction Calls

A production-ready Flutter mobile application that clones WhatsApp functionality with an innovative microtransaction-based calling system.

## Features

### Core Features
- **Authentication System**
  - Phone number verification
  - User registration and login
  - Profile management

- **Real-time Chat**
  - One-to-one messaging
  - Group chats
  - Real-time message delivery
  - Read receipts
  - Online/offline status
  - Typing indicators
  - End-to-end encryption

- **Voice/Video Calls with Microtransactions**
  - Voice calling
  - Video calling
  - Pay-per-call system (users pay per minute)
  - In-app wallet and credits system
  - Transaction history
  - Call duration tracking tied to balance

- **Additional Features**
  - Media sharing (images, videos, documents)
  - Voice messages
  - Status/Stories feature
  - Contact synchronization
  - Push notifications

## Tech Stack

### Frontend
- **Flutter 3.x+** - Cross-platform framework
- **Dart 3.0+** - Programming language
- **Riverpod** - State management
- **GoRouter** - Navigation

### Backend & Services
- **Firebase Authentication** - User authentication
- **Cloud Firestore** - Real-time database
- **Firebase Storage** - Media storage
- **Firebase Cloud Messaging** - Push notifications
- **Agora/WebRTC** - Voice and video calls
- **Stripe** - Payment processing

### Architecture
- **Clean Architecture** - Domain, Data, Presentation layers
- **Repository Pattern** - Data access abstraction
- **Dependency Injection** - GetIt for service locator

## Project Structure

```
lib/
├── main.dart                       # Application entry point
├── core/                           # Core application files
│   ├── constants/                  # Constants and configuration
│   │   ├── app_constants.dart      # App-wide constants
│   │   └── api_constants.dart      # API endpoints and keys
│   ├── themes/                     # Theme configuration
│   │   ├── app_theme.dart          # Light and dark themes
│   │   ├── app_colors.dart         # Color palette
│   │   └── app_text_styles.dart    # Typography
│   ├── utils/                      # Utility functions
│   │   ├── validators.dart         # Form validators
│   │   └── extensions.dart         # Extension methods
│   ├── errors/                     # Error handling
│   │   ├── failures.dart           # Failure classes
│   │   └── exceptions.dart         # Exception classes
│   ├── di/                         # Dependency injection
│   │   └── injection.dart          # Service locator setup
│   └── router/                     # Navigation
│       └── app_router.dart         # GoRouter configuration
├── features/                       # Feature modules
│   ├── auth/                       # Authentication feature
│   │   ├── data/                   # Data layer
│   │   │   ├── models/             # Data models
│   │   │   ├── repositories/       # Repository implementations
│   │   │   └── datasources/        # Remote and local data sources
│   │   ├── domain/                 # Domain layer
│   │   │   ├── entities/           # Business entities
│   │   │   ├── repositories/       # Repository interfaces
│   │   │   └── usecases/           # Business logic
│   │   └── presentation/           # Presentation layer
│   │       ├── bloc/               # BLoC/State management
│   │       ├── pages/              # Screens
│   │       └── widgets/            # UI components
│   ├── chat/                       # Chat feature
│   ├── calls/                      # Calls feature
│   ├── payments/                   # Payments and wallet
│   ├── contacts/                   # Contacts management
│   └── status/                     # Status/Stories feature
├── shared/                         # Shared across features
│   ├── widgets/                    # Reusable widgets
│   └── services/                   # Shared services
└── test/                           # Tests
    ├── unit/                       # Unit tests
    ├── widget/                     # Widget tests
    └── integration/                # Integration tests
```

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / Xcode
- Firebase account
- Stripe account (for payments)
- Agora account (for calls)

### Installation

1. **Clone the repository**
   ```bash
   cd /Users/manu/Documents/LUXOR/chatz
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   a. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)

   b. Add Android app:
      - Download `google-services.json`
      - Place it in `android/app/`

   c. Add iOS app:
      - Download `GoogleService-Info.plist`
      - Place it in `ios/Runner/`

   d. Enable Firebase services:
      - Authentication (Phone, Email/Password, Google)
      - Cloud Firestore
      - Firebase Storage
      - Cloud Messaging (FCM)
      - Firebase Analytics

4. **Configure Stripe**

   a. Get your Stripe API keys from [Stripe Dashboard](https://dashboard.stripe.com/)

   b. Update `lib/core/constants/api_constants.dart`:
   ```dart
   static const String stripePublishableKey = 'pk_test_YOUR_KEY';
   ```

5. **Configure Agora**

   a. Create an Agora project at [Agora Console](https://console.agora.io/)

   b. Get your App ID

   c. Update `lib/core/constants/api_constants.dart`:
   ```dart
   static const String agoraAppId = 'YOUR_AGORA_APP_ID';
   ```

6. **Run code generation** (when needed)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

7. **Run the app**
   ```bash
   # For Android
   flutter run

   # For iOS
   flutter run
   ```

## Firebase Setup Details

### Firestore Collections Structure

```
users/
  - {userId}/
    - id: string
    - phoneNumber: string
    - displayName: string
    - email: string (optional)
    - photoUrl: string (optional)
    - about: string (optional)
    - isOnline: boolean
    - lastSeen: timestamp
    - walletBalance: number
    - createdAt: timestamp
    - updatedAt: timestamp

chats/
  - {chatId}/
    - id: string
    - participants: array<string>
    - type: string (individual/group)
    - lastMessage: string
    - lastMessageTime: timestamp
    - unreadCount: map<userId, number>
    - createdAt: timestamp

messages/
  - {chatId}/
    - messages/
      - {messageId}/
        - id: string
        - senderId: string
        - content: string
        - type: string (text/image/video/audio/document)
        - mediaUrl: string (optional)
        - timestamp: timestamp
        - isRead: boolean
        - isDelivered: boolean

calls/
  - {callId}/
    - id: string
    - callerId: string
    - receiverId: string
    - type: string (voice/video)
    - status: string (initiated/ongoing/completed/missed)
    - duration: number (seconds)
    - cost: number
    - startTime: timestamp
    - endTime: timestamp (optional)

transactions/
  - {userId}/
    - transactions/
      - {transactionId}/
        - id: string
        - userId: string
        - type: string (recharge/call/refund)
        - amount: number
        - description: string
        - timestamp: timestamp

status/
  - {statusId}/
    - id: string
    - userId: string
    - mediaUrl: string
    - type: string (image/video/text)
    - caption: string (optional)
    - viewers: array<string>
    - timestamp: timestamp
    - expiresAt: timestamp
```

### Firestore Security Rules (Example)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read and update their own data
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }

    // Chat participants can read and write messages
    match /chats/{chatId} {
      allow read, write: if request.auth != null &&
        request.auth.uid in resource.data.participants;
    }

    match /messages/{chatId}/messages/{messageId} {
      allow read, write: if request.auth != null;
    }

    // Transactions are user-specific
    match /transactions/{userId}/transactions/{transactionId} {
      allow read: if request.auth.uid == userId;
      allow write: if false; // Only server can write
    }
  }
}
```

### Firebase Storage Rules (Example)

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_images/{userId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }

    match /chat_media/{chatId}/{fileName} {
      allow read, write: if request.auth != null;
    }

    match /status_media/{userId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
  }
}
```

## Payment Flow

The microtransaction calling system works as follows:

1. **Wallet Recharge**: Users recharge their wallet using Stripe
2. **Call Initiation**: Before a call starts, the system checks if the user has sufficient balance
3. **During Call**: Every 10 seconds, the system deducts credits based on call duration
4. **Call End**: Final cost calculation and transaction recorded
5. **Low Balance**: User is notified when balance is low during a call

### Cost Structure
- Voice Call: $0.10 per minute
- Video Call: $0.10 per minute (can be adjusted)
- Minimum balance required: $0.50

## Development Guidelines

### Code Style
- Follow Flutter/Dart style guide
- Use `flutter analyze` to check for issues
- Use `flutter format` to format code
- All code must pass lint checks (very_good_analysis)

### State Management
- Use Riverpod for state management
- Keep business logic in the domain layer
- UI should only react to state changes

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/auth_test.dart

# Run tests with coverage
flutter test --coverage
```

### Building for Production

#### Android
```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

#### iOS
```bash
# Build for iOS
flutter build ios --release
```

## Troubleshooting

### Common Issues

1. **Firebase not initialized**
   - Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are correctly placed
   - Run `flutter clean` and rebuild

2. **Build errors after adding dependencies**
   ```bash
   flutter clean
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. **iOS CocoaPods issues**
   ```bash
   cd ios
   pod deintegrate
   pod install
   cd ..
   flutter run
   ```

## Roadmap

- [x] Project structure and core infrastructure
- [ ] Complete authentication implementation
- [ ] Chat feature with encryption
- [ ] Voice/Video calls with Agora
- [ ] Payment integration with Stripe
- [ ] Wallet and transaction management
- [ ] Contacts synchronization
- [ ] Status/Stories feature
- [ ] Push notifications
- [ ] Unit and integration tests
- [ ] App Store/Play Store deployment

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License.

## Support

For support, email support@chatz.com or join our Slack channel.

## Acknowledgements

- [Flutter](https://flutter.dev/)
- [Firebase](https://firebase.google.com/)
- [Agora](https://www.agora.io/)
- [Stripe](https://stripe.com/)
- [Riverpod](https://riverpod.dev/)

---

Built with Flutter
