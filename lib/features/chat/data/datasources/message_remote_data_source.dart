import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:chatz/core/errors/exceptions.dart';
import 'package:chatz/features/chat/data/models/message_model.dart';
import 'package:chatz/features/chat/domain/entities/message_entity.dart';
import 'package:uuid/uuid.dart';

/// Remote data source for message operations using Firestore
abstract class MessageRemoteDataSource {
  Stream<List<MessageModel>> getChatMessages({
    required String chatId,
    int limit = 50,
  });
  Future<List<MessageModel>> getMessagesPaginated({
    required String chatId,
    required int limit,
    DocumentSnapshot? lastDocument,
  });
  Future<MessageModel> getMessageById({
    required String chatId,
    required String messageId,
  });
  Future<MessageModel> sendMessage({
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
  Future<String> uploadMedia({
    required String chatId,
    required String filePath,
    required MessageType type,
  });
  Future<void> markMessagesAsRead({
    required String chatId,
    required String userId,
    required List<String> messageIds,
  });
  Future<void> markMessagesAsDelivered({
    required String chatId,
    required String userId,
    required List<String> messageIds,
  });
  Future<void> addReaction({
    required String chatId,
    required String messageId,
    required String userId,
    required String emoji,
  });
  Future<void> removeReaction({
    required String chatId,
    required String messageId,
    required String userId,
  });
  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String userId,
    required String newContent,
  });
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
    required String userId,
  });
  Future<void> deleteMessageForSelf({
    required String chatId,
    required String messageId,
    required String userId,
  });
}

