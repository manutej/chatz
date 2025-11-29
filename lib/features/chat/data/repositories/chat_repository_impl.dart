import 'package:dartz/dartz.dart';
import 'package:chatz/core/errors/exceptions.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:chatz/features/chat/domain/entities/chat_entity.dart';
import 'package:chatz/features/chat/domain/repositories/chat_repository.dart';

/// Implementation of ChatRepository using remote data source
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl(this.remoteDataSource);

  @override
  Stream<Either<Failure, List<ChatEntity>>> getUserChats(String userId) {
    try {
      return remoteDataSource.getUserChats(userId).map(
        (chatModels) {
          final entities = chatModels.map((model) => model.toEntity()).toList();
          return Right<Failure, List<ChatEntity>>(entities);
        },
      ).handleError((error) {
        return Left<Failure, List<ChatEntity>>(_handleError(error));
      });
    } catch (e) {
      return Stream.value(Left(_handleError(e)));
    }
  }

  @override
  Future<Either<Failure, ChatEntity>> getChatById(String chatId) async {
    try {
      final chatModel = await remoteDataSource.getChatById(chatId);
      return Right(chatModel.toEntity());
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, ChatEntity>> createOneToOneChat({
    required String currentUserId,
    required String otherUserId,
    required String currentUserName,
    required String otherUserName,
    String? currentUserPhotoUrl,
    String? otherUserPhotoUrl,
  }) async {
    try {
      final chatModel = await remoteDataSource.createOneToOneChat(
        currentUserId: currentUserId,
        otherUserId: otherUserId,
        currentUserName: currentUserName,
        otherUserName: otherUserName,
        currentUserPhotoUrl: currentUserPhotoUrl,
        otherUserPhotoUrl: otherUserPhotoUrl,
      );
      return Right(chatModel.toEntity());
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, ChatEntity>> createGroupChat({
    required String createdBy,
    required String name,
    String? description,
    String? photoUrl,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    required Map<String, String?> participantPhotos,
  }) async {
    try {
      final chatModel = await remoteDataSource.createGroupChat(
        createdBy: createdBy,
        name: name,
        description: description,
        photoUrl: photoUrl,
        participantIds: participantIds,
        participantNames: participantNames,
        participantPhotos: participantPhotos,
      );
      return Right(chatModel.toEntity());
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateChatMetadata({
    required String chatId,
    required String userId,
    String? name,
    String? description,
    String? photoUrl,
  }) async {
    try {
      await remoteDataSource.updateChatMetadata(
        chatId: chatId,
        userId: userId,
        name: name,
        description: description,
        photoUrl: photoUrl,
      );
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> addParticipants({
    required String chatId,
    required String adminId,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    required Map<String, String?> participantPhotos,
  }) async {
    try {
      await remoteDataSource.addParticipants(
        chatId: chatId,
        adminId: adminId,
        participantIds: participantIds,
        participantNames: participantNames,
        participantPhotos: participantPhotos,
      );
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> removeParticipant({
    required String chatId,
    required String adminId,
    required String participantId,
  }) async {
    try {
      await remoteDataSource.removeParticipant(
        chatId: chatId,
        adminId: adminId,
        participantId: participantId,
      );
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> leaveChat({
    required String chatId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.leaveChat(
        chatId: chatId,
        userId: userId,
      );
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> archiveChat({
    required String chatId,
    required String userId,
    required bool isArchived,
  }) async {
    try {
      await remoteDataSource.archiveChat(
        chatId: chatId,
        userId: userId,
        isArchived: isArchived,
      );
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> pinChat({
    required String chatId,
    required String userId,
    required bool isPinned,
  }) async {
    try {
      await remoteDataSource.pinChat(
        chatId: chatId,
        userId: userId,
        isPinned: isPinned,
      );
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> muteChat({
    required String chatId,
    required String userId,
    required bool isMuted,
  }) async {
    try {
      await remoteDataSource.muteChat(
        chatId: chatId,
        userId: userId,
        isMuted: isMuted,
      );
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteChat({
    required String chatId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.deleteChat(
        chatId: chatId,
        userId: userId,
      );
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, ChatEntity>> getOrCreateOneToOneChat({
    required String currentUserId,
    required String otherUserId,
    required String currentUserName,
    required String otherUserName,
    String? currentUserPhotoUrl,
    String? otherUserPhotoUrl,
  }) async {
    try {
      // Check if chat already exists
      final existingChat = await remoteDataSource.findExistingOneToOneChat(
        userId1: currentUserId,
        userId2: otherUserId,
      );

      if (existingChat != null) {
        return Right(existingChat.toEntity());
      }

      // Create new chat if doesn't exist
      final newChat = await remoteDataSource.createOneToOneChat(
        currentUserId: currentUserId,
        otherUserId: otherUserId,
        currentUserName: currentUserName,
        otherUserName: otherUserName,
        currentUserPhotoUrl: currentUserPhotoUrl,
        otherUserPhotoUrl: otherUserPhotoUrl,
      );

      return Right(newChat.toEntity());
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  /// Handle errors and convert to appropriate Failure types
  Failure _handleError(dynamic error) {
    if (error is NetworkException) {
      return NetworkFailure(error.message);
    } else if (error is FirestoreException) {
      return FirestoreFailure(error.message);
    } else if (error is ChatNotFoundException) {
      return ChatNotFoundFailure(error.message);
    } else if (error is UnauthorizedChatAccessException) {
      return UnauthorizedChatAccessFailure(error.message);
    } else if (error is ValidationException) {
      return ValidationFailure(error.message);
    } else if (error is TimeoutException) {
      return TimeoutFailure(error.message);
    } else {
      return UnknownFailure(error.toString());
    }
  }
}
