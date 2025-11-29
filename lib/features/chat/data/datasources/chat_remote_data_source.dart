import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatz/core/errors/exceptions.dart';
import 'package:chatz/features/chat/data/models/chat_model.dart';
import 'package:chatz/features/chat/data/models/participant_model.dart';

/// Remote data source for chat operations using Firestore
abstract class ChatRemoteDataSource {
  Stream<List<ChatModel>> getUserChats(String userId);
  Future<ChatModel> getChatById(String chatId);
  Future<ChatModel> createOneToOneChat({
    required String currentUserId,
    required String otherUserId,
    required String currentUserName,
    required String otherUserName,
    String? currentUserPhotoUrl,
    String? otherUserPhotoUrl,
  });
  Future<ChatModel> createGroupChat({
    required String createdBy,
    required String name,
    String? description,
    String? photoUrl,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    required Map<String, String?> participantPhotos,
  });
  Future<void> updateChatMetadata({
    required String chatId,
    required String userId,
    String? name,
    String? description,
    String? photoUrl,
  });
  Future<void> addParticipants({
    required String chatId,
    required String adminId,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    required Map<String, String?> participantPhotos,
  });
  Future<void> removeParticipant({
    required String chatId,
    required String adminId,
    required String participantId,
  });
  Future<void> leaveChat({
    required String chatId,
    required String userId,
  });
  Future<void> archiveChat({
    required String chatId,
    required String userId,
    required bool isArchived,
  });
  Future<void> pinChat({
    required String chatId,
    required String userId,
    required bool isPinned,
  });
  Future<void> muteChat({
    required String chatId,
    required String userId,
    required bool isMuted,
  });
  Future<void> deleteChat({
    required String chatId,
    required String userId,
  });
  Future<ChatModel?> findExistingOneToOneChat({
    required String userId1,
    required String userId2,
  });
}

