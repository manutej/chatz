import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatz/features/chat/data/models/chat_model.dart';
import 'package:chatz/features/chat/data/models/participant_model.dart';
import 'package:chatz/features/chat/domain/entities/chat_entity.dart';
import 'package:chatz/features/chat/domain/entities/participant_entity.dart';

/// Test fixtures for chat feature tests
class ChatFixtures {
  // Test user IDs
  static const String userId1 = 'user-id-1';
  static const String userId2 = 'user-id-2';
  static const String userId3 = 'user-id-3';

  // Test chat IDs
  static const String oneToOneChatId = 'one-to-one-chat-id';
  static const String groupChatId = 'group-chat-id';

  // Timestamps
  static final DateTime testTimestamp = DateTime(2025, 1, 15, 10, 30);
  static final Timestamp firestoreTimestamp =
      Timestamp.fromDate(testTimestamp);

  // Participant Entities
  static const participantEntity1 = ParticipantEntity(
    userId: userId1,
    displayName: 'User One',
    photoUrl: 'https://example.com/user1.jpg',
    isAdmin: false,
  );

  static const participantEntity2 = ParticipantEntity(
    userId: userId2,
    displayName: 'User Two',
    photoUrl: 'https://example.com/user2.jpg',
    isAdmin: false,
  );

  static const participantEntity3 = ParticipantEntity(
    userId: userId3,
    displayName: 'User Three',
    photoUrl: null,
    isAdmin: true,
  );

  // Participant Models
  static const participantModel1 = ParticipantModel(
    displayName: 'User One',
    photoUrl: 'https://example.com/user1.jpg',
  );

  static const participantModel2 = ParticipantModel(
    displayName: 'User Two',
    photoUrl: 'https://example.com/user2.jpg',
  );

  static const participantModel3 = ParticipantModel(
    displayName: 'User Three',
    photoUrl: null,
  );

  // Last Message
  static final lastMessageModel = LastMessageModel(
    content: 'Hello there!',
    senderId: userId1,
    senderName: 'User One',
    timestamp: testTimestamp,
    type: 'text',
  );

  static final lastMessageEntity = LastMessage(
    content: 'Hello there!',
    senderId: userId1,
    senderName: 'User One',
    timestamp: testTimestamp,
    type: 'text',
  );

  // One-to-One Chat Entity
  static final oneToOneChatEntity = ChatEntity(
    id: oneToOneChatId,
    type: ChatType.oneToOne,
    name: null,
    description: null,
    photoUrl: null,
    participantIds: const [userId1, userId2],
    participantDetails: const {
      userId1: participantEntity1,
      userId2: participantEntity2,
    },
    createdBy: userId1,
    admins: const [],
    lastMessage: lastMessageEntity,
    unreadCount: const {userId1: 0, userId2: 2},
    isArchived: const {userId1: false, userId2: false},
    isPinned: const {userId1: false, userId2: true},
    isMuted: const {userId1: false, userId2: false},
    createdAt: testTimestamp,
    updatedAt: testTimestamp,
  );

  // One-to-One Chat Model
  static final oneToOneChatModel = ChatModel(
    id: oneToOneChatId,
    type: 'one-to-one',
    name: null,
    description: null,
    photoUrl: null,
    participants: const [userId1, userId2],
    participantDetails: {
      userId1: participantModel1.toJson(),
      userId2: participantModel2.toJson(),
    },
    createdBy: userId1,
    admins: const [],
    lastMessage: lastMessageModel,
    unreadCount: const {userId1: 0, userId2: 2},
    isArchived: const {userId1: false, userId2: false},
    isPinned: const {userId1: false, userId2: true},
    isMuted: const {userId1: false, userId2: false},
    createdAt: testTimestamp,
    updatedAt: testTimestamp,
  );

  // Group Chat Entity
  static final groupChatEntity = ChatEntity(
    id: groupChatId,
    type: ChatType.group,
    name: 'Test Group',
    description: 'A test group chat',
    photoUrl: 'https://example.com/group.jpg',
    participantIds: const [userId1, userId2, userId3],
    participantDetails: const {
      userId1: participantEntity1,
      userId2: participantEntity2,
      userId3: participantEntity3,
    },
    createdBy: userId3,
    admins: const [userId3],
    lastMessage: lastMessageEntity,
    unreadCount: const {userId1: 5, userId2: 3, userId3: 0},
    isArchived: const {userId1: false, userId2: false, userId3: false},
    isPinned: const {userId1: true, userId2: false, userId3: false},
    isMuted: const {userId1: false, userId2: true, userId3: false},
    createdAt: testTimestamp,
    updatedAt: testTimestamp,
  );

  // Group Chat Model
  static final groupChatModel = ChatModel(
    id: groupChatId,
    type: 'group',
    name: 'Test Group',
    description: 'A test group chat',
    photoUrl: 'https://example.com/group.jpg',
    participants: const [userId1, userId2, userId3],
    participantDetails: {
      userId1: participantModel1.toJson(),
      userId2: participantModel2.toJson(),
      userId3: participantModel3.toJson(),
    },
    createdBy: userId3,
    admins: const [userId3],
    lastMessage: lastMessageModel,
    unreadCount: const {userId1: 5, userId2: 3, userId3: 0},
    isArchived: const {userId1: false, userId2: false, userId3: false},
    isPinned: const {userId1: true, userId2: false, userId3: false},
    isMuted: const {userId1: false, userId2: true, userId3: false},
    createdAt: testTimestamp,
    updatedAt: testTimestamp,
  );

  // Firestore document data
  static Map<String, dynamic> get oneToOneChatFirestoreData => {
        'type': 'one-to-one',
        'participants': [userId1, userId2],
        'participantDetails': {
          userId1: participantModel1.toJson(),
          userId2: participantModel2.toJson(),
        },
        'createdBy': userId1,
        'admins': <String>[],
        'lastMessage': lastMessageModel.toJson(),
        'unreadCount': {userId1: 0, userId2: 2},
        'isArchived': {userId1: false, userId2: false},
        'isPinned': {userId1: false, userId2: true},
        'isMuted': {userId1: false, userId2: false},
        'createdAt': firestoreTimestamp,
        'updatedAt': firestoreTimestamp,
      };

  static Map<String, dynamic> get groupChatFirestoreData => {
        'type': 'group',
        'name': 'Test Group',
        'description': 'A test group chat',
        'photoUrl': 'https://example.com/group.jpg',
        'participants': [userId1, userId2, userId3],
        'participantDetails': {
          userId1: participantModel1.toJson(),
          userId2: participantModel2.toJson(),
          userId3: participantModel3.toJson(),
        },
        'createdBy': userId3,
        'admins': [userId3],
        'lastMessage': lastMessageModel.toJson(),
        'unreadCount': {userId1: 5, userId2: 3, userId3: 0},
        'isArchived': {userId1: false, userId2: false, userId3: false},
        'isPinned': {userId1: true, userId2: false, userId3: false},
        'isMuted': {userId1: false, userId2: true, userId3: false},
        'createdAt': firestoreTimestamp,
        'updatedAt': firestoreTimestamp,
      };
}
