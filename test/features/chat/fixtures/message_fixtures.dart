import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatz/features/chat/data/models/message_model.dart';
import 'package:chatz/features/chat/domain/entities/message_entity.dart';

/// Test fixtures for message feature tests
class MessageFixtures {
  // Test IDs
  static const String chatId = 'test-chat-id';
  static const String messageId1 = 'message-id-1';
  static const String messageId2 = 'message-id-2';
  static const String messageId3 = 'message-id-3';
  static const String senderId = 'sender-id';
  static const String receiverId = 'receiver-id';

  // Timestamps
  static final DateTime testTimestamp = DateTime(2025, 1, 15, 10, 30);
  static final DateTime editedTimestamp = DateTime(2025, 1, 15, 10, 35);
  static final Timestamp firestoreTimestamp =
      Timestamp.fromDate(testTimestamp);
  static final Timestamp editedFirestoreTimestamp =
      Timestamp.fromDate(editedTimestamp);

  // Media Metadata Entity
  static const mediaMetadataEntity = MediaMetadata(
    fileName: 'image.jpg',
    fileSize: 1024000,
    duration: null,
    mimeType: 'image/jpeg',
    thumbnailUrl: 'https://example.com/thumb.jpg',
  );

  // Media Metadata Model
  static const mediaMetadataModel = MediaMetadataModel(
    fileName: 'image.jpg',
    fileSize: 1024000,
    duration: null,
    mimeType: 'image/jpeg',
    thumbnailUrl: 'https://example.com/thumb.jpg',
  );

  // Reply Metadata Entity
  static const replyMetadataEntity = ReplyMetadata(
    messageId: 'original-message-id',
    content: 'Original message content',
    senderName: 'Original Sender',
  );

  // Reply Metadata Model
  static const replyMetadataModel = ReplyMetadataModel(
    messageId: 'original-message-id',
    content: 'Original message content',
    senderName: 'Original Sender',
  );

  // Text Message Entity
  static final textMessageEntity = MessageEntity(
    id: messageId1,
    chatId: chatId,
    senderId: senderId,
    senderName: 'Sender Name',
    senderPhotoUrl: 'https://example.com/sender.jpg',
    content: 'Hello, this is a text message',
    type: MessageType.text,
    mediaUrl: null,
    mediaMetadata: null,
    replyTo: null,
    readBy: const [senderId],
    deliveredTo: const [],
    reactions: const {},
    isDeleted: false,
    deletedFor: const [],
    isEdited: false,
    editedAt: null,
    createdAt: testTimestamp,
    updatedAt: testTimestamp,
  );

  // Text Message Model
  static final textMessageModel = MessageModel(
    id: messageId1,
    chatId: chatId,
    senderId: senderId,
    senderName: 'Sender Name',
    senderPhotoUrl: 'https://example.com/sender.jpg',
    content: 'Hello, this is a text message',
    type: 'text',
    mediaUrl: null,
    mediaMetadata: null,
    replyTo: null,
    readBy: const [senderId],
    deliveredTo: const [],
    reactions: const {},
    isDeleted: false,
    deletedFor: const [],
    isEdited: false,
    editedAt: null,
    createdAt: testTimestamp,
    updatedAt: testTimestamp,
  );

  // Image Message Entity with Media
  static final imageMessageEntity = MessageEntity(
    id: messageId2,
    chatId: chatId,
    senderId: senderId,
    senderName: 'Sender Name',
    senderPhotoUrl: 'https://example.com/sender.jpg',
    content: 'Check out this image',
    type: MessageType.image,
    mediaUrl: 'https://example.com/image.jpg',
    mediaMetadata: mediaMetadataEntity,
    replyTo: null,
    readBy: const [senderId, receiverId],
    deliveredTo: const [receiverId],
    reactions: const {'user-1': '👍', 'user-2': '❤️'},
    isDeleted: false,
    deletedFor: const [],
    isEdited: false,
    editedAt: null,
    createdAt: testTimestamp,
    updatedAt: testTimestamp,
  );

  // Image Message Model
  static final imageMessageModel = MessageModel(
    id: messageId2,
    chatId: chatId,
    senderId: senderId,
    senderName: 'Sender Name',
    senderPhotoUrl: 'https://example.com/sender.jpg',
    content: 'Check out this image',
    type: 'image',
    mediaUrl: 'https://example.com/image.jpg',
    mediaMetadata: mediaMetadataModel,
    replyTo: null,
    readBy: const [senderId, receiverId],
    deliveredTo: const [receiverId],
    reactions: const {'user-1': '👍', 'user-2': '❤️'},
    isDeleted: false,
    deletedFor: const [],
    isEdited: false,
    editedAt: null,
    createdAt: testTimestamp,
    updatedAt: testTimestamp,
  );

