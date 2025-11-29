import 'package:dartz/dartz.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/features/chat/domain/entities/message_entity.dart';
import 'package:chatz/features/chat/domain/repositories/message_repository.dart';

/// Parameters for sending a message
class SendMessageParams {
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String content;
  final MessageType type;
  final String? mediaUrl;
  final Map<String, dynamic>? mediaMetadata;
  final String? replyToMessageId;
  final String? replyToContent;
  final String? replyToSenderName;

  const SendMessageParams({
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.content,
    this.type = MessageType.text,
    this.mediaUrl,
    this.mediaMetadata,
    this.replyToMessageId,
    this.replyToContent,
    this.replyToSenderName,
  });
}

/// Use case for sending a message
/// Handles both text and media messages
class SendMessage {
  final MessageRepository repository;

  SendMessage(this.repository);

  /// Execute the use case
  /// Returns the sent message or failure
  Future<Either<Failure, MessageEntity>> call(SendMessageParams params) async {
    return await repository.sendMessage(
      chatId: params.chatId,
      senderId: params.senderId,
      senderName: params.senderName,
      senderPhotoUrl: params.senderPhotoUrl,
      content: params.content,
      type: params.type,
      mediaUrl: params.mediaUrl,
      mediaMetadata: params.mediaMetadata,
      replyToMessageId: params.replyToMessageId,
      replyToContent: params.replyToContent,
      replyToSenderName: params.replyToSenderName,
    );
  }
}
