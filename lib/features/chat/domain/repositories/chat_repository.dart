import 'package:dartz/dartz.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/features/chat/domain/entities/chat_entity.dart';

/// Repository interface for chat operations
/// Follows repository pattern with Either<Failure, Success> return types
abstract class ChatRepository {
  /// Get all chats for a user with real-time updates
  /// Returns a stream of chat lists that updates automatically
  Stream<Either<Failure, List<ChatEntity>>> getUserChats(String userId);

  /// Get a specific chat by ID
  Future<Either<Failure, ChatEntity>> getChatById(String chatId);

  /// Create a new one-to-one chat
  /// Returns the created chat or reuses existing if already exists
  Future<Either<Failure, ChatEntity>> createOneToOneChat({
    required String currentUserId,
    required String otherUserId,
    required String currentUserName,
    required String otherUserName,
    String? currentUserPhotoUrl,
    String? otherUserPhotoUrl,
  });

  /// Create a new group chat
  Future<Either<Failure, ChatEntity>> createGroupChat({
    required String createdBy,
    required String name,
    String? description,
    String? photoUrl,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    required Map<String, String?> participantPhotos,
  });

  /// Update chat metadata (name, description, photo)
  /// Only for group chats and only by admins
  Future<Either<Failure, void>> updateChatMetadata({
    required String chatId,
    required String userId,
    String? name,
    String? description,
    String? photoUrl,
  });

  /// Add participants to group chat
  Future<Either<Failure, void>> addParticipants({
    required String chatId,
    required String adminId,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    required Map<String, String?> participantPhotos,
  });

  /// Remove participant from group chat
  Future<Either<Failure, void>> removeParticipant({
    required String chatId,
    required String adminId,
    required String participantId,
  });

  /// Leave a group chat
  Future<Either<Failure, void>> leaveChat({
    required String chatId,
    required String userId,
  });

  /// Archive/unarchive chat for a user
  Future<Either<Failure, void>> archiveChat({
    required String chatId,
    required String userId,
    required bool isArchived,
  });

  /// Pin/unpin chat for a user
  Future<Either<Failure, void>> pinChat({
    required String chatId,
    required String userId,
    required bool isPinned,
  });

  /// Mute/unmute chat for a user
  Future<Either<Failure, void>> muteChat({
    required String chatId,
    required String userId,
    required bool isMuted,
  });

  /// Delete chat (only creator can delete)
  Future<Either<Failure, void>> deleteChat({
    required String chatId,
    required String userId,
  });

  /// Get or create one-to-one chat (convenience method)
  /// Checks if chat exists, creates if not
  Future<Either<Failure, ChatEntity>> getOrCreateOneToOneChat({
    required String currentUserId,
    required String otherUserId,
    required String currentUserName,
    required String otherUserName,
    String? currentUserPhotoUrl,
    String? otherUserPhotoUrl,
  });
}
