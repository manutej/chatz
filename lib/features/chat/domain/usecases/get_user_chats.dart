import 'package:dartz/dartz.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/features/chat/domain/entities/chat_entity.dart';
import 'package:chatz/features/chat/domain/repositories/chat_repository.dart';

/// Use case for getting user's chats with real-time updates
/// Returns a stream that automatically updates when chats change
class GetUserChats {
  final ChatRepository repository;

  GetUserChats(this.repository);

  /// Execute the use case
  /// Returns stream of chat lists or failure
  Stream<Either<Failure, List<ChatEntity>>> call(String userId) {
    return repository.getUserChats(userId);
  }
}
