import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatz/core/errors/exceptions.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/features/chat/data/datasources/message_remote_data_source.dart';
import 'package:chatz/features/chat/domain/entities/message_entity.dart';
import 'package:chatz/features/chat/domain/repositories/message_repository.dart';

/// Implementation of MessageRepository using remote data source
class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource remoteDataSource;

  MessageRepositoryImpl(this.remoteDataSource);

  @override
  Stream<Either<Failure, List<MessageEntity>>> getChatMessages({
    required String chatId,
    int limit = 50,
  }) {
    try {
      return remoteDataSource
          .getChatMessages(chatId: chatId, limit: limit)
          .map(
        (messageModels) {
          final entities =
              messageModels.map((model) => model.toEntity()).toList();
          return Right<Failure, List<MessageEntity>>(entities);
        },
      ).handleError((error) {
        return Left<Failure, List<MessageEntity>>(_handleError(error));
      });
    } catch (e) {
      return Stream.value(Left(_handleError(e)));
    }
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> getMessagesPaginated({
    required String chatId,
    required int limit,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      final messageModels = await remoteDataSource.getMessagesPaginated(
        chatId: chatId,
        limit: limit,
        lastDocument: lastDocument,
      );
      final entities = messageModels.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, MessageEntity>> getMessageById({
    required String chatId,
    required String messageId,
  }) async {
    try {
      final messageModel = await remoteDataSource.getMessageById(
        chatId: chatId,
        messageId: messageId,
      );
      return Right(messageModel.toEntity());
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
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
  }) async {
    try {
      final messageModel = await remoteDataSource.sendMessage(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        content: content,
        type: type,
        mediaUrl: mediaUrl,
        mediaMetadata: mediaMetadata,
        replyToMessageId: replyToMessageId,
        replyToContent: replyToContent,
        replyToSenderName: replyToSenderName,
      );
      return Right(messageModel.toEntity());
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
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
  }) async {
    try {
      // Upload media file first
      final mediaUrl = await remoteDataSource.uploadMedia(
        chatId: chatId,
        filePath: filePath,
        type: type,
      );

      // Get file metadata (simplified - could be enhanced)
      final fileName = filePath.split('/').last;
      final mediaMetadata = {
        'fileName': fileName,
        'mimeType': _getMimeType(type),
      };

      // Send message with media URL
      final messageModel = await remoteDataSource.sendMessage(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        content: caption ?? _getDefaultCaption(type),
        type: type,
        mediaUrl: mediaUrl,
        mediaMetadata: mediaMetadata,
        replyToMessageId: replyToMessageId,
        replyToContent: replyToContent,
        replyToSenderName: replyToSenderName,
      );

      return Right(messageModel.toEntity());
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> markMessagesAsRead({
    required String chatId,
    required String userId,
    required List<String> messageIds,
  }) async {
    try {
      await remoteDataSource.markMessagesAsRead(
        chatId: chatId,
        userId: userId,
        messageIds: messageIds,
      );
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> markMessagesAsDelivered({
    required String chatId,
    required String userId,
    required List<String> messageIds,
  }) async {
    try {
      await remoteDataSource.markMessagesAsDelivered(
        chatId: chatId,
        userId: userId,
        messageIds: messageIds,
      );
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> addReaction({
    required String chatId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      await remoteDataSource.addReaction(
        chatId: chatId,
        messageId: messageId,
        userId: userId,
        emoji: emoji,
      );
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> removeReaction({
    required String chatId,
    required String messageId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.removeReaction(
        chatId: chatId,
        messageId: messageId,
        userId: userId,
      );
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> editMessage({
    required String chatId,
    required String messageId,
    required String userId,
    required String newContent,
  }) async {
    try {
      await remoteDataSource.editMessage(
        chatId: chatId,
        messageId: messageId,
        userId: userId,
        newContent: newContent,
      );
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage({
    required String chatId,
    required String messageId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.deleteMessage(
        chatId: chatId,
        messageId: messageId,
        userId: userId,
      );
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessageForSelf({
    required String chatId,
    required String messageId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.deleteMessageForSelf(
        chatId: chatId,
        messageId: messageId,
        userId: userId,
      );
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> searchMessages({
    required String chatId,
    required String query,
    int limit = 20,
  }) async {
    // Note: Firestore doesn't support full-text search natively
    // This is a simplified implementation
    // For production, use Algolia or Elasticsearch
    try {
      // Get all messages (limited) and filter client-side
      final messageModels = await remoteDataSource.getMessagesPaginated(
        chatId: chatId,
        limit: limit * 5, // Get more to filter
        lastDocument: null,
      );

      final filtered = messageModels
          .where((message) =>
              message.content.toLowerCase().contains(query.toLowerCase()))
          .take(limit)
          .toList();

      final entities = filtered.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> getMediaMessages({
    required String chatId,
    required MessageType type,
    int limit = 20,
  }) async {
    // Note: This requires a composite index on chatId + type + createdAt
    // For now, we'll get all messages and filter client-side
    try {
      final messageModels = await remoteDataSource.getMessagesPaginated(
        chatId: chatId,
        limit: limit * 3, // Get more to filter
        lastDocument: null,
      );

      final filtered = messageModels
          .where((message) => message.type == type.value)
          .take(limit)
          .toList();

      final entities = filtered.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  /// Get MIME type from message type
  String _getMimeType(MessageType type) {
    switch (type) {
      case MessageType.image:
        return 'image/jpeg';
      case MessageType.video:
        return 'video/mp4';
      case MessageType.audio:
        return 'audio/mpeg';
      case MessageType.file:
        return 'application/octet-stream';
      default:
        return 'text/plain';
    }
  }

  /// Get default caption for media type
  String _getDefaultCaption(MessageType type) {
    switch (type) {
      case MessageType.image:
        return 'Photo';
      case MessageType.video:
        return 'Video';
      case MessageType.audio:
        return 'Audio';
      case MessageType.file:
        return 'File';
      default:
        return '';
    }
  }

  /// Handle errors and convert to appropriate Failure types
  Failure _handleError(dynamic error) {
    if (error is NetworkException) {
      return NetworkFailure(error.message);
    } else if (error is FirestoreException) {
      return FirestoreFailure(error.message);
    } else if (error is MessageNotFoundException) {
      return MessageNotFoundFailure(error.message);
    } else if (error is UnauthorizedChatAccessException) {
      return UnauthorizedChatAccessFailure(error.message);
    } else if (error is MediaUploadException) {
      return MediaUploadFailure(error.message);
    } else if (error is TimeoutException) {
      return TimeoutFailure(error.message);
    } else {
      return UnknownFailure(error.toString());
    }
  }
}
