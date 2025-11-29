/// Base exception class for all custom exceptions
class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;
}

/// Server exception
class ServerException extends AppException {
  const ServerException([super.message = 'Server error occurred']);
}

/// Network exception
class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection']);
}

/// Cache exception
class CacheException extends AppException {
  const CacheException([super.message = 'Cache error occurred']);
}

/// Authentication exception
class AuthException extends AppException {
  const AuthException([super.message = 'Authentication failed']);
}

/// Validation exception
class ValidationException extends AppException {
  const ValidationException([super.message = 'Validation failed']);
}

/// Permission exception
class PermissionException extends AppException {
  const PermissionException([super.message = 'Permission denied']);
}

/// Payment exception
class PaymentException extends AppException {
  const PaymentException([super.message = 'Payment failed']);
}

/// Insufficient funds exception
class InsufficientFundsException extends AppException {
  const InsufficientFundsException([
    super.message = 'Insufficient credits in wallet',
  ]);
}

/// Call exception
class CallException extends AppException {
  const CallException([super.message = 'Call failed']);
}

/// Media upload exception
class MediaUploadException extends AppException {
  const MediaUploadException([super.message = 'Media upload failed']);
}

/// Encryption exception
class EncryptionException extends AppException {
  const EncryptionException([super.message = 'Encryption failed']);
}

/// Not found exception
class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Resource not found']);
}

/// Timeout exception
class TimeoutException extends AppException {
  const TimeoutException([super.message = 'Request timeout']);
}

/// Firestore exception
class FirestoreException extends AppException {
  const FirestoreException([super.message = 'Database error occurred']);
}

/// Chat not found exception
class ChatNotFoundException extends AppException {
  const ChatNotFoundException([super.message = 'Chat not found']);
}

/// Message not found exception
class MessageNotFoundException extends AppException {
  const MessageNotFoundException([super.message = 'Message not found']);
}

/// Unauthorized chat access exception
class UnauthorizedChatAccessException extends AppException {
  const UnauthorizedChatAccessException([
    super.message = 'You do not have access to this chat',
  ]);
}
