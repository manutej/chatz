import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/features/chat/domain/entities/message_entity.dart';

/// Repository interface for message operations
abstract class MessageRepository {
  /// Get messages for a chat with real-time updates
  /// Returns a stream that automatically updates with new messages
  Stream<Either<Failure, List<MessageEntity>>> getChatMessages({
    required String chatId,
    int limit = 50,
  });

  /// Get paginated messages (for loading more history)
  /// Uses cursor-based pagination with DocumentSnapshot
  Future<Either<Failure, List<MessageEntity>>> getMessagesPaginated({
    required String chatId,
    required int limit,
    DocumentSnapshot? lastDocument,
  });

  /// Get a specific message by ID
  Future<Either<Failure, MessageEntity>> getMessageById({
    required String chatId,
    required String messageId,
  });

  /// Send a text message
  Future<Either<Failure, MessageEntity>> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String content,
    required MessageType type,
    String? mediaUrl,
    Map<String, dynamic>? mediaMetadata,
    String? replyToMessageId,
    String? replyToContent,
    String? replyToSenderName,
  });

  /// Upload and send media message
  /// Handles file upload to Firebase Storage and creates message
  Future<Either<Failure, MessageEntity>> sendMediaMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String filePath,
    required MessageType type,
    String? caption,
    String? replyToMessageId,
    String? replyToContent,
    String? replyToSenderName,
  });

  /// Mark messages as read by user
  /// Updates readBy array for unread messages
  Future<Either<Failure, void>> markMessagesAsRead({
    required String chatId,
    required String userId,
    required List<String> messageIds,
  });

  /// Mark messages as delivered to user
  Future<Either<Failure, void>> markMessagesAsDelivered({
    required String chatId,
    required String userId,
    required List<String> messageIds,
  });

  /// Add reaction to message
  Future<Either<Failure, void>> addReaction({
    required String chatId,
    required String messageId,
    required String userId,
    required String emoji,
  });

  /// Remove reaction from message
  Future<Either<Failure, void>> removeReaction({
    required String chatId,
    required String messageId,
    required String userId,
  });

  /// Edit message (only sender can edit)
  Future<Either<Failure, void>> editMessage({
    required String chatId,
    required String messageId,
    required String userId,
    required String newContent,
  });

  /// Delete message for everyone (only sender can do this)
  Future<Either<Failure, void>> deleteMessage({
    required String chatId,
    required String messageId,
    required String userId,
  });

  /// Delete message for self only
  Future<Either<Failure, void>> deleteMessageForSelf({
    required String chatId,
    required String messageId,
    required String userId,
  });

  /// Search messages in a chat
  Future<Either<Failure, List<MessageEntity>>> searchMessages({
    required String chatId,
    required String query,
    int limit = 20,
  });

  /// Get media messages (images, videos, files)
  Future<Either<Failure, List<MessageEntity>>> getMediaMessages({
    required String chatId,
    required MessageType type,
    int limit = 20,
  });
}
