import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatz/core/errors/exceptions.dart';
import 'package:chatz/features/chat/data/datasources/message_remote_data_source.dart';
import 'package:chatz/features/chat/domain/entities/message_entity.dart';
import '../../fixtures/message_fixtures.dart';
import '../../fixtures/chat_fixtures.dart';

void main() {
  group('MessageRemoteDataSourceImpl', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseStorage mockStorage;
    late MessageRemoteDataSourceImpl dataSource;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockStorage = MockFirebaseStorage();
      dataSource = MessageRemoteDataSourceImpl(fakeFirestore, mockStorage);
    });

    group('getChatMessages', () {
      test('should return stream of messages for chat', () async {
        // Arrange
        final chatRef = await fakeFirestore
            .collection('chats')
            .add(ChatFixtures.oneToOneChatFirestoreData);
        await chatRef.collection('messages').add(
              MessageFixtures.textMessageFirestoreData,
            );

        // Act
        final stream = dataSource.getChatMessages(chatId: chatRef.id);

        // Assert
        await expectLater(
          stream,
          emits(predicate((messages) => messages.isNotEmpty)),
        );
      });

      test('should order messages by createdAt descending', () async {
        // Arrange
        final chatRef = await fakeFirestore.collection('chats').add({});
        final oldMessage = {
          ...MessageFixtures.textMessageFirestoreData,
          'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
        };
        final newMessage = {
          ...MessageFixtures.textMessageFirestoreData,
          'createdAt': Timestamp.fromDate(DateTime(2025, 1, 15)),
        };

        await chatRef.collection('messages').add(oldMessage);
        await chatRef.collection('messages').add(newMessage);

        // Act
        final stream = dataSource.getChatMessages(chatId: chatRef.id);

        // Assert
        await expectLater(
          stream,
          emits(predicate((messages) {
            if (messages.length < 2) return false;
            return messages[0].createdAt.isAfter(messages[1].createdAt);
          })),
        );
      });

      test('should limit messages to specified limit', () async {
        // Arrange
        final chatRef = await fakeFirestore.collection('chats').add({});
        for (int i = 0; i < 100; i++) {
          await chatRef.collection('messages').add(
                MessageFixtures.textMessageFirestoreData,
              );
        }

        // Act
        final stream = dataSource.getChatMessages(chatId: chatRef.id, limit: 50);

        // Assert
        await expectLater(
          stream,
          emits(predicate((messages) => messages.length == 50)),
        );
      });

      test('should emit updated list when new message is added', () async {
        // Arrange
        final chatRef = await fakeFirestore.collection('chats').add({});
        final stream = dataSource.getChatMessages(chatId: chatRef.id);

        // Act - Add message after stream is created
        await Future.delayed(const Duration(milliseconds: 100));
        await chatRef.collection('messages').add(
              MessageFixtures.textMessageFirestoreData,
            );

        // Assert
        await expectLater(
          stream,
          emitsInOrder([
            [], // Initial empty state
            predicate((messages) => messages.length == 1),
          ]),
        );
      });
    });

    group('getMessagesPaginated', () {
      test('should return paginated messages', () async {
        // Arrange
        final chatRef = await fakeFirestore.collection('chats').add({});
        final messageRefs = <DocumentReference>[];
        for (int i = 0; i < 10; i++) {
          final ref = await chatRef.collection('messages').add({
            ...MessageFixtures.textMessageFirestoreData,
            'content': 'Message $i',
          });
          messageRefs.add(ref);
        }

        // Act
        final firstPage = await dataSource.getMessagesPaginated(
          chatId: chatRef.id,
          limit: 5,
        );

        // Assert
        expect(firstPage.length, 5);
      });

      test('should support pagination with lastDocument', () async {
        // Arrange
        final chatRef = await fakeFirestore.collection('chats').add({});
        for (int i = 0; i < 10; i++) {
          await chatRef.collection('messages').add({
            ...MessageFixtures.textMessageFirestoreData,
            'content': 'Message $i',
          });
        }

        // Act - Get first page
        final firstPage = await dataSource.getMessagesPaginated(
          chatId: chatRef.id,
          limit: 5,
        );

        // Get second page using last document from first page
        final lastDoc = await chatRef
            .collection('messages')
            .orderBy('createdAt', descending: true)
            .limit(5)
            .get()
            .then((snapshot) => snapshot.docs.last);

        final secondPage = await dataSource.getMessagesPaginated(
          chatId: chatRef.id,
          limit: 5,
          lastDocument: lastDoc,
        );

        // Assert
        expect(firstPage.length, 5);
        expect(secondPage.length, 5);
      });
    });

    group('getMessageById', () {
      test('should return message when it exists', () async {
        // Arrange
        final chatRef = await fakeFirestore.collection('chats').add({});
        final messageRef = await chatRef.collection('messages').add(
              MessageFixtures.textMessageFirestoreData,
            );

        // Act
        final result = await dataSource.getMessageById(
          chatId: chatRef.id,
          messageId: messageRef.id,
        );

        // Assert
        expect(result.id, messageRef.id);
        expect(result.content, 'Hello, this is a text message');
      });

      test('should throw MessageNotFoundException when message does not exist', () async {
        // Arrange
        final chatRef = await fakeFirestore.collection('chats').add({});

        // Act & Assert
        expect(
          () => dataSource.getMessageById(
            chatId: chatRef.id,
            messageId: 'non-existent',
          ),
          throwsA(isA<MessageNotFoundException>()),
        );
      });
    });

    group('sendMessage', () {
      test('should send text message successfully', () async {
        // Arrange
        final chatRef = await fakeFirestore
            .collection('chats')
            .add(ChatFixtures.oneToOneChatFirestoreData);

        // Act
        final result = await dataSource.sendMessage(
          chatId: chatRef.id,
          senderId: MessageFixtures.senderId,
          senderName: 'Sender Name',
          senderPhotoUrl: 'https://example.com/sender.jpg',
          content: 'Hello World',
          type: MessageType.text,
        );

        // Assert
        expect(result.content, 'Hello World');
        expect(result.senderId, MessageFixtures.senderId);
        expect(result.type, 'text');
        expect(result.readBy, contains(MessageFixtures.senderId));
      });

      test('should send message with reply metadata', () async {
        // Arrange
        final chatRef = await fakeFirestore.collection('chats').add({});

        // Act
        final result = await dataSource.sendMessage(
          chatId: chatRef.id,
          senderId: MessageFixtures.senderId,
          senderName: 'Sender',
          content: 'Reply message',
          type: MessageType.text,
          replyToMessageId: 'original-msg-id',
          replyToContent: 'Original content',
          replyToSenderName: 'Original Sender',
        );

        // Assert
        expect(result.replyTo, isNotNull);
        expect(result.replyTo!.messageId, 'original-msg-id');
      });

      test('should update chat lastMessage after sending', () async {
        // Arrange
        final chatRef = await fakeFirestore
            .collection('chats')
            .add(ChatFixtures.oneToOneChatFirestoreData);

        // Act
        await dataSource.sendMessage(
          chatId: chatRef.id,
          senderId: MessageFixtures.senderId,
          senderName: 'Sender Name',
          content: 'New message',
          type: MessageType.text,
        );

        // Assert
        final chatDoc = await chatRef.get();
        expect(chatDoc.data()!['lastMessage'], isNotNull);
        expect(chatDoc.data()!['lastMessage']['content'], 'New message');
      });

      test('should increment unread count for other participants', () async {
        // Arrange
        final chatRef = await fakeFirestore
            .collection('chats')
            .add(ChatFixtures.oneToOneChatFirestoreData);

        // Act
        await dataSource.sendMessage(
          chatId: chatRef.id,
          senderId: ChatFixtures.userId1,
          senderName: 'Sender',
          content: 'Message',
          type: MessageType.text,
        );

        // Assert
        final chatDoc = await chatRef.get();
        final unreadCount = chatDoc.data()!['unreadCount'];
        expect(unreadCount[ChatFixtures.userId2], greaterThan(0));
      });

      test('should send image message with media metadata', () async {
        // Arrange
        final chatRef = await fakeFirestore.collection('chats').add({});

        // Act
        final result = await dataSource.sendMessage(
          chatId: chatRef.id,
          senderId: MessageFixtures.senderId,
          senderName: 'Sender',
          content: 'Image message',
          type: MessageType.image,
          mediaUrl: 'https://example.com/image.jpg',
          mediaMetadata: {
            'fileName': 'image.jpg',
            'fileSize': 1024000,
            'mimeType': 'image/jpeg',
          },
        );

        // Assert
        expect(result.type, 'image');
        expect(result.mediaUrl, 'https://example.com/image.jpg');
        expect(result.mediaMetadata, isNotNull);
      });
    });

    group('markMessagesAsRead', () {
      test('should mark multiple messages as read', () async {
        // Arrange
        final chatRef = await fakeFirestore
            .collection('chats')
            .add(ChatFixtures.oneToOneChatFirestoreData);
        final msg1Ref = await chatRef.collection('messages').add(
              MessageFixtures.textMessageFirestoreData,
            );
        final msg2Ref = await chatRef.collection('messages').add(
              MessageFixtures.textMessageFirestoreData,
            );

        // Act
        await dataSource.markMessagesAsRead(
          chatId: chatRef.id,
          userId: ChatFixtures.userId2,
          messageIds: [msg1Ref.id, msg2Ref.id],
        );

        // Assert
        final msg1 = await msg1Ref.get();
        final msg2 = await msg2Ref.get();
        expect((msg1.data()!['readBy'] as List), contains(ChatFixtures.userId2));
        expect((msg2.data()!['readBy'] as List), contains(ChatFixtures.userId2));
      });

      test('should reset unread count for user', () async {
        // Arrange
        final chatRef = await fakeFirestore
            .collection('chats')
            .add(ChatFixtures.oneToOneChatFirestoreData);
        final msgRef = await chatRef.collection('messages').add(
              MessageFixtures.textMessageFirestoreData,
            );

        // Act
        await dataSource.markMessagesAsRead(
          chatId: chatRef.id,
          userId: ChatFixtures.userId2,
          messageIds: [msgRef.id],
        );

        // Assert
        final chatDoc = await chatRef.get();
        expect(chatDoc.data()!['unreadCount'][ChatFixtures.userId2], 0);
      });

      test('should handle empty message list', () async {
        // Arrange
        final chatRef = await fakeFirestore.collection('chats').add({});

        // Act & Assert - Should not throw
        await dataSource.markMessagesAsRead(
          chatId: chatRef.id,
          userId: 'user-id',
          messageIds: [],
        );
      });
    });

    group('markMessagesAsDelivered', () {
      test('should mark messages as delivered', () async {
        // Arrange
        final chatRef = await fakeFirestore.collection('chats').add({});
        final msgRef = await chatRef.collection('messages').add(
              MessageFixtures.textMessageFirestoreData,
            );

        // Act
        await dataSource.markMessagesAsDelivered(
          chatId: chatRef.id,
          userId: ChatFixtures.userId2,
          messageIds: [msgRef.id],
        );

        // Assert
        final msg = await msgRef.get();
        expect(
          (msg.data()!['deliveredTo'] as List),
          contains(ChatFixtures.userId2),
        );
      });
    });

    group('addReaction', () {
      test('should add reaction to message', () async {
        // Arrange
        final chatRef = await fakeFirestore.collection('chats').add({});
        final msgRef = await chatRef.collection('messages').add(
              MessageFixtures.textMessageFirestoreData,
            );

        // Act
        await dataSource.addReaction(
          chatId: chatRef.id,
          messageId: msgRef.id,
          userId: 'user-id',
          emoji: '👍',
        );

        // Assert
        final msg = await msgRef.get();
        expect(msg.data()!['reactions']['user-id'], '👍');
      });

      test('should update existing reaction', () async {
        // Arrange
        final chatRef = await fakeFirestore.collection('chats').add({});
        final msgRef = await chatRef.collection('messages').add(
              MessageFixtures.textMessageFirestoreData,
            );

        // Act - Add first reaction
        await dataSource.addReaction(
          chatId: chatRef.id,
          messageId: msgRef.id,
          userId: 'user-id',
          emoji: '👍',
        );

        // Act - Update to different reaction
        await dataSource.addReaction(
          chatId: chatRef.id,
          messageId: msgRef.id,
          userId: 'user-id',
          emoji: '❤️',
        );

        // Assert
        final msg = await msgRef.get();
        expect(msg.data()!['reactions']['user-id'], '❤️');
      });
    });

    group('removeReaction', () {
      test('should remove reaction from message', () async {
        // Arrange
        final chatRef = await fakeFirestore.collection('chats').add({});
        final msgRef = await chatRef.collection('messages').add({
          ...MessageFixtures.textMessageFirestoreData,
          'reactions': {'user-id': '👍'},
        });

        // Act
        await dataSource.removeReaction(
          chatId: chatRef.id,
          messageId: msgRef.id,
          userId: 'user-id',
        );

        // Assert
        final msg = await msgRef.get();
        expect(msg.data()!['reactions'].containsKey('user-id'), false);
      });
    });

    group('editMessage', () {
      test('should edit message when user is sender', () async {
        // Arrange
        final chatRef = await fakeFirestore.collection('chats').add({});
        final msgRef = await chatRef.collection('messages').add(
              MessageFixtures.textMessageFirestoreData,
            );

        // Act
        await dataSource.editMessage(
          chatId: chatRef.id,
          messageId: msgRef.id,
          userId: MessageFixtures.senderId,
          newContent: 'Edited content',
        );

        // Assert
        final msg = await msgRef.get();
        expect(msg.data()!['content'], 'Edited content');
        expect(msg.data()!['isEdited'], true);
        expect(msg.data()!['editedAt'], isNotNull);
      });

      test('should throw UnauthorizedChatAccessException when user is not sender', () async {
        // Arrange
        final chatRef = await fakeFirestore.collection('chats').add({});
        final msgRef = await chatRef.collection('messages').add(
              MessageFixtures.textMessageFirestoreData,
            );

        // Act & Assert
        expect(
          () => dataSource.editMessage(
            chatId: chatRef.id,
            messageId: msgRef.id,
            userId: 'other-user',
            newContent: 'Hacked!',
          ),
          throwsA(isA<UnauthorizedChatAccessException>()),
        );
      });
    });

    group('deleteMessage', () {
      test('should mark message as deleted when user is sender', () async {
        // Arrange
        final chatRef = await fakeFirestore.collection('chats').add({});
        final msgRef = await chatRef.collection('messages').add(
              MessageFixtures.textMessageFirestoreData,
            );

        // Act
        await dataSource.deleteMessage(
          chatId: chatRef.id,
          messageId: msgRef.id,
          userId: MessageFixtures.senderId,
        );

        // Assert
        final msg = await msgRef.get();
        expect(msg.data()!['isDeleted'], true);
        expect(msg.data()!['content'], 'This message was deleted');
      });

      test('should throw UnauthorizedChatAccessException when user is not sender', () async {
        // Arrange
        final chatRef = await fakeFirestore.collection('chats').add({});
        final msgRef = await chatRef.collection('messages').add(
              MessageFixtures.textMessageFirestoreData,
            );

        // Act & Assert
        expect(
          () => dataSource.deleteMessage(
            chatId: chatRef.id,
            messageId: msgRef.id,
            userId: 'other-user',
          ),
          throwsA(isA<UnauthorizedChatAccessException>()),
        );
      });
    });

    group('deleteMessageForSelf', () {
      test('should add user to deletedFor array', () async {
        // Arrange
        final chatRef = await fakeFirestore.collection('chats').add({});
        final msgRef = await chatRef.collection('messages').add(
              MessageFixtures.textMessageFirestoreData,
            );

        // Act
        await dataSource.deleteMessageForSelf(
          chatId: chatRef.id,
          messageId: msgRef.id,
          userId: 'user-id',
        );

        // Assert
        final msg = await msgRef.get();
        expect(
          (msg.data()!['deletedFor'] as List),
          contains('user-id'),
        );
      });
    });

    group('batch operations', () {
      test('should handle batch writes for large number of messages', () async {
        // Arrange
        final chatRef = await fakeFirestore.collection('chats').add({});
        final messageIds = <String>[];

        // Create 600 messages (more than batch limit of 500)
        for (int i = 0; i < 600; i++) {
          final ref = await chatRef.collection('messages').add(
                MessageFixtures.textMessageFirestoreData,
              );
          messageIds.add(ref.id);
        }

        // Act - Should not throw
        await dataSource.markMessagesAsRead(
          chatId: chatRef.id,
          userId: 'user-id',
          messageIds: messageIds,
        );

        // Assert - Verify first and last messages were marked
        final firstMsg = await chatRef.collection('messages').doc(messageIds.first).get();
        final lastMsg = await chatRef.collection('messages').doc(messageIds.last).get();

        expect((firstMsg.data()!['readBy'] as List), contains('user-id'));
        expect((lastMsg.data()!['readBy'] as List), contains('user-id'));
      });
    });
  });
}
