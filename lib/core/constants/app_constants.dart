/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Chatz';
  static const String appVersion = '1.0.0';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Pagination
  static const int messagesPerPage = 50;
  static const int contactsPerPage = 30;
  static const int statusPerPage = 20;

  // Media
  static const int maxImageSizeInMB = 5;
  static const int maxVideoSizeInMB = 50;
  static const int maxDocumentSizeInMB = 20;
  static const int imageCompressionQuality = 85;

  // Call Settings
  static const double callCreditCostPerMinute = 0.10; // $0.10 per minute
  static const double minCallCredit = 0.50; // Minimum $0.50 to start a call
  static const Duration callCheckInterval = Duration(seconds: 10);

  // Payment
  static const List<double> rechargeAmounts = [5.0, 10.0, 20.0, 50.0, 100.0];
  static const String currency = 'USD';
  static const String currencySymbol = '\$';

  // Audio Recording
  static const Duration maxVoiceMessageDuration = Duration(minutes: 5);
  static const Duration minVoiceMessageDuration = Duration(seconds: 1);

  // Status/Stories
  static const Duration statusDuration = Duration(hours: 24);
  static const Duration statusViewDuration = Duration(seconds: 5);
  static const int maxStatusPerDay = 10;

  // Cache
  static const Duration cacheValidityDuration = Duration(hours: 1);
  static const int maxCachedImages = 100;

  // Phone Number
  static const String defaultCountryCode = '+1';
  static const int phoneNumberLength = 10;

  // Typing Indicator
  static const Duration typingIndicatorTimeout = Duration(seconds: 3);

  // Online Status
  static const Duration onlineStatusTimeout = Duration(seconds: 30);

  // Group Chat
  static const int maxGroupMembers = 256;
  static const int maxGroupNameLength = 50;

  // Message
  static const int maxMessageLength = 4096;

  // Encryption
  static const String encryptionAlgorithm = 'AES';
  static const int encryptionKeyLength = 256;

  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userIdKey = 'user_id';
  static const String userPhoneKey = 'user_phone';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String fcmTokenKey = 'fcm_token';

  // Error Messages
  static const String genericErrorMessage =
      'Something went wrong. Please try again.';
  static const String networkErrorMessage =
      'No internet connection. Please check your network.';
  static const String serverErrorMessage =
      'Server error. Please try again later.';
  static const String insufficientFundsMessage =
      'Insufficient credits. Please recharge your wallet.';
}
