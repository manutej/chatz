import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chatz/features/chat/data/models/chat_model.dart';
import 'package:chatz/features/chat/domain/entities/chat_entity.dart';
import '../../fixtures/chat_fixtures.dart';

void main() {
  group('ChatModel', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    group('JSON Serialization', () {
      test('should serialize one-to-one chat to JSON correctly', () {
        // Act
        final json = ChatFixtures.oneToOneChatModel.toJson();

        // Assert
        expect(json['id'], ChatFixtures.oneToOneChatId);
        expect(json['type'], 'one-to-one');
        expect(json['participants'], [ChatFixtures.userId1, ChatFixtures.userId2]);
        expect(json['name'], isNull);
        expect(json['admins'], isEmpty);
      });

      test('should deserialize one-to-one chat from JSON correctly', () {
        // Arrange
        final json = ChatFixtures.oneToOneChatModel.toJson();

        // Act
        final model = ChatModel.fromJson(json);

        // Assert
        expect(model.id, ChatFixtures.oneToOneChatId);
        expect(model.type, 'one-to-one');
        expect(model.participants, [ChatFixtures.userId1, ChatFixtures.userId2]);
      });

      test('should serialize group chat with all fields', () {
        // Act
        final json = ChatFixtures.groupChatModel.toJson();

        // Assert
        expect(json['type'], 'group');
        expect(json['name'], 'Test Group');
        expect(json['description'], 'A test group chat');
        expect(json['photoUrl'], 'https://example.com/group.jpg');
        expect(json['admins'], [ChatFixtures.userId3]);
        expect(json['participants'].length, 3);
      });

      test('should serialize lastMessage correctly', () {
        // Act
        final json = ChatFixtures.oneToOneChatModel.toJson();

        // Assert
        expect(json['lastMessage'], isNotNull);
        expect(json['lastMessage']['content'], 'Hello there!');
        expect(json['lastMessage']['senderId'], ChatFixtures.userId1);
        expect(json['lastMessage']['type'], 'text');
      });

      test('should serialize participant details correctly', () {
        // Act
        final json = ChatFixtures.groupChatModel.toJson();

        // Assert
        expect(json['participantDetails'], isA<Map>());
        expect(json['participantDetails'][ChatFixtures.userId1], isNotNull);
        expect(
          json['participantDetails'][ChatFixtures.userId1]['displayName'],
          'User One',
        );
      });
    });

    group('Firestore Conversion', () {
      test('should convert from Firestore DocumentSnapshot', () async {
        // Arrange
        final collection = fakeFirestore.collection('chats');
        await collection.doc(ChatFixtures.oneToOneChatId).set(
              ChatFixtures.oneToOneChatFirestoreData,
            );
        final doc = await collection.doc(ChatFixtures.oneToOneChatId).get();

        // Act
        final model = ChatModel.fromFirestore(doc);

        // Assert
        expect(model.id, ChatFixtures.oneToOneChatId);
        expect(model.type, 'one-to-one');
      });

      test('should convert to Firestore map without id field', () {
        // Act
        final firestoreMap = ChatFixtures.oneToOneChatModel.toFirestore();

        // Assert
        expect(firestoreMap.containsKey('id'), false);
        expect(firestoreMap['type'], 'one-to-one');
        expect(firestoreMap['participants'], isNotNull);
      });
    });

    group('Entity Conversion', () {
      test('should convert one-to-one chat model to entity', () {
        // Act
        final entity = ChatFixtures.oneToOneChatModel.toEntity();

        // Assert
        expect(entity, isA<ChatEntity>());
        expect(entity.id, ChatFixtures.oneToOneChatId);
        expect(entity.type, ChatType.oneToOne);
        expect(entity.participantIds.length, 2);
        expect(entity.participantDetails.length, 2);
        expect(entity.admins, isEmpty);
      });

      test('should convert group chat model to entity', () {
        // Act
        final entity = ChatFixtures.groupChatModel.toEntity();

        // Assert
        expect(entity.type, ChatType.group);
        expect(entity.name, 'Test Group');
        expect(entity.description, 'A test group chat');
        expect(entity.admins, [ChatFixtures.userId3]);
        expect(entity.participantIds.length, 3);
      });

      test('should convert participant details correctly', () {
        // Act
        final entity = ChatFixtures.groupChatModel.toEntity();

        // Assert
        expect(entity.participantDetails[ChatFixtures.userId1]?.displayName, 'User One');
        expect(entity.participantDetails[ChatFixtures.userId2]?.displayName, 'User Two');
        expect(entity.participantDetails[ChatFixtures.userId3]?.displayName, 'User Three');
        expect(entity.participantDetails[ChatFixtures.userId3]?.isAdmin, true);
      });

      test('should convert entity to model', () {
        // Act
        final model = ChatModel.fromEntity(ChatFixtures.oneToOneChatEntity);

        // Assert
        expect(model.id, ChatFixtures.oneToOneChatId);
        expect(model.type, 'one-to-one');
        expect(model.participants, [ChatFixtures.userId1, ChatFixtures.userId2]);
      });

      test('should handle lastMessage conversion', () {
        // Act
        final entity = ChatFixtures.oneToOneChatModel.toEntity();

        // Assert
        expect(entity.lastMessage, isNotNull);
        expect(entity.lastMessage!.content, 'Hello there!');
        expect(entity.lastMessage!.senderId, ChatFixtures.userId1);
      });

      test('should handle null lastMessage', () {
        // Arrange
        final modelWithoutLastMessage = ChatModel(
          id: 'test-id',
          type: 'one-to-one',
          name: null,
          description: null,
          photoUrl: null,
          participants: const ['user1', 'user2'],
          participantDetails: const {},
          createdBy: 'user1',
          admins: const [],
          lastMessage: null,
          unreadCount: const {},
          isArchived: const {},
          isPinned: const {},
          isMuted: const {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final entity = modelWithoutLastMessage.toEntity();

        // Assert
        expect(entity.lastMessage, isNull);
      });
    });

    group('ChatType Conversion', () {
      test('should convert "one-to-one" string to ChatType.oneToOne', () {
        // Act
        final entity = ChatFixtures.oneToOneChatModel.toEntity();

        // Assert
        expect(entity.type, ChatType.oneToOne);
      });

      test('should convert "group" string to ChatType.group', () {
        // Act
        final entity = ChatFixtures.groupChatModel.toEntity();

        // Assert
        expect(entity.type, ChatType.group);
      });

      test('should convert ChatType.oneToOne to Firestore value', () {
        // Act
        final model = ChatModel.fromEntity(ChatFixtures.oneToOneChatEntity);

        // Assert
        expect(model.type, 'one-to-one');
      });

      test('should convert ChatType.group to Firestore value', () {
        // Act
        final model = ChatModel.fromEntity(ChatFixtures.groupChatEntity);

        // Assert
        expect(model.type, 'group');
      });
    });

    group('User-specific Properties', () {
      test('should preserve unreadCount for all users', () {
        // Act
        final entity = ChatFixtures.oneToOneChatModel.toEntity();

        // Assert
        expect(entity.unreadCount[ChatFixtures.userId1], 0);
        expect(entity.unreadCount[ChatFixtures.userId2], 2);
      });

      test('should preserve isPinned for all users', () {
        // Act
        final entity = ChatFixtures.oneToOneChatModel.toEntity();

        // Assert
        expect(entity.isPinned[ChatFixtures.userId1], false);
        expect(entity.isPinned[ChatFixtures.userId2], true);
      });

      test('should preserve isArchived and isMuted', () {
        // Act
        final entity = ChatFixtures.groupChatModel.toEntity();

        // Assert
        expect(entity.isArchived[ChatFixtures.userId2], false);
        expect(entity.isMuted[ChatFixtures.userId2], true);
      });
    });

    group('Timestamp Handling', () {
      test('should handle Firestore Timestamp correctly', () async {
        // Arrange
        final collection = fakeFirestore.collection('chats');
        await collection.doc(ChatFixtures.oneToOneChatId).set(
              ChatFixtures.oneToOneChatFirestoreData,
            );
        final doc = await collection.doc(ChatFixtures.oneToOneChatId).get();

        // Act
        final model = ChatModel.fromFirestore(doc);

        // Assert
        expect(model.createdAt, isA<DateTime>());
        expect(model.updatedAt, isA<DateTime>());
      });

      test('should convert DateTime to Firestore Timestamp', () {
        // Act
        final firestoreMap = ChatFixtures.oneToOneChatModel.toFirestore();

        // Assert
        expect(firestoreMap['createdAt'], isNotNull);
        expect(firestoreMap['updatedAt'], isNotNull);
      });
    });

    group('Roundtrip Conversions', () {
      test('should maintain data through full roundtrip', () {
        // Arrange
        final original = ChatFixtures.oneToOneChatModel;

        // Act - Model to Entity to Model
        final entity = original.toEntity();
        final result = ChatModel.fromEntity(entity);

        // Assert
        expect(result.id, original.id);
        expect(result.type, original.type);
        expect(result.participants, original.participants);
        expect(result.unreadCount, original.unreadCount);
      });

      test('should maintain group chat data through roundtrip', () {
        // Arrange
        final original = ChatFixtures.groupChatModel;

        // Act
        final entity = original.toEntity();
        final result = ChatModel.fromEntity(entity);

        // Assert
        expect(result.name, original.name);
        expect(result.description, original.description);
        expect(result.admins, original.admins);
      });
    });

    group('Edge Cases', () {
      test('should handle empty participant details', () {
        // Arrange
        final modelWithEmptyDetails = ChatModel(
          id: 'test-id',
          type: 'group',
          name: 'Test',
          description: null,
          photoUrl: null,
          participants: const ['user1'],
          participantDetails: const {},
          createdBy: 'user1',
          admins: const [],
          lastMessage: null,
          unreadCount: const {},
          isArchived: const {},
          isPinned: const {},
          isMuted: const {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final entity = modelWithEmptyDetails.toEntity();

        // Assert
        expect(entity.participantDetails, isEmpty);
      });

      test('should handle empty admins array', () {
        // Act
        final entity = ChatFixtures.oneToOneChatModel.toEntity();

        // Assert
        expect(entity.admins, isEmpty);
      });
    });
  });

  group('LastMessageModel', () {
    test('should serialize and deserialize correctly', () {
      // Arrange
      final model = ChatFixtures.lastMessageModel;

      // Act
      final json = model.toJson();
      final result = LastMessageModel.fromJson(json);

      // Assert
      expect(result.content, model.content);
      expect(result.senderId, model.senderId);
      expect(result.senderName, model.senderName);
      expect(result.type, model.type);
    });

    test('should convert to entity correctly', () {
      // Act
      final entity = ChatFixtures.lastMessageModel.toEntity();

      // Assert
      expect(entity, isA<LastMessage>());
      expect(entity.content, 'Hello there!');
      expect(entity.type, 'text');
    });

    test('should get correct displayText for media types', () {
      // Arrange
      final imageMessage = LastMessage(
        content: 'image.jpg',
        senderId: 'sender',
        senderName: 'Sender',
        timestamp: DateTime.now(),
        type: 'image',
      );

      // Assert
      expect(imageMessage.displayText, 'Photo');
    });
  });
}