  // Reply Message Entity
  static final replyMessageEntity = MessageEntity(
    id: messageId3,
    chatId: chatId,
    senderId: receiverId,
    senderName: 'Receiver Name',
    senderPhotoUrl: null,
    content: 'This is a reply',
    type: MessageType.text,
    mediaUrl: null,
    mediaMetadata: null,
    replyTo: replyMetadataEntity,
    readBy: const [receiverId],
    deliveredTo: const [],
    reactions: const {},
    isDeleted: false,
    deletedFor: const [],
    isEdited: false,
    editedAt: null,
    createdAt: testTimestamp,
    updatedAt: testTimestamp,
  );

  // Reply Message Model
  static final replyMessageModel = MessageModel(
    id: messageId3,
    chatId: chatId,
    senderId: receiverId,
    senderName: 'Receiver Name',
    senderPhotoUrl: null,
    content: 'This is a reply',
    type: 'text',
    mediaUrl: null,
    mediaMetadata: null,
    replyTo: replyMetadataModel,
    readBy: const [receiverId],
    deliveredTo: const [],
    reactions: const {},
    isDeleted: false,
    deletedFor: const [],
    isEdited: false,
    editedAt: null,
    createdAt: testTimestamp,
    updatedAt: testTimestamp,
  );

  // Edited Message Entity
  static final editedMessageEntity = MessageEntity(
    id: messageId1,
    chatId: chatId,
    senderId: senderId,
    senderName: 'Sender Name',
    senderPhotoUrl: 'https://example.com/sender.jpg',
    content: 'Edited message content',
    type: MessageType.text,
    mediaUrl: null,
    mediaMetadata: null,
    replyTo: null,
    readBy: const [senderId, receiverId],
    deliveredTo: const [receiverId],
    reactions: const {},
    isDeleted: false,
    deletedFor: const [],
    isEdited: true,
    editedAt: editedTimestamp,
    createdAt: testTimestamp,
    updatedAt: editedTimestamp,
  );

  // Deleted Message Entity
  static final deletedMessageEntity = MessageEntity(
    id: messageId1,
    chatId: chatId,
    senderId: senderId,
    senderName: 'Sender Name',
    senderPhotoUrl: 'https://example.com/sender.jpg',
    content: 'This message was deleted',
    type: MessageType.text,
    mediaUrl: null,
    mediaMetadata: null,
    replyTo: null,
    readBy: const [senderId],
    deliveredTo: const [],
    reactions: const {},
    isDeleted: true,
    deletedFor: const [],
    isEdited: false,
    editedAt: null,
    createdAt: testTimestamp,
    updatedAt: testTimestamp,
  );

  // Firestore document data
  static Map<String, dynamic> get textMessageFirestoreData => {
        'chatId': chatId,
        'senderId': senderId,
        'senderName': 'Sender Name',
        'senderPhotoUrl': 'https://example.com/sender.jpg',
        'content': 'Hello, this is a text message',
        'type': 'text',
        'mediaUrl': null,
        'mediaMetadata': null,
        'replyTo': null,
        'readBy': [senderId],
        'deliveredTo': <String>[],
        'reactions': <String, String>{},
        'isDeleted': false,
        'deletedFor': <String>[],
        'isEdited': false,
        'editedAt': null,
        'createdAt': firestoreTimestamp,
        'updatedAt': firestoreTimestamp,
      };

  static Map<String, dynamic> get imageMessageFirestoreData => {
        'chatId': chatId,
        'senderId': senderId,
        'senderName': 'Sender Name',
        'senderPhotoUrl': 'https://example.com/sender.jpg',
        'content': 'Check out this image',
        'type': 'image',
        'mediaUrl': 'https://example.com/image.jpg',
        'mediaMetadata': mediaMetadataModel.toJson(),
        'replyTo': null,
        'readBy': [senderId, receiverId],
        'deliveredTo': [receiverId],
        'reactions': {'user-1': '👍', 'user-2': '❤️'},
        'isDeleted': false,
        'deletedFor': <String>[],
        'isEdited': false,
        'editedAt': null,
        'createdAt': firestoreTimestamp,
        'updatedAt': firestoreTimestamp,
      };

  static Map<String, dynamic> get replyMessageFirestoreData => {
        'chatId': chatId,
        'senderId': receiverId,
        'senderName': 'Receiver Name',
        'senderPhotoUrl': null,
        'content': 'This is a reply',
        'type': 'text',
        'mediaUrl': null,
        'mediaMetadata': null,
        'replyTo': replyMetadataModel.toJson(),
        'readBy': [receiverId],
        'deliveredTo': <String>[],
        'reactions': <String, String>{},
        'isDeleted': false,
        'deletedFor': <String>[],
        'isEdited': false,
        'editedAt': null,
        'createdAt': firestoreTimestamp,
        'updatedAt': firestoreTimestamp,
      };
}
