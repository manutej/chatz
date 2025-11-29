import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chatz/features/chat/data/models/message_model.dart';
import 'package:chatz/features/chat/domain/entities/message_entity.dart';
import '../../fixtures/message_fixtures.dart';

void main() {
  group('MessageModel', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    group('JSON Serialization', () {
      test('should serialize text message to JSON correctly', () {
        // Act
        final json = MessageFixtures.textMessageModel.toJson();

        // Assert
        expect(json['id'], MessageFixtures.messageId1);
        expect(json['chatId'], MessageFixtures.chatId);
        expect(json['senderId'], MessageFixtures.senderId);
        expect(json['content'], 'Hello, this is a text message');
        expect(json['type'], 'text');
        expect(json['mediaUrl'], isNull);
        expect(json['isDeleted'], false);
        expect(json['isEdited'], false);
      });

      test('should deserialize text message from JSON correctly', () {
        // Arrange
        final json = MessageFixtures.textMessageModel.toJson();

        // Act
        final model = MessageModel.fromJson(json);

        // Assert
        expect(model.id, MessageFixtures.messageId1);
        expect(model.content, 'Hello, this is a text message');
        expect(model.type, 'text');
      });

      test('should serialize image message with media metadata', () {
        // Act
        final json = MessageFixtures.imageMessageModel.toJson();

        // Assert
        expect(json['type'], 'image');
        expect(json['mediaUrl'], 'https://example.com/image.jpg');
        expect(json['mediaMetadata'], isNotNull);
        expect(json['mediaMetadata']['fileName'], 'image.jpg');
        expect(json['mediaMetadata']['fileSize'], 1024000);
        expect(json['reactions'], {'user-1': '👍', 'user-2': '❤️'});
      });

      test('should serialize reply message with reply metadata', () {
        // Act
        final json = MessageFixtures.replyMessageModel.toJson();

        // Assert
        expect(json['replyTo'], isNotNull);
        expect(json['replyTo']['messageId'], 'original-message-id');
        expect(json['replyTo']['content'], 'Original message content');
        expect(json['replyTo']['senderName'], 'Original Sender');
      });
    });

    group('Firestore Conversion', () {
      test('should convert from Firestore DocumentSnapshot', () async {
        // Arrange
        final collection = fakeFirestore.collection('chats/test/messages');
        await collection.doc(MessageFixtures.messageId1).set(
              MessageFixtures.textMessageFirestoreData,
            );
        final doc = await collection.doc(MessageFixtures.messageId1).get();

        // Act
        final model = MessageModel.fromFirestore(doc);

        // Assert
        expect(model.id, MessageFixtures.messageId1);
        expect(model.chatId, MessageFixtures.chatId);
        expect(model.content, 'Hello, this is a text message');
      });

      test('should convert to Firestore map without id field', () {
        // Act
        final firestoreMap = MessageFixtures.textMessageModel.toFirestore();

        // Assert
        expect(firestoreMap.containsKey('id'), false);
        expect(firestoreMap['chatId'], MessageFixtures.chatId);
        expect(firestoreMap['content'], 'Hello, this is a text message');
      });
    });

    group('Entity Conversion', () {
      test('should convert text message model to entity', () {
        // Act
        final entity = MessageFixtures.textMessageModel.toEntity();

        // Assert
        expect(entity, isA<MessageEntity>());
        expect(entity.id, MessageFixtures.messageId1);
        expect(entity.content, 'Hello, this is a text message');
        expect(entity.type, MessageType.text);
        expect(entity.isDeleted, false);
        expect(entity.isEdited, false);
      });

      test('should convert image message model to entity with media', () {
        // Act
        final entity = MessageFixtures.imageMessageModel.toEntity();

        // Assert
        expect(entity.type, MessageType.image);
        expect(entity.mediaUrl, 'https://example.com/image.jpg');
        expect(entity.mediaMetadata, isNotNull);
        expect(entity.mediaMetadata!.fileName, 'image.jpg');
        expect(entity.mediaMetadata!.fileSize, 1024000);
      });

      test('should convert reply message model to entity with reply data', () {
        // Act
        final entity = MessageFixtures.replyMessageModel.toEntity();

        // Assert
        expect(entity.replyTo, isNotNull);
        expect(entity.replyTo!.messageId, 'original-message-id');
        expect(entity.replyTo!.content, 'Original message content');
        expect(entity.isReply, true);
      });

      test('should convert entity to model', () {
        // Act
        final model = MessageModel.fromEntity(MessageFixtures.textMessageEntity);

        // Assert
        expect(model.id, MessageFixtures.messageId1);
        expect(model.content, 'Hello, this is a text message');
        expect(model.type, 'text');
      });
    });

    group('Timestamp Handling', () {
      test('should handle Firestore Timestamp correctly', () async {
        // Arrange
        final collection = fakeFirestore.collection('chats/test/messages');
        await collection.doc(MessageFixtures.messageId1).set(
              MessageFixtures.textMessageFirestoreData,
            );
        final doc = await collection.doc(MessageFixtures.messageId1).get();

        // Act
        final model = MessageModel.fromFirestore(doc);

        // Assert
        expect(model.createdAt, isA<DateTime>());
        expect(model.updatedAt, isA<DateTime>());
      });

      test('should handle null editedAt timestamp', () {
        // Assert
        expect(MessageFixtures.textMessageModel.editedAt, isNull);

        final entity = MessageFixtures.textMessageModel.toEntity();
        expect(entity.editedAt, isNull);
      });

      test('should handle int timestamp (milliseconds)', () {
        // Arrange
        final jsonWithIntTimestamp = {
          ...MessageFixtures.textMessageModel.toJson(),
          'createdAt': MessageFixtures.testTimestamp.millisecondsSinceEpoch,
          'updatedAt': MessageFixtures.testTimestamp.millisecondsSinceEpoch,
        };

        // Act
        final model = MessageModel.fromJson(jsonWithIntTimestamp);

        // Assert
        expect(model.createdAt, isA<DateTime>());
        expect(model.updatedAt, isA<DateTime>());
      });

      test('should handle string timestamp (ISO8601)', () {
        // Arrange
        final jsonWithStringTimestamp = {
          ...MessageFixtures.textMessageModel.toJson(),
          'createdAt': MessageFixtures.testTimestamp.toIso8601String(),
          'updatedAt': MessageFixtures.testTimestamp.toIso8601String(),
        };

        // Act
        final model = MessageModel.fromJson(jsonWithStringTimestamp);

        // Assert
        expect(model.createdAt, isA<DateTime>());
        expect(model.updatedAt, isA<DateTime>());
      });
    });

    group('Roundtrip Conversions', () {
      test('should maintain data through full roundtrip', () {
        // Arrange
        final original = MessageFixtures.textMessageModel;

        // Act - Model to Entity to Model
        final entity = original.toEntity();
        final result = MessageModel.fromEntity(entity);

        // Assert
        expect(result.id, original.id);
        expect(result.content, original.content);
        expect(result.type, original.type);
        expect(result.senderId, original.senderId);
      });

      test('should maintain media data through roundtrip', () {
        // Arrange
        final original = MessageFixtures.imageMessageModel;

        // Act
        final entity = original.toEntity();
        final result = MessageModel.fromEntity(entity);

        // Assert
        expect(result.mediaUrl, original.mediaUrl);
        expect(result.mediaMetadata?.fileName, original.mediaMetadata?.fileName);
        expect(result.reactions, original.reactions);
      });
    });

    group('Edge Cases', () {
      test('should handle empty arrays', () {
        // Arrange
        final messageWithEmptyArrays = MessageModel(
          id: 'test-id',
          chatId: 'test-chat',
          senderId: 'sender',
          senderName: 'Sender',
          senderPhotoUrl: null,
          content: 'Test',
          type: 'text',
          mediaUrl: null,
          mediaMetadata: null,
          replyTo: null,
          readBy: const [],
          deliveredTo: const [],
          reactions: const {},
          isDeleted: false,
          deletedFor: const [],
          isEdited: false,
          editedAt: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final entity = messageWithEmptyArrays.toEntity();

        // Assert
        expect(entity.readBy, isEmpty);
        expect(entity.deliveredTo, isEmpty);
        expect(entity.reactions, isEmpty);
        expect(entity.deletedFor, isEmpty);
      });

      test('should handle message without sender photo', () {
        // Arrange
        final model = MessageFixtures.replyMessageModel;

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity.senderPhotoUrl, isNull);
      });
    });
  });

  group('MediaMetadataModel', () {
    test('should serialize and deserialize correctly', () {
      // Arrange
      final model = MessageFixtures.mediaMetadataModel;

      // Act
      final json = model.toJson();
      final result = MediaMetadataModel.fromJson(json);

      // Assert
      expect(result.fileName, model.fileName);
      expect(result.fileSize, model.fileSize);
      expect(result.mimeType, model.mimeType);
    });

    test('should convert to entity correctly', () {
      // Act
      final entity = MessageFixtures.mediaMetadataModel.toEntity();

      // Assert
      expect(entity, isA<MediaMetadata>());
      expect(entity.fileName, 'image.jpg');
      expect(entity.fileSize, 1024000);
    });
  });

  group('ReplyMetadataModel', () {
    test('should serialize and deserialize correctly', () {
      // Arrange
      final model = MessageFixtures.replyMetadataModel;

      // Act
      final json = model.toJson();
      final result = ReplyMetadataModel.fromJson(json);

      // Assert
      expect(result.messageId, model.messageId);
      expect(result.content, model.content);
      expect(result.senderName, model.senderName);
    });

    test('should convert to entity correctly', () {
      // Act
      final entity = MessageFixtures.replyMetadataModel.toEntity();

      // Assert
      expect(entity, isA<ReplyMetadata>());
      expect(entity.messageId, 'original-message-id');
      expect(entity.content, 'Original message content');
    });
  });
}
