import 'package:dartz/dartz.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/features/chat/domain/entities/chat_entity.dart';
import 'package:chatz/features/chat/domain/repositories/chat_repository.dart';

/// Parameters for creating a one-to-one chat
class CreateOneToOneChatParams {
  final String currentUserId;
  final String otherUserId;
  final String currentUserName;
  final String otherUserName;
  final String? currentUserPhotoUrl;
  final String? otherUserPhotoUrl;

  const CreateOneToOneChatParams({
    required this.currentUserId,
    required this.otherUserId,
    required this.currentUserName,
    required this.otherUserName,
    this.currentUserPhotoUrl,
    this.otherUserPhotoUrl,
  });
}

/// Parameters for creating a group chat
class CreateGroupChatParams {
  final String createdBy;
  final String name;
  final String? description;
  final String? photoUrl;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String?> participantPhotos;

  const CreateGroupChatParams({
    required this.createdBy,
    required this.name,
    this.description,
    this.photoUrl,
    required this.participantIds,
    required this.participantNames,
    required this.participantPhotos,
  });
}

/// Use case for creating a chat
/// Handles both one-to-one and group chats
class CreateChat {
  final ChatRepository repository;

  CreateChat(this.repository);

  /// Create or get one-to-one chat
  /// If chat already exists, returns existing chat
  Future<Either<Failure, ChatEntity>> createOneToOne(
    CreateOneToOneChatParams params,
  ) async {
    return await repository.getOrCreateOneToOneChat(
      currentUserId: params.currentUserId,
      otherUserId: params.otherUserId,
      currentUserName: params.currentUserName,
      otherUserName: params.otherUserName,
      currentUserPhotoUrl: params.currentUserPhotoUrl,
      otherUserPhotoUrl: params.otherUserPhotoUrl,
    );
  }

  /// Create a new group chat
  Future<Either<Failure, ChatEntity>> createGroup(
    CreateGroupChatParams params,
  ) async {
    return await repository.createGroupChat(
      createdBy: params.createdBy,
      name: params.name,
      description: params.description,
      photoUrl: params.photoUrl,
      participantIds: params.participantIds,
      participantNames: params.participantNames,
      participantPhotos: params.participantPhotos,
    );
  }
}
