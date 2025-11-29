import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatz/core/errors/exceptions.dart';
import 'package:chatz/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:chatz/features/chat/data/models/chat_model.dart';
import '../../fixtures/chat_fixtures.dart';

void main() {
  group('ChatRemoteDataSourceImpl', () {
    late FakeFirebaseFirestore fakeFirestore;
    late ChatRemoteDataSourceImpl dataSource;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      dataSource = ChatRemoteDataSourceImpl(fakeFirestore);
    });

    group('getUserChats', () {
      test('should return stream of chats for user', () async {
        // Arrange
        await fakeFirestore.collection('chats').add(
              ChatFixtures.oneToOneChatFirestoreData,
            );

        // Act
        final stream = dataSource.getUserChats(ChatFixtures.userId1);

        // Assert
        await expectLater(
          stream,
          emits(predicate<List<ChatModel>>(
            (chats) => chats.isNotEmpty && chats.first.participants.contains(ChatFixtures.userId1),
          )),
        );
      });

      test('should order chats by updatedAt descending', () async {
        // Arrange - Create chats with different timestamps
        final oldChat = {
          ...ChatFixtures.oneToOneChatFirestoreData,
          'updatedAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
        };
        final newChat = {
          ...ChatFixtures.oneToOneChatFirestoreData,
          'updatedAt': Timestamp.fromDate(DateTime(2025, 1, 15)),
        };

        await fakeFirestore.collection('chats').add(oldChat);
        await fakeFirestore.collection('chats').add(newChat);

        // Act
        final stream = dataSource.getUserChats(ChatFixtures.userId1);

        // Assert
        await expectLater(
          stream,
          emits(predicate<List<ChatModel>>((chats) {
            if (chats.length < 2) return false;
            return chats[0].updatedAt.isAfter(chats[1].updatedAt);
          })),
        );
      });

      test('should emit updated list when new chat is added', () async {
        // Arrange
        final stream = dataSource.getUserChats(ChatFixtures.userId1);

        // Act - Add chat after stream is created
        await Future.delayed(const Duration(milliseconds: 100));
        await fakeFirestore.collection('chats').add(
              ChatFixtures.oneToOneChatFirestoreData,
            );

        // Assert
        await expectLater(
          stream,
          emitsInOrder([
            [], // Initial empty state
            predicate<List<ChatModel>>((chats) => chats.length == 1),
          ]),
        );
      });

      test('should only return chats where user is participant', () async {
        // Arrange
        await fakeFirestore.collection('chats').add(
              ChatFixtures.oneToOneChatFirestoreData,
            ); // userId1 is participant

        final otherUserChat = {
          ...ChatFixtures.oneToOneChatFirestoreData,
          'participants': ['other-user-1', 'other-user-2'],
        };
        await fakeFirestore.collection('chats').add(otherUserChat);

        // Act
        final stream = dataSource.getUserChats(ChatFixtures.userId1);

        // Assert
        await expectLater(
          stream,
          emits(predicate<List<ChatModel>>(
            (chats) => chats.length == 1 && chats.first.participants.contains(ChatFixtures.userId1),
          )),
        );
      });
    });

    group('getChatById', () {
      test('should return chat when it exists', () async {
        // Arrange
        final docRef = await fakeFirestore
            .collection('chats')
            .add(ChatFixtures.oneToOneChatFirestoreData);

        // Act
        final result = await dataSource.getChatById(docRef.id);

        // Assert
        expect(result, isA<ChatModel>());
        expect(result.id, docRef.id);
        expect(result.type, 'one-to-one');
      });

      test('should throw ChatNotFoundException when chat does not exist', () async {
        // Act & Assert
        expect(
          () => dataSource.getChatById('non-existent-id'),
          throwsA(isA<ChatNotFoundException>()),
        );
      });
    });

    group('createOneToOneChat', () {
      test('should create one-to-one chat with correct data', () async {
        // Act
        final result = await dataSource.createOneToOneChat(
          currentUserId: ChatFixtures.userId1,
          otherUserId: ChatFixtures.userId2,
          currentUserName: 'User One',
          otherUserName: 'User Two',
          currentUserPhotoUrl: 'https://example.com/user1.jpg',
          otherUserPhotoUrl: 'https://example.com/user2.jpg',
        );

        // Assert
        expect(result, isA<ChatModel>());
        expect(result.type, 'one-to-one');
        expect(result.participants, containsAll([ChatFixtures.userId1, ChatFixtures.userId2]));
        expect(result.participants.length, 2);
        expect(result.admins, isEmpty);
        expect(result.unreadCount[ChatFixtures.userId1], 0);
        expect(result.unreadCount[ChatFixtures.userId2], 0);
      });

      test('should initialize participant details correctly', () async {
        // Act
        final result = await dataSource.createOneToOneChat(
          currentUserId: ChatFixtures.userId1,
          otherUserId: ChatFixtures.userId2,
          currentUserName: 'User One',
          otherUserName: 'User Two',
          currentUserPhotoUrl: 'https://example.com/user1.jpg',
          otherUserPhotoUrl: 'https://example.com/user2.jpg',
        );

        // Assert
        expect(result.participantDetails[ChatFixtures.userId1], isNotNull);
        expect(result.participantDetails[ChatFixtures.userId2], isNotNull);
      });

      test('should set createdBy to current user', () async {
        // Act
        final result = await dataSource.createOneToOneChat(
          currentUserId: ChatFixtures.userId1,
          otherUserId: ChatFixtures.userId2,
          currentUserName: 'User One',
          otherUserName: 'User Two',
        );

        // Assert
        expect(result.createdBy, ChatFixtures.userId1);
      });
    });

    group('createGroupChat', () {
      test('should create group chat with all participants', () async {
        // Act
        final result = await dataSource.createGroupChat(
          createdBy: ChatFixtures.userId3,
          name: 'Test Group',
          description: 'A test group chat',
          photoUrl: 'https://example.com/group.jpg',
          participantIds: [ChatFixtures.userId1, ChatFixtures.userId2, ChatFixtures.userId3],
          participantNames: {
            ChatFixtures.userId1: 'User One',
            ChatFixtures.userId2: 'User Two',
            ChatFixtures.userId3: 'User Three',
          },
          participantPhotos: {
            ChatFixtures.userId1: 'https://example.com/user1.jpg',
            ChatFixtures.userId2: 'https://example.com/user2.jpg',
            ChatFixtures.userId3: null,
          },
        );

        // Assert
        expect(result, isA<ChatModel>());
        expect(result.type, 'group');
        expect(result.name, 'Test Group');
        expect(result.description, 'A test group chat');
        expect(result.participants.length, 3);
        expect(result.admins, [ChatFixtures.userId3]);
      });

      test('should initialize user-specific properties for all participants', () async {
        // Act
        final result = await dataSource.createGroupChat(
          createdBy: ChatFixtures.userId1,
          name: 'Test Group',
          participantIds: [ChatFixtures.userId1, ChatFixtures.userId2],
          participantNames: {
            ChatFixtures.userId1: 'User One',
            ChatFixtures.userId2: 'User Two',
          },
          participantPhotos: {
            ChatFixtures.userId1: null,
            ChatFixtures.userId2: null,
          },
        );

        // Assert
        expect(result.unreadCount[ChatFixtures.userId1], 0);
        expect(result.unreadCount[ChatFixtures.userId2], 0);
        expect(result.isArchived[ChatFixtures.userId1], false);
        expect(result.isPinned[ChatFixtures.userId1], false);
        expect(result.isMuted[ChatFixtures.userId1], false);
      });
    });

    group('updateChatMetadata', () {
      test('should update chat metadata when user is admin', () async {
        // Arrange
        final chatRef = await fakeFirestore
            .collection('chats')
            .add(ChatFixtures.groupChatFirestoreData);

        // Act
        await dataSource.updateChatMetadata(
          chatId: chatRef.id,
          userId: ChatFixtures.userId3, // Admin
          name: 'Updated Group Name',
          description: 'Updated description',
        );

        // Assert
        final doc = await chatRef.get();
        expect(doc.data()!['name'], 'Updated Group Name');
        expect(doc.data()!['description'], 'Updated description');
      });

      test('should throw UnauthorizedChatAccessException when user is not admin', () async {
        // Arrange
        final chatRef = await fakeFirestore
            .collection('chats')
            .add(ChatFixtures.groupChatFirestoreData);

        // Act & Assert
        expect(
          () => dataSource.updateChatMetadata(
            chatId: chatRef.id,
            userId: ChatFixtures.userId1, // Not admin
            name: 'New Name',
          ),
          throwsA(isA<UnauthorizedChatAccessException>()),
        );
      });
    });

    group('addParticipants', () {
      test('should add new participants when user is admin', () async {
        // Arrange
        final chatRef = await fakeFirestore
            .collection('chats')
            .add(ChatFixtures.groupChatFirestoreData);
        const newUserId = 'new-user-id';

        // Act
        await dataSource.addParticipants(
          chatId: chatRef.id,
          adminId: ChatFixtures.userId3,
          participantIds: [newUserId],
          participantNames: {newUserId: 'New User'},
          participantPhotos: {newUserId: null},
        );

        // Assert
        final doc = await chatRef.get();
        final participants = List<String>.from(doc.data()!['participants']);
        expect(participants, contains(newUserId));
      });

      test('should throw UnauthorizedChatAccessException when user is not admin', () async {
        // Arrange
        final chatRef = await fakeFirestore
            .collection('chats')
            .add(ChatFixtures.groupChatFirestoreData);

        // Act & Assert
        expect(
          () => dataSource.addParticipants(
            chatId: chatRef.id,
            adminId: ChatFixtures.userId1, // Not admin
            participantIds: ['new-user'],
            participantNames: {'new-user': 'New'},
            participantPhotos: {'new-user': null},
          ),
          throwsA(isA<UnauthorizedChatAccessException>()),
        );
      });
    });

    group('removeParticipant', () {
      test('should remove participant when user is admin', () async {
        // Arrange
        final chatRef = await fakeFirestore
            .collection('chats')
            .add(ChatFixtures.groupChatFirestoreData);

        // Act
        await dataSource.removeParticipant(
          chatId: chatRef.id,
          adminId: ChatFixtures.userId3,
          participantId: ChatFixtures.userId1,
        );

        // Assert
        final doc = await chatRef.get();
        final participants = List<String>.from(doc.data()!['participants']);
        expect(participants, isNot(contains(ChatFixtures.userId1)));
      });

      test('should throw ValidationException when removing only admin', () async {
        // Arrange
        final singleAdminChat = {
          ...ChatFixtures.groupChatFirestoreData,
          'admins': [ChatFixtures.userId3],
        };
        final chatRef = await fakeFirestore.collection('chats').add(singleAdminChat);

        // Act & Assert
        expect(
          () => dataSource.removeParticipant(
            chatId: chatRef.id,
            adminId: ChatFixtures.userId3,
            participantId: ChatFixtures.userId3,
          ),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('archiveChat', () {
      test('should archive chat for specific user', () async {
        // Arrange
        final chatRef = await fakeFirestore
            .collection('chats')
            .add(ChatFixtures.oneToOneChatFirestoreData);

        // Act
        await dataSource.archiveChat(
          chatId: chatRef.id,
          userId: ChatFixtures.userId1,
          isArchived: true,
        );

        // Assert
        final doc = await chatRef.get();
        expect(doc.data()!['isArchived'][ChatFixtures.userId1], true);
      });
    });

    group('pinChat', () {
      test('should pin chat for specific user', () async {
        // Arrange
        final chatRef = await fakeFirestore
            .collection('chats')
            .add(ChatFixtures.oneToOneChatFirestoreData);

        // Act
        await dataSource.pinChat(
          chatId: chatRef.id,
          userId: ChatFixtures.userId1,
          isPinned: true,
        );

        // Assert
        final doc = await chatRef.get();
        expect(doc.data()!['isPinned'][ChatFixtures.userId1], true);
      });
    });

    group('muteChat', () {
      test('should mute chat for specific user', () async {
        // Arrange
        final chatRef = await fakeFirestore
            .collection('chats')
            .add(ChatFixtures.oneToOneChatFirestoreData);

        // Act
        await dataSource.muteChat(
          chatId: chatRef.id,
          userId: ChatFixtures.userId1,
          isMuted: true,
        );

        // Assert
        final doc = await chatRef.get();
        expect(doc.data()!['isMuted'][ChatFixtures.userId1], true);
      });
    });

    group('deleteChat', () {
      test('should delete chat and messages when user is creator', () async {
        // Arrange
        final chatRef = await fakeFirestore
            .collection('chats')
            .add(ChatFixtures.oneToOneChatFirestoreData);

        // Add some messages
        await chatRef.collection('messages').add({'content': 'Message 1'});
        await chatRef.collection('messages').add({'content': 'Message 2'});

        // Act
        await dataSource.deleteChat(
          chatId: chatRef.id,
          userId: ChatFixtures.userId1, // Creator
        );

        // Assert
        final doc = await chatRef.get();
        expect(doc.exists, false);
      });

      test('should throw UnauthorizedChatAccessException when user is not creator', () async {
        // Arrange
        final chatRef = await fakeFirestore
            .collection('chats')
            .add(ChatFixtures.oneToOneChatFirestoreData);

        // Act & Assert
        expect(
          () => dataSource.deleteChat(
            chatId: chatRef.id,
            userId: ChatFixtures.userId2, // Not creator
          ),
          throwsA(isA<UnauthorizedChatAccessException>()),
        );
      });
    });

    group('findExistingOneToOneChat', () {
      test('should find existing one-to-one chat between two users', () async {
        // Arrange
        await fakeFirestore
            .collection('chats')
            .add(ChatFixtures.oneToOneChatFirestoreData);

        // Act
        final result = await dataSource.findExistingOneToOneChat(
          userId1: ChatFixtures.userId1,
          userId2: ChatFixtures.userId2,
        );

        // Assert
        expect(result, isNotNull);
        expect(result!.type, 'one-to-one');
        expect(result.participants, containsAll([ChatFixtures.userId1, ChatFixtures.userId2]));
      });

      test('should return null when no chat exists', () async {
        // Act
        final result = await dataSource.findExistingOneToOneChat(
          userId1: 'user-a',
          userId2: 'user-b',
        );

        // Assert
        expect(result, isNull);
      });

      test('should not return group chats', () async {
        // Arrange
        await fakeFirestore
            .collection('chats')
            .add(ChatFixtures.groupChatFirestoreData);

        // Act
        final result = await dataSource.findExistingOneToOneChat(
          userId1: ChatFixtures.userId1,
          userId2: ChatFixtures.userId2,
        );

        // Assert
        expect(result, isNull);
      });
    });

    group('leaveChat', () {
      test('should remove user from chat', () async {
        // Arrange
        final chatRef = await fakeFirestore
            .collection('chats')
            .add(ChatFixtures.groupChatFirestoreData);

        // Act
        await dataSource.leaveChat(
          chatId: chatRef.id,
          userId: ChatFixtures.userId1,
        );

        // Assert
        final doc = await chatRef.get();
        final participants = List<String>.from(doc.data()!['participants']);
        expect(participants, isNot(contains(ChatFixtures.userId1)));
      });

      test('should throw ValidationException when only admin leaves', () async {
        // Arrange
        final singleAdminChat = {
          ...ChatFixtures.groupChatFirestoreData,
          'admins': [ChatFixtures.userId3],
        };
        final chatRef = await fakeFirestore.collection('chats').add(singleAdminChat);

        // Act & Assert
        expect(
          () => dataSource.leaveChat(
            chatId: chatRef.id,
            userId: ChatFixtures.userId3,
          ),
          throwsA(isA<ValidationException>()),
        );
      });
    });
  });
}
