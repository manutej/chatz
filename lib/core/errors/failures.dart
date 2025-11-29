import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error occurred']);
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation failed']);
}

/// Permission failures
class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission denied']);
}

/// Payment failures
class PaymentFailure extends Failure {
  const PaymentFailure([super.message = 'Payment failed']);
}

/// Insufficient funds failure
class InsufficientFundsFailure extends Failure {
  const InsufficientFundsFailure([
    super.message = 'Insufficient credits in wallet',
  ]);
}

/// Call failures
class CallFailure extends Failure {
  const CallFailure([super.message = 'Call failed']);
}

/// Media upload failures
class MediaUploadFailure extends Failure {
  const MediaUploadFailure([super.message = 'Media upload failed']);
}

/// Encryption failures
class EncryptionFailure extends Failure {
  const EncryptionFailure([super.message = 'Encryption failed']);
}

/// Not found failures
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found']);
}

/// Timeout failures
class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Request timeout']);
}

/// Unknown failures
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Unknown error occurred']);
}

/// Firestore database failures
class FirestoreFailure extends Failure {
  const FirestoreFailure([super.message = 'Database error occurred']);
}

/// Chat not found failures
class ChatNotFoundFailure extends Failure {
  const ChatNotFoundFailure([super.message = 'Chat not found']);
}

/// Message not found failures
class MessageNotFoundFailure extends Failure {
  const MessageNotFoundFailure([super.message = 'Message not found']);
}

/// Unauthorized chat access failures
class UnauthorizedChatAccessFailure extends Failure {
  const UnauthorizedChatAccessFailure([
    super.message = 'You do not have access to this chat',
  ]);
}
