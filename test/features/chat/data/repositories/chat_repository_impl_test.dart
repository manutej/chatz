import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:chatz/core/errors/exceptions.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:chatz/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:chatz/features/chat/domain/entities/chat_entity.dart';
import '../../fixtures/chat_fixtures.dart';

class MockChatRemoteDataSource extends Mock implements ChatRemoteDataSource {}

void main() {
  late MockChatRemoteDataSource mockDataSource;
  late ChatRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockChatRemoteDataSource();
    repository = ChatRepositoryImpl(mockDataSource);
  });

  group('getUserChats', () {
    test('should return stream of Right(List<ChatEntity>) on success', () async {
      // Arrange
      when(() => mockDataSource.getUserChats(any())).thenAnswer(
        (_) => Stream.value([ChatFixtures.oneToOneChatModel]),
      );

      // Act
      final stream = repository.getUserChats(ChatFixtures.userId1);

      // Assert
      await expectLater(
        stream,
        emits(predicate<Either<Failure, List<ChatEntity>>>(
          (either) => either.isRight() && either.getOrElse(() => []).isNotEmpty,
        )),
      );
      verify(() => mockDataSource.getUserChats(ChatFixtures.userId1)).called(1);
    });

    test('should return stream of Left(FirestoreFailure) on FirestoreException', () async {
      // Arrange
      when(() => mockDataSource.getUserChats(any())).thenAnswer(
        (_) => Stream.error(const FirestoreException('Database error')),
      );

      // Act
      final stream = repository.getUserChats(ChatFixtures.userId1);

      // Assert
      await expectLater(
        stream,
        emits(predicate<Either<Failure, List<ChatEntity>>>(
          (either) => either.isLeft(),
        )),
      );
    });

    test('should map models to entities correctly', () async {
      // Arrange
      when(() => mockDataSource.getUserChats(any())).thenAnswer(
        (_) => Stream.value([
          ChatFixtures.oneToOneChatModel,
          ChatFixtures.groupChatModel,
        ]),
      );

      // Act
      final stream = repository.getUserChats(ChatFixtures.userId1);

      // Assert
      await expectLater(
        stream,
        emits(predicate<Either<Failure, List<ChatEntity>>>((either) {
          final chats = either.getOrElse(() => []);
          return chats.length == 2 &&
              chats[0].type == ChatType.oneToOne &&
              chats[1].type == ChatType.group;
        })),
      );
    });
  });

  group('getChatById', () {
    test('should return Right(ChatEntity) on success', () async {
      // Arrange
      when(() => mockDataSource.getChatById(any()))
          .thenAnswer((_) async => ChatFixtures.oneToOneChatModel);

      // Act
      final result = await repository.getChatById(ChatFixtures.oneToOneChatId);

      // Assert
      expect(result, isA<Right<Failure, ChatEntity>>());
      expect(result.getOrElse(() => throw Exception()), isA<ChatEntity>());
      verify(() => mockDataSource.getChatById(ChatFixtures.oneToOneChatId)).called(1);
    });

    test('should return Left(ChatNotFoundFailure) on ChatNotFoundException', () async {
      // Arrange
      when(() => mockDataSource.getChatById(any()))
          .thenThrow(const ChatNotFoundException());

      // Act
      final result = await repository.getChatById('non-existent');

      // Assert
      expect(result, isA<Left<Failure, ChatEntity>>());
      expect(result.fold((l) => l, (_) => null), isA<ChatNotFoundFailure>());
    });
  });

  group('createOneToOneChat', () {
    test('should return Right(ChatEntity) on success', () async {
      // Arrange
      when(() => mockDataSource.createOneToOneChat(
            currentUserId: any(named: 'currentUserId'),
            otherUserId: any(named: 'otherUserId'),
            currentUserName: any(named: 'currentUserName'),
            otherUserName: any(named: 'otherUserName'),
            currentUserPhotoUrl: any(named: 'currentUserPhotoUrl'),
            otherUserPhotoUrl: any(named: 'otherUserPhotoUrl'),
          )).thenAnswer((_) async => ChatFixtures.oneToOneChatModel);

      // Act
      final result = await repository.createOneToOneChat(
        currentUserId: ChatFixtures.userId1,
        otherUserId: ChatFixtures.userId2,
        currentUserName: 'User One',
        otherUserName: 'User Two',
      );

      // Assert
      expect(result, isA<Right<Failure, ChatEntity>>());
    });

    test('should return Left(FirestoreFailure) on FirestoreException', () async {
      // Arrange
      when(() => mockDataSource.createOneToOneChat(
            currentUserId: any(named: 'currentUserId'),
            otherUserId: any(named: 'otherUserId'),
            currentUserName: any(named: 'currentUserName'),
            otherUserName: any(named: 'otherUserName'),
            currentUserPhotoUrl: any(named: 'currentUserPhotoUrl'),
            otherUserPhotoUrl: any(named: 'otherUserPhotoUrl'),
          )).thenThrow(const FirestoreException('Creation failed'));

      // Act
      final result = await repository.createOneToOneChat(
        currentUserId: ChatFixtures.userId1,
        otherUserId: ChatFixtures.userId2,
        currentUserName: 'User One',
        otherUserName: 'User Two',
      );

      // Assert
      expect(result, isA<Left<Failure, ChatEntity>>());
      expect(result.fold((l) => l, (_) => null), isA<FirestoreFailure>());
    });
  });

  group('createGroupChat', () {
    test('should return Right(ChatEntity) on success', () async {
      // Arrange
      when(() => mockDataSource.createGroupChat(
            createdBy: any(named: 'createdBy'),
            name: any(named: 'name'),
            description: any(named: 'description'),
            photoUrl: any(named: 'photoUrl'),
            participantIds: any(named: 'participantIds'),
            participantNames: any(named: 'participantNames'),
            participantPhotos: any(named: 'participantPhotos'),
          )).thenAnswer((_) async => ChatFixtures.groupChatModel);

      // Act
      final result = await repository.createGroupChat(
        createdBy: ChatFixtures.userId1,
        name: 'Test Group',
        participantIds: [ChatFixtures.userId1, ChatFixtures.userId2],
        participantNames: {
          ChatFixtures.userId1: 'User One',
          ChatFixtures.userId2: 'User Two',
        },
        participantPhotos: {},
      );

      // Assert
      expect(result, isA<Right<Failure, ChatEntity>>());
    });
  });

  group('archiveChat', () {
    test('should return Right(void) on success', () async {
      // Arrange
      when(() => mockDataSource.archiveChat(
            chatId: any(named: 'chatId'),
            userId: any(named: 'userId'),
            isArchived: any(named: 'isArchived'),
          )).thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.archiveChat(
        chatId: ChatFixtures.oneToOneChatId,
        userId: ChatFixtures.userId1,
        isArchived: true,
      );

      // Assert
      expect(result, isA<Right<Failure, void>>());
    });
  });

  group('pinChat', () {
    test('should return Right(void) on success', () async {
      // Arrange
      when(() => mockDataSource.pinChat(
            chatId: any(named: 'chatId'),
            userId: any(named: 'userId'),
            isPinned: any(named: 'isPinned'),
          )).thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.pinChat(
        chatId: ChatFixtures.oneToOneChatId,
        userId: ChatFixtures.userId1,
        isPinned: true,
      );

      // Assert
      expect(result, isA<Right<Failure, void>>());
    });
  });

  group('muteChat', () {
    test('should return Right(void) on success', () async {
      // Arrange
      when(() => mockDataSource.muteChat(
            chatId: any(named: 'chatId'),
            userId: any(named: 'userId'),
            isMuted: any(named: 'isMuted'),
          )).thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.muteChat(
        chatId: ChatFixtures.oneToOneChatId,
        userId: ChatFixtures.userId1,
        isMuted: true,
      );

      // Assert
      expect(result, isA<Right<Failure, void>>());
    });
  });

  group('getOrCreateOneToOneChat', () {
    test('should return existing chat if found', () async {
      // Arrange
      when(() => mockDataSource.findExistingOneToOneChat(
            userId1: any(named: 'userId1'),
            userId2: any(named: 'userId2'),
          )).thenAnswer((_) async => ChatFixtures.oneToOneChatModel);

      // Act
      final result = await repository.getOrCreateOneToOneChat(
        currentUserId: ChatFixtures.userId1,
        otherUserId: ChatFixtures.userId2,
        currentUserName: 'User One',
        otherUserName: 'User Two',
      );

      // Assert
      expect(result, isA<Right<Failure, ChatEntity>>());
      verify(() => mockDataSource.findExistingOneToOneChat(
            userId1: any(named: 'userId1'),
            userId2: any(named: 'userId2'),
          )).called(1);
      verifyNever(() => mockDataSource.createOneToOneChat(
            currentUserId: any(named: 'currentUserId'),
            otherUserId: any(named: 'otherUserId'),
            currentUserName: any(named: 'currentUserName'),
            otherUserName: any(named: 'otherUserName'),
            currentUserPhotoUrl: any(named: 'currentUserPhotoUrl'),
            otherUserPhotoUrl: any(named: 'otherUserPhotoUrl'),
          ));
    });

    test('should create new chat if not found', () async {
      // Arrange
      when(() => mockDataSource.findExistingOneToOneChat(
            userId1: any(named: 'userId1'),
            userId2: any(named: 'userId2'),
          )).thenAnswer((_) async => null);

      when(() => mockDataSource.createOneToOneChat(
            currentUserId: any(named: 'currentUserId'),
            otherUserId: any(named: 'otherUserId'),
            currentUserName: any(named: 'currentUserName'),
            otherUserName: any(named: 'otherUserName'),
            currentUserPhotoUrl: any(named: 'currentUserPhotoUrl'),
            otherUserPhotoUrl: any(named: 'otherUserPhotoUrl'),
          )).thenAnswer((_) async => ChatFixtures.oneToOneChatModel);

      // Act
      final result = await repository.getOrCreateOneToOneChat(
        currentUserId: ChatFixtures.userId1,
        otherUserId: ChatFixtures.userId2,
        currentUserName: 'User One',
        otherUserName: 'User Two',
      );

      // Assert
      expect(result, isA<Right<Failure, ChatEntity>>());
      verify(() => mockDataSource.findExistingOneToOneChat(
            userId1: any(named: 'userId1'),
            userId2: any(named: 'userId2'),
          )).called(1);
      verify(() => mockDataSource.createOneToOneChat(
            currentUserId: any(named: 'currentUserId'),
            otherUserId: any(named: 'otherUserId'),
            currentUserName: any(named: 'currentUserName'),
            otherUserName: any(named: 'otherUserName'),
            currentUserPhotoUrl: any(named: 'currentUserPhotoUrl'),
            otherUserPhotoUrl: any(named: 'otherUserPhotoUrl'),
          )).called(1);
    });
  });

  group('error handling', () {
    test('should map NetworkException to NetworkFailure', () async {
      // Arrange
      when(() => mockDataSource.getChatById(any()))
          .thenThrow(const NetworkException('No connection'));

      // Act
      final result = await repository.getChatById('chat-id');

      // Assert
      expect(result.fold((l) => l, (_) => null), isA<NetworkFailure>());
    });

    test('should map ValidationException to ValidationFailure', () async {
      // Arrange
      when(() => mockDataSource.updateChatMetadata(
            chatId: any(named: 'chatId'),
            userId: any(named: 'userId'),
            name: any(named: 'name'),
          )).thenThrow(const ValidationException('Invalid data'));

      // Act
      final result = await repository.updateChatMetadata(
        chatId: 'chat-id',
        userId: 'user-id',
        name: 'New Name',
      );

      // Assert
      expect(result.fold((l) => l, (_) => null), isA<ValidationFailure>());
    });

    test('should map UnauthorizedChatAccessException to UnauthorizedChatAccessFailure', () async {
      // Arrange
      when(() => mockDataSource.deleteChat(
            chatId: any(named: 'chatId'),
            userId: any(named: 'userId'),
          )).thenThrow(const UnauthorizedChatAccessException('Access denied'));

      // Act
      final result = await repository.deleteChat(
        chatId: 'chat-id',
        userId: 'user-id',
      );

      // Assert
      expect(result.fold((l) => l, (_) => null), isA<UnauthorizedChatAccessFailure>());
    });

    test('should map unknown exceptions to UnknownFailure', () async {
      // Arrange
      when(() => mockDataSource.getChatById(any())).thenThrow(Exception('Unknown'));

      // Act
      final result = await repository.getChatById('chat-id');

      // Assert
      expect(result.fold((l) => l, (_) => null), isA<UnknownFailure>());
    });
  });
}
