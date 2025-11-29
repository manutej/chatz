import 'package:dartz/dartz.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/features/chat/domain/repositories/message_repository.dart';

/// Parameters for marking messages as read
class MarkMessagesAsReadParams {
  final String chatId;
  final String userId;
  final List<String> messageIds;

  const MarkMessagesAsReadParams({
    required this.chatId,
    required this.userId,
    required this.messageIds,
  });
}

/// Use case for marking messages as read
/// Updates readBy array for messages and resets unread count
class MarkMessagesAsRead {
  final MessageRepository repository;

  MarkMessagesAsRead(this.repository);

  /// Execute the use case
  /// Returns success or failure
  Future<Either<Failure, void>> call(MarkMessagesAsReadParams params) async {
    if (params.messageIds.isEmpty) {
      return const Right(null);
    }

    return await repository.markMessagesAsRead(
      chatId: params.chatId,
      userId: params.userId,
      messageIds: params.messageIds,
    );
  }
}
