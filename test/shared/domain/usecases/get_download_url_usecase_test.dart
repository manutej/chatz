import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/shared/domain/repositories/storage_repository.dart';
import 'package:chatz/shared/domain/usecases/get_download_url_usecase.dart';

@GenerateMocks([StorageRepository])
import 'get_download_url_usecase_test.mocks.dart';

void main() {
  late GetDownloadUrlUseCase useCase;
  late MockStorageRepository mockRepository;

  setUp(() {
    mockRepository = MockStorageRepository();
    useCase = GetDownloadUrlUseCase(mockRepository);
  });

  group('GetDownloadUrlUseCase', () {
    const testPath = 'test/path/file.jpg';
    const downloadUrl = 'https://example.com/download-url.jpg';

    test('should get download URL successfully', () async {
      // Arrange
      when(mockRepository.getDownloadUrl(storagePath: anyNamed('storagePath')))
          .thenAnswer((_) async => const Right(downloadUrl));

      // Act
      final result = await useCase(testPath);

      // Assert
      expect(result.isRight(), true);
      expect(result.getOrElse(() => ''), downloadUrl);
      verify(mockRepository.getDownloadUrl(storagePath: testPath)).called(1);
    });

    test('should return NotFoundFailure when file not found', () async {
      // Arrange
      when(mockRepository.getDownloadUrl(storagePath: anyNamed('storagePath')))
          .thenAnswer((_) async => const Left(NotFoundFailure('File not found')));

      // Act
      final result = await useCase(testPath);

      // Assert
      expect(result.isLeft(), true);
      final failure = result.fold((l) => l, (r) => throw Exception());
      expect(failure, isA<NotFoundFailure>());
      expect(failure.message, 'File not found');
    });

    test('should return NetworkFailure on network error', () async {
      // Arrange
      when(mockRepository.getDownloadUrl(storagePath: anyNamed('storagePath')))
          .thenAnswer((_) async => const Left(NetworkFailure('Network error')));

      // Act
      final result = await useCase(testPath);

      // Assert
      expect(result.isLeft(), true);
      final failure = result.fold((l) => l, (r) => throw Exception());
      expect(failure, isA<NetworkFailure>());
    });

    test('should return MediaUploadFailure on upload error', () async {
      // Arrange
      when(mockRepository.getDownloadUrl(storagePath: anyNamed('storagePath')))
          .thenAnswer(
        (_) async => const Left(MediaUploadFailure('Failed to get URL')),
      );

      // Act
      final result = await useCase(testPath);

      // Assert
      expect(result.isLeft(), true);
      final failure = result.fold((l) => l, (r) => throw Exception());
      expect(failure, isA<MediaUploadFailure>());
    });

    test('should handle different file paths correctly', () async {
      // Arrange
      final testCases = {
        'profile_images/user123/avatar.jpg': 'https://example.com/profile.jpg',
        'chat_media/chat456/images/msg789.jpg': 'https://example.com/chat.jpg',
        'status_media/user123/status456.jpg': 'https://example.com/status.jpg',
      };

      for (final entry in testCases.entries) {
        when(mockRepository.getDownloadUrl(storagePath: entry.key))
            .thenAnswer((_) async => Right(entry.value));

        // Act
        final result = await useCase(entry.key);

        // Assert
        expect(result.isRight(), true);
        expect(result.getOrElse(() => ''), entry.value);
      }
    });

    test('should handle special characters in path', () async {
      // Arrange
      const specialPath = 'test/path with spaces/file (1).jpg';
      const expectedUrl = 'https://example.com/special-file.jpg';

      when(mockRepository.getDownloadUrl(storagePath: specialPath))
          .thenAnswer((_) async => const Right(expectedUrl));

      // Act
      final result = await useCase(specialPath);

      // Assert
      expect(result.isRight(), true);
      expect(result.getOrElse(() => ''), expectedUrl);
    });

    test('should handle empty path gracefully', () async {
      // Arrange
      when(mockRepository.getDownloadUrl(storagePath: ''))
          .thenAnswer(
        (_) async => const Left(ValidationFailure('Invalid path')),
      );

      // Act
      final result = await useCase('');

      // Assert
      expect(result.isLeft(), true);
    });
  });
}
