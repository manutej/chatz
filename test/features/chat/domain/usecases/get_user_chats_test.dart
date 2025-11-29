import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/features/chat/domain/entities/chat_entity.dart';
import 'package:chatz/features/chat/domain/repositories/chat_repository.dart';
import 'package:chatz/features/chat/domain/usecases/get_user_chats.dart';
import '../../../fixtures/chat_fixtures.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late MockChatRepository mockRepository;
  late GetUserChats useCase;

  setUp(() {
    mockRepository = MockChatRepository();
    useCase = GetUserChats(mockRepository);
  });

  group('GetUserChats', () {
    test('should get chats stream from repository', () async {
      // Arrange
      when(() => mockRepository.getUserChats(any())).thenAnswer(
        (_) => Stream.value(
          Right([ChatFixtures.oneToOneChatEntity, ChatFixtures.groupChatEntity]),
        ),
      );

      // Act
      final stream = useCase(ChatFixtures.userId1);

      // Assert
      await expectLater(
        stream,
        emits(predicate<Either<Failure, List<ChatEntity>>>(
          (either) => either.isRight() && either.getOrElse(() => []).length == 2,
        )),
      );
      verify(() => mockRepository.getUserChats(ChatFixtures.userId1)).called(1);
    });

    test('should emit multiple events for real-time updates', () async {
      // Arrange
      final controller = StreamController<Either<Failure, List<ChatEntity>>>();
      when(() => mockRepository.getUserChats(any())).thenAnswer(
        (_) => controller.stream,
      );

      // Act
      final stream = useCase(ChatFixtures.userId1);

      // Emit multiple updates
      controller.add(Right([ChatFixtures.oneToOneChatEntity]));
      controller.add(Right([
        ChatFixtures.oneToOneChatEntity,
        ChatFixtures.groupChatEntity,
      ]));

      // Assert
      await expectLater(
        stream,
        emitsInOrder([
          predicate<Either<Failure, List<ChatEntity>>>(
            (either) => either.getOrElse(() => []).length == 1,
          ),
          predicate<Either<Failure, List<ChatEntity>>>(
            (either) => either.getOrElse(() => []).length == 2,
          ),
        ]),
      );

      await controller.close();
    });

    test('should emit Left(Failure) on repository error', () async {
      // Arrange
      when(() => mockRepository.getUserChats(any())).thenAnswer(
        (_) => Stream.value(const Left(FirestoreFailure('Database error'))),
      );

      // Act
      final stream = useCase(ChatFixtures.userId1);

      // Assert
      await expectLater(
        stream,
        emits(predicate<Either<Failure, List<ChatEntity>>>(
          (either) => either.isLeft(),
        )),
      );
    });

    test('should handle empty chat list', () async {
      // Arrange
      when(() => mockRepository.getUserChats(any())).thenAnswer(
        (_) => Stream.value(const Right([])),
      );

      // Act
      final stream = useCase(ChatFixtures.userId1);

      // Assert
      await expectLater(
        stream,
        emits(predicate<Either<Failure, List<ChatEntity>>>(
          (either) => either.isRight() && either.getOrElse(() => []).isEmpty,
        )),
      );
    });
  });
}
