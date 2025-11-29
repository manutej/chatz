import 'package:dartz/dartz.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/features/chat/domain/entities/message_entity.dart';
import 'package:chatz/features/chat/domain/repositories/message_repository.dart';

/// Parameters for getting chat messages
class GetChatMessagesParams {
  final String chatId;
  final int limit;

  const GetChatMessagesParams({
    required this.chatId,
    this.limit = 50,
  });
}

/// Use case for getting chat messages with real-time updates
/// Returns a stream that automatically updates with new messages
class GetChatMessages {
  final MessageRepository repository;

  GetChatMessages(this.repository);

  /// Execute the use case
  /// Returns stream of message lists or failure
  Stream<Either<Failure, List<MessageEntity>>> call(
    GetChatMessagesParams params,
  ) {
    return repository.getChatMessages(
      chatId: params.chatId,
      limit: params.limit,
    );
  }
}