/// Implementation of ChatRemoteDataSource using Firestore
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore firestore;
  static const String _chatsCollection = 'chats';

  ChatRemoteDataSourceImpl(this.firestore);

  @override
  Stream<List<ChatModel>> getUserChats(String userId) {
    try {
      return firestore
          .collection(_chatsCollection)
          .where('participants', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ChatModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw FirestoreException('Failed to get user chats: ${e.toString()}');
    }
  }

  @override
  Future<ChatModel> getChatById(String chatId) async {
    try {
      final doc =
          await firestore.collection(_chatsCollection).doc(chatId).get();

      if (!doc.exists) {
        throw const ChatNotFoundException();
      }

      return ChatModel.fromFirestore(doc);
    } on ChatNotFoundException {
      rethrow;
    } catch (e) {
      throw FirestoreException('Failed to get chat: ${e.toString()}');
    }
  }

  @override
  Future<ChatModel> createOneToOneChat({
    required String currentUserId,
    required String otherUserId,
    required String currentUserName,
    required String otherUserName,
    String? currentUserPhotoUrl,
    String? otherUserPhotoUrl,
  }) async {
    try {
      // Create participant details
      final participantDetails = {
        currentUserId:
            ParticipantModel(
              displayName: currentUserName,
              photoUrl: currentUserPhotoUrl,
            ).toJson(),
        otherUserId:
            ParticipantModel(
              displayName: otherUserName,
              photoUrl: otherUserPhotoUrl,
            ).toJson(),
      };

      final now = Timestamp.now();
      final chatData = {
        'type': 'one-to-one',
        'participants': [currentUserId, otherUserId],
        'participantDetails': participantDetails,
        'createdBy': currentUserId,
        'admins': <String>[],
        'unreadCount': {currentUserId: 0, otherUserId: 0},
        'isArchived': {currentUserId: false, otherUserId: false},
        'isPinned': {currentUserId: false, otherUserId: false},
        'isMuted': {currentUserId: false, otherUserId: false},
        'createdAt': now,
        'updatedAt': now,
      };

      final docRef =
          await firestore.collection(_chatsCollection).add(chatData);
      final doc = await docRef.get();

      return ChatModel.fromFirestore(doc);
    } catch (e) {
      throw FirestoreException(
        'Failed to create one-to-one chat: ${e.toString()}',
      );
    }
  }

  @override
  Future<ChatModel> createGroupChat({
    required String createdBy,
    required String name,
    String? description,
    String? photoUrl,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    required Map<String, String?> participantPhotos,
  }) async {
    try {
      // Create participant details
      final Map<String, dynamic> participantDetails = {};
      for (final userId in participantIds) {
        participantDetails[userId] = ParticipantModel(
          displayName: participantNames[userId] ?? 'Unknown',
          photoUrl: participantPhotos[userId],
        ).toJson();
      }

      // Initialize unread, archived, pinned, muted for all participants
      final Map<String, int> unreadCount = {};
      final Map<String, bool> isArchived = {};
      final Map<String, bool> isPinned = {};
      final Map<String, bool> isMuted = {};
      for (final userId in participantIds) {
        unreadCount[userId] = 0;
        isArchived[userId] = false;
        isPinned[userId] = false;
        isMuted[userId] = false;
      }

      final now = Timestamp.now();
      final chatData = {
        'type': 'group',
        'name': name,
        'description': description,
        'photoUrl': photoUrl,
        'participants': participantIds,
        'participantDetails': participantDetails,
        'createdBy': createdBy,
        'admins': [createdBy], // Creator is admin by default
        'unreadCount': unreadCount,
        'isArchived': isArchived,
        'isPinned': isPinned,
        'isMuted': isMuted,
        'createdAt': now,
        'updatedAt': now,
      };

      final docRef =
          await firestore.collection(_chatsCollection).add(chatData);
      final doc = await docRef.get();

      return ChatModel.fromFirestore(doc);
    } catch (e) {
      throw FirestoreException('Failed to create group chat: ${e.toString()}');
    }
  }

  @override
  Future<void> updateChatMetadata({
    required String chatId,
    required String userId,
    String? name,
    String? description,
    String? photoUrl,
  }) async {
    try {
      // Verify user is admin
      final chat = await getChatById(chatId);
      if (!chat.admins.contains(userId)) {
        throw const UnauthorizedChatAccessException(
          'Only admins can update chat metadata',
        );
      }

      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (photoUrl != null) updateData['photoUrl'] = photoUrl;

      await firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .update(updateData);
    } on UnauthorizedChatAccessException {
      rethrow;
    } catch (e) {
      throw FirestoreException(
        'Failed to update chat metadata: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> addParticipants({
    required String chatId,
    required String adminId,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    required Map<String, String?> participantPhotos,
  }) async {
    try {
      // Verify user is admin
      final chat = await getChatById(chatId);
      if (!chat.admins.contains(adminId)) {
        throw const UnauthorizedChatAccessException(
          'Only admins can add participants',
        );
      }

      // Prepare participant details to add
      final Map<String, dynamic> newParticipantDetails = {};
      final Map<String, int> newUnreadCount = {};
      final Map<String, bool> newIsArchived = {};
      final Map<String, bool> newIsPinned = {};
      final Map<String, bool> newIsMuted = {};

      for (final userId in participantIds) {
        newParticipantDetails['participantDetails.$userId'] =
            ParticipantModel(
          displayName: participantNames[userId] ?? 'Unknown',
          photoUrl: participantPhotos[userId],
        ).toJson();
        newUnreadCount['unreadCount.$userId'] = 0;
        newIsArchived['isArchived.$userId'] = false;
        newIsPinned['isPinned.$userId'] = false;
        newIsMuted['isMuted.$userId'] = false;
      }

      // Update chat with new participants
      await firestore.collection(_chatsCollection).doc(chatId).update({
        'participants': FieldValue.arrayUnion(participantIds),
        ...newParticipantDetails,
        ...newUnreadCount,
        ...newIsArchived,
        ...newIsPinned,
        ...newIsMuted,
        'updatedAt': Timestamp.now(),
      });
    } on UnauthorizedChatAccessException {
      rethrow;
    } catch (e) {
      throw FirestoreException('Failed to add participants: ${e.toString()}');
    }
  }

  @override
  Future<void> removeParticipant({
    required String chatId,
    required String adminId,
    required String participantId,
  }) async {
    try {
      // Verify user is admin
      final chat = await getChatById(chatId);
      if (!chat.admins.contains(adminId)) {
        throw const UnauthorizedChatAccessException(
          'Only admins can remove participants',
        );
      }

      // Can't remove yourself as admin if you're the only admin
      if (participantId == adminId &&
          chat.admins.length == 1 &&
          chat.admins.contains(adminId)) {
        throw const ValidationException(
          'Cannot remove the only admin. Transfer admin rights first.',
        );
      }

      // Remove participant
      await firestore.collection(_chatsCollection).doc(chatId).update({
        'participants': FieldValue.arrayRemove([participantId]),
        'admins': FieldValue.arrayRemove([participantId]),
        'participantDetails.$participantId': FieldValue.delete(),
        'unreadCount.$participantId': FieldValue.delete(),
        'isArchived.$participantId': FieldValue.delete(),
        'isPinned.$participantId': FieldValue.delete(),
        'isMuted.$participantId': FieldValue.delete(),
        'updatedAt': Timestamp.now(),
      });
    } on UnauthorizedChatAccessException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw FirestoreException(
        'Failed to remove participant: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> leaveChat({
    required String chatId,
    required String userId,
  }) async {
    try {
      final chat = await getChatById(chatId);

      // If leaving user is the only admin, prevent leaving
      if (chat.admins.length == 1 &&
          chat.admins.contains(userId) &&
          chat.participants.length > 1) {
        throw const ValidationException(
          'Transfer admin rights before leaving the group',
        );
      }

      // Remove user from chat
      await firestore.collection(_chatsCollection).doc(chatId).update({
        'participants': FieldValue.arrayRemove([userId]),
        'admins': FieldValue.arrayRemove([userId]),
        'participantDetails.$userId': FieldValue.delete(),
        'unreadCount.$userId': FieldValue.delete(),
        'isArchived.$userId': FieldValue.delete(),
        'isPinned.$userId': FieldValue.delete(),
        'isMuted.$userId': FieldValue.delete(),
        'updatedAt': Timestamp.now(),
      });
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw FirestoreException('Failed to leave chat: ${e.toString()}');
    }
  }

  @override
  Future<void> archiveChat({
    required String chatId,
    required String userId,
    required bool isArchived,
  }) async {
    try {
      await firestore.collection(_chatsCollection).doc(chatId).update({
        'isArchived.$userId': isArchived,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw FirestoreException('Failed to archive chat: ${e.toString()}');
    }
  }

  @override
  Future<void> pinChat({
    required String chatId,
    required String userId,
    required bool isPinned,
  }) async {
    try {
      await firestore.collection(_chatsCollection).doc(chatId).update({
        'isPinned.$userId': isPinned,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw FirestoreException('Failed to pin chat: ${e.toString()}');
    }
  }

  @override
  Future<void> muteChat({
    required String chatId,
    required String userId,
    required bool isMuted,
  }) async {
    try {
      await firestore.collection(_chatsCollection).doc(chatId).update({
        'isMuted.$userId': isMuted,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw FirestoreException('Failed to mute chat: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteChat({
    required String chatId,
    required String userId,
  }) async {
    try {
      final chat = await getChatById(chatId);

      // Only creator can delete the chat
      if (chat.createdBy != userId) {
        throw const UnauthorizedChatAccessException(
          'Only the creator can delete this chat',
        );
      }

      // Delete all messages in the chat first (subcollection)
      final messagesSnapshot = await firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection('messages')
          .get();

      // Delete messages in batches of 500
      final batch = firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete the chat document
      await firestore.collection(_chatsCollection).doc(chatId).delete();
    } on UnauthorizedChatAccessException {
      rethrow;
    } catch (e) {
      throw FirestoreException('Failed to delete chat: ${e.toString()}');
    }
  }

  @override
  Future<ChatModel?> findExistingOneToOneChat({
    required String userId1,
    required String userId2,
  }) async {
    try {
      // Query for existing one-to-one chat between two users
      final querySnapshot = await firestore
          .collection(_chatsCollection)
          .where('type', isEqualTo: 'one-to-one')
          .where('participants', arrayContains: userId1)
          .get();

      // Filter for chat that contains both users
      for (final doc in querySnapshot.docs) {
        final chat = ChatModel.fromFirestore(doc);
        if (chat.participants.contains(userId2)) {
          return chat;
        }
      }

      return null;
    } catch (e) {
      throw FirestoreException(
        'Failed to find existing chat: ${e.toString()}',
      );
    }
  }
}
