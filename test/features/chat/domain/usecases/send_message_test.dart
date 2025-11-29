import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/features/chat/domain/entities/message_entity.dart';
import 'package:chatz/features/chat/domain/repositories/message_repository.dart';
import 'package:chatz/features/chat/domain/usecases/send_message.dart';
import '../../../fixtures/message_fixtures.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

void main() {
  late MockMessageRepository mockRepository;
  late SendMessage useCase;

  setUp(() {
    mockRepository = MockMessageRepository();
    useCase = SendMessage(mockRepository);
  });

  group('SendMessage', () {
    const testParams = SendMessageParams(
      chatId: MessageFixtures.chatId,
      senderId: MessageFixtures.senderId,
      senderName: 'Sender Name',
      content: 'Test message',
      type: MessageType.text,
    );

    test('should send text message through repository', () async {
      // Arrange
      when(() => mockRepository.sendMessage(
            chatId: any(named: 'chatId'),
            senderId: any(named: 'senderId'),
            senderName: any(named: 'senderName'),
            senderPhotoUrl: any(named: 'senderPhotoUrl'),
            content: any(named: 'content'),
            type: any(named: 'type'),
            mediaUrl: any(named: 'mediaUrl'),
            mediaMetadata: any(named: 'mediaMetadata'),
            replyToMessageId: any(named: 'replyToMessageId'),
            replyToContent: any(named: 'replyToContent'),
            replyToSenderName: any(named: 'replyToSenderName'),
          )).thenAnswer((_) async => Right(MessageFixtures.textMessageEntity));

      // Act
      final result = await useCase(testParams);

      // Assert
      expect(result, isA<Right<Failure, MessageEntity>>());
      expect(
        result.getOrElse(() => throw Exception()),
        MessageFixtures.textMessageEntity,
      );
      verify(() => mockRepository.sendMessage(
            chatId: testParams.chatId,
            senderId: testParams.senderId,
            senderName: testParams.senderName,
            senderPhotoUrl: testParams.senderPhotoUrl,
            content: testParams.content,
            type: testParams.type,
            mediaUrl: testParams.mediaUrl,
            mediaMetadata: testParams.mediaMetadata,
            replyToMessageId: testParams.replyToMessageId,
            replyToContent: testParams.replyToContent,
            replyToSenderName: testParams.replyToSenderName,
          )).called(1);
    });

    test('should send image message with media metadata', () async {
      // Arrange
      const imageParams = SendMessageParams(
        chatId: MessageFixtures.chatId,
        senderId: MessageFixtures.senderId,
        senderName: 'Sender',
        content: 'Image message',
        type: MessageType.image,
        mediaUrl: 'https://example.com/image.jpg',
        mediaMetadata: {'fileName': 'image.jpg', 'fileSize': 1024},
      );

      when(() => mockRepository.sendMessage(
            chatId: any(named: 'chatId'),
            senderId: any(named: 'senderId'),
            senderName: any(named: 'senderName'),
            senderPhotoUrl: any(named: 'senderPhotoUrl'),
            content: any(named: 'content'),
            type: any(named: 'type'),
            mediaUrl: any(named: 'mediaUrl'),
            mediaMetadata: any(named: 'mediaMetadata'),
            replyToMessageId: any(named: 'replyToMessageId'),
            replyToContent: any(named: 'replyToContent'),
            replyToSenderName: any(named: 'replyToSenderName'),
          )).thenAnswer((_) async => Right(MessageFixtures.imageMessageEntity));

      // Act
      final result = await useCase(imageParams);

      // Assert
      expect(result, isA<Right<Failure, MessageEntity>>());
      verify(() => mockRepository.sendMessage(
            chatId: imageParams.chatId,
            senderId: imageParams.senderId,
            senderName: imageParams.senderName,
            senderPhotoUrl: imageParams.senderPhotoUrl,
            content: imageParams.content,
            type: imageParams.type,
            mediaUrl: imageParams.mediaUrl,
            mediaMetadata: imageParams.mediaMetadata,
            replyToMessageId: null,
            replyToContent: null,
            replyToSenderName: null,
          )).called(1);
    });

    test('should send reply message with reply metadata', () async {
      // Arrange
      const replyParams = SendMessageParams(
        chatId: MessageFixtures.chatId,
        senderId: MessageFixtures.receiverId,
        senderName: 'Receiver',
        content: 'Reply message',
        type: MessageType.text,
        replyToMessageId: 'original-msg-id',
        replyToContent: 'Original content',
        replyToSenderName: 'Original Sender',
      );

      when(() => mockRepository.sendMessage(
            chatId: any(named: 'chatId'),
            senderId: any(named: 'senderId'),
            senderName: any(named: 'senderName'),
            senderPhotoUrl: any(named: 'senderPhotoUrl'),
            content: any(named: 'content'),
            type: any(named: 'type'),
            mediaUrl: any(named: 'mediaUrl'),
            mediaMetadata: any(named: 'mediaMetadata'),
            replyToMessageId: any(named: 'replyToMessageId'),
            replyToContent: any(named: 'replyToContent'),
            replyToSenderName: any(named: 'replyToSenderName'),
          )).thenAnswer((_) async => Right(MessageFixtures.replyMessageEntity));

      // Act
      final result = await useCase(replyParams);

      // Assert
      expect(result, isA<Right<Failure, MessageEntity>>());
    });

    test('should return Left(Failure) on repository error', () async {
      // Arrange
      when(() => mockRepository.sendMessage(
            chatId: any(named: 'chatId'),
            senderId: any(named: 'senderId'),
            senderName: any(named: 'senderName'),
            senderPhotoUrl: any(named: 'senderPhotoUrl'),
            content: any(named: 'content'),
            type: any(named: 'type'),
            mediaUrl: any(named: 'mediaUrl'),
            mediaMetadata: any(named: 'mediaMetadata'),
            replyToMessageId: any(named: 'replyToMessageId'),
            replyToContent: any(named: 'replyToContent'),
            replyToSenderName: any(named: 'replyToSenderName'),
          )).thenAnswer((_) async => const Left(FirestoreFailure('Send failed')));

      // Act
      final result = await useCase(testParams);

      // Assert
      expect(result, isA<Left<Failure, MessageEntity>>());
      expect(result.fold((l) => l, (_) => null), isA<FirestoreFailure>());
    });
  });
}