/// Implementation of MessageRemoteDataSource using Firestore
class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  static const String _chatsCollection = 'chats';
  static const String _messagesCollection = 'messages';
  final _uuid = const Uuid();

  MessageRemoteDataSourceImpl(this.firestore, this.storage);

  @override
  Stream<List<MessageModel>> getChatMessages({
    required String chatId,
    int limit = 50,
  }) {
    try {
      return firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw FirestoreException('Failed to get messages: ${e.toString()}');
    }
  }

  @override
  Future<List<MessageModel>> getMessagesPaginated({
    required String chatId,
    required int limit,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw FirestoreException(
        'Failed to get paginated messages: ${e.toString()}',
      );
    }
  }

  @override
  Future<MessageModel> getMessageById({
    required String chatId,
    required String messageId,
  }) async {
    try {
      final doc = await firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .doc(messageId)
          .get();

      if (!doc.exists) {
        throw const MessageNotFoundException();
      }

      return MessageModel.fromFirestore(doc);
    } on MessageNotFoundException {
      rethrow;
    } catch (e) {
      throw FirestoreException('Failed to get message: ${e.toString()}');
    }
  }

  @override
  Future<MessageModel> sendMessage({
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
      final now = Timestamp.now();
      final messageId = _uuid.v4();

      final messageData = {
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'senderPhotoUrl': senderPhotoUrl,
        'content': content,
        'type': type.value,
        'mediaUrl': mediaUrl,
        'mediaMetadata': mediaMetadata,
        'replyTo': replyToMessageId != null
            ? {
                'messageId': replyToMessageId,
                'content': replyToContent ?? '',
                'senderName': replyToSenderName ?? '',
              }
            : null,
        'readBy': [senderId], // Sender has read their own message
        'deliveredTo': <String>[],
        'reactions': <String, String>{},
        'isDeleted': false,
        'deletedFor': <String>[],
        'isEdited': false,
        'editedAt': null,
        'createdAt': now,
        'updatedAt': now,
      };

      // Add message to subcollection
      await firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .doc(messageId)
          .set(messageData);

      // Update chat's lastMessage and updatedAt
      await _updateChatLastMessage(
        chatId: chatId,
        content: content,
        senderId: senderId,
        senderName: senderName,
        timestamp: now,
        type: type.value,
      );

      // Increment unread count for other participants
      await _incrementUnreadCount(chatId, senderId);

      // Retrieve and return the created message
      final doc = await firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .doc(messageId)
          .get();

      return MessageModel.fromFirestore(doc);
    } catch (e) {
      throw FirestoreException('Failed to send message: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadMedia({
    required String chatId,
    required String filePath,
    required MessageType type,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw const MediaUploadException('File does not exist');
      }

      // Generate unique filename
      final fileName = '${_uuid.v4()}_${file.uri.pathSegments.last}';
      final storageRef =
          storage.ref().child('chats/$chatId/media/$fileName');

      // Upload file
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw MediaUploadException('Failed to upload media: ${e.toString()}');
    }
  }

  @override
  Future<void> markMessagesAsRead({
    required String chatId,
    required String userId,
    required List<String> messageIds,
  }) async {
    try {
      if (messageIds.isEmpty) return;

      // Use batched writes (max 500 operations per batch)
      final batch = firestore.batch();
      int operationCount = 0;

      for (final messageId in messageIds) {
        if (operationCount >= 500) {
          await batch.commit();
          operationCount = 0;
        }

        final messageRef = firestore
            .collection(_chatsCollection)
            .doc(chatId)
            .collection(_messagesCollection)
            .doc(messageId);

        batch.update(messageRef, {
          'readBy': FieldValue.arrayUnion([userId]),
          'updatedAt': Timestamp.now(),
        });
        operationCount++;
      }

      if (operationCount > 0) {
        await batch.commit();
      }

      // Reset unread count for this user
      await firestore.collection(_chatsCollection).doc(chatId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      throw FirestoreException(
        'Failed to mark messages as read: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> markMessagesAsDelivered({
    required String chatId,
    required String userId,
    required List<String> messageIds,
  }) async {
    try {
      if (messageIds.isEmpty) return;

      // Use batched writes
      final batch = firestore.batch();
      int operationCount = 0;

      for (final messageId in messageIds) {
        if (operationCount >= 500) {
          await batch.commit();
          operationCount = 0;
        }

        final messageRef = firestore
            .collection(_chatsCollection)
            .doc(chatId)
            .collection(_messagesCollection)
            .doc(messageId);

        batch.update(messageRef, {
          'deliveredTo': FieldValue.arrayUnion([userId]),
          'updatedAt': Timestamp.now(),
        });
        operationCount++;
      }

      if (operationCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      throw FirestoreException(
        'Failed to mark messages as delivered: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> addReaction({
    required String chatId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      await firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .doc(messageId)
          .update({
        'reactions.$userId': emoji,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw FirestoreException('Failed to add reaction: ${e.toString()}');
    }
  }

  @override
  Future<void> removeReaction({
    required String chatId,
    required String messageId,
    required String userId,
  }) async {
    try {
      await firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .doc(messageId)
          .update({
        'reactions.$userId': FieldValue.delete(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw FirestoreException('Failed to remove reaction: ${e.toString()}');
    }
  }

  @override
  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String userId,
    required String newContent,
  }) async {
    try {
      // Verify user is the sender
      final message = await getMessageById(
        chatId: chatId,
        messageId: messageId,
      );

      if (message.senderId != userId) {
        throw const UnauthorizedChatAccessException(
          'Only the sender can edit this message',
        );
      }

      await firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .doc(messageId)
          .update({
        'content': newContent,
        'isEdited': true,
        'editedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } on UnauthorizedChatAccessException {
      rethrow;
    } catch (e) {
      throw FirestoreException('Failed to edit message: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
    required String userId,
  }) async {
    try {
      // Verify user is the sender
      final message = await getMessageById(
        chatId: chatId,
        messageId: messageId,
      );

      if (message.senderId != userId) {
        throw const UnauthorizedChatAccessException(
          'Only the sender can delete this message',
        );
      }

      // Mark as deleted (don't actually delete to preserve message history)
      await firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .doc(messageId)
          .update({
        'isDeleted': true,
        'content': 'This message was deleted',
        'updatedAt': Timestamp.now(),
      });
    } on UnauthorizedChatAccessException {
      rethrow;
    } catch (e) {
      throw FirestoreException('Failed to delete message: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteMessageForSelf({
    required String chatId,
    required String messageId,
    required String userId,
  }) async {
    try {
      await firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .doc(messageId)
          .update({
        'deletedFor': FieldValue.arrayUnion([userId]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw FirestoreException(
        'Failed to delete message for self: ${e.toString()}',
      );
    }
  }

  /// Helper method to update chat's lastMessage
  Future<void> _updateChatLastMessage({
    required String chatId,
    required String content,
    required String senderId,
    required String senderName,
    required Timestamp timestamp,
    required String type,
  }) async {
    await firestore.collection(_chatsCollection).doc(chatId).update({
      'lastMessage': {
        'content': content,
        'senderId': senderId,
        'senderName': senderName,
        'timestamp': timestamp,
        'type': type,
      },
      'updatedAt': timestamp,
    });
  }

  /// Helper method to increment unread count for participants
  Future<void> _incrementUnreadCount(String chatId, String senderId) async {
    try {
      // Get chat to find participants
      final chatDoc =
          await firestore.collection(_chatsCollection).doc(chatId).get();

      if (!chatDoc.exists) return;

      final participants =
          List<String>.from(chatDoc.data()?['participants'] ?? []);
      final Map<String, dynamic> updates = {};

      // Increment unread count for all participants except sender
      for (final participantId in participants) {
        if (participantId != senderId) {
          updates['unreadCount.$participantId'] = FieldValue.increment(1);
        }
      }

      if (updates.isNotEmpty) {
        await firestore.collection(_chatsCollection).doc(chatId).update(
              updates,
            );
      }
    } catch (e) {
      // Log error but don't throw - unread count is not critical
      print('Failed to increment unread count: $e');
    }
  }
}
