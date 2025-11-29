import 'dart:async';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/shared/domain/entities/media_entity.dart';
import 'package:chatz/shared/domain/entities/upload_progress.dart';
import 'package:chatz/shared/domain/repositories/storage_repository.dart';
import 'package:chatz/shared/domain/usecases/upload_file_usecase.dart';

@GenerateMocks([StorageRepository, File])
import 'upload_file_usecase_test.mocks.dart';

void main() {
  late UploadFileUseCase useCase;
  late MockStorageRepository mockRepository;

  setUp(() {
    mockRepository = MockStorageRepository();
    useCase = UploadFileUseCase(mockRepository);
  });

  group('UploadFileUseCase', () {
    final mockFile = MockFile();
    const testPath = 'test/path/image.jpg';
    const downloadUrl = 'https://example.com/image.jpg';

    test('should forward upload progress stream from repository', () async {
      // Arrange
      final controller = StreamController<Either<Failure, UploadProgress>>();
      final uploadId = DateTime.now().millisecondsSinceEpoch.toString();

      when(mockRepository.uploadFile(
        file: anyNamed('file'),
        storagePath: anyNamed('storagePath'),
        mediaType: anyNamed('mediaType'),
        compress: anyNamed('compress'),
        metadata: anyNamed('metadata'),
      )).thenAnswer((_) => controller.stream);

      final params = UploadFileParams(
        file: mockFile,
        storagePath: testPath,
        mediaType: MediaType.image,
      );

      // Act
      final progressStream = useCase(params);

      final progressList = <Either<Failure, UploadProgress>>[];
      final subscription = progressStream.listen(progressList.add);

      // Emit progress
      controller.add(Right(UploadProgress.uploading(
        uploadId,
        bytesTransferred: 500,
        totalBytes: 1000,
      )));
      await Future.delayed(const Duration(milliseconds: 50));

      controller.add(Right(UploadProgress.completed(
        uploadId,
        downloadUrl: downloadUrl,
      )));
      await Future.delayed(const Duration(milliseconds: 50));

      await controller.close();
      await subscription.cancel();

      // Assert
      expect(progressList.length, 2);
      expect(progressList[0].isRight(), true);
      expect(progressList[1].isRight(), true);

      final progress1 = progressList[0].getOrElse(() => throw Exception());
      expect(progress1.status, UploadStatus.uploading);
      expect(progress1.percentage, 50);

      final progress2 = progressList[1].getOrElse(() => throw Exception());
      expect(progress2.status, UploadStatus.completed);
      expect(progress2.downloadUrl, downloadUrl);

      verify(mockRepository.uploadFile(
        file: mockFile,
        storagePath: testPath,
        mediaType: MediaType.image,
        compress: true,
        metadata: null,
      )).called(1);
    });

    test('should use custom compress setting from params', () async {
      // Arrange
      final controller = StreamController<Either<Failure, UploadProgress>>();

      when(mockRepository.uploadFile(
        file: anyNamed('file'),
        storagePath: anyNamed('storagePath'),
        mediaType: anyNamed('mediaType'),
        compress: anyNamed('compress'),
        metadata: anyNamed('metadata'),
      )).thenAnswer((_) => controller.stream);

      final params = UploadFileParams(
        file: mockFile,
        storagePath: testPath,
        mediaType: MediaType.image,
        compress: false,
      );

      // Act
      final progressStream = useCase(params);
      final subscription = progressStream.listen((_) {});

      await Future.delayed(const Duration(milliseconds: 50));
      await controller.close();
      await subscription.cancel();

      // Assert
      verify(mockRepository.uploadFile(
        file: mockFile,
        storagePath: testPath,
        mediaType: MediaType.image,
        compress: false,
        metadata: null,
      )).called(1);
    });

    test('should include custom metadata from params', () async {
      // Arrange
      final controller = StreamController<Either<Failure, UploadProgress>>();
      const metadata = {'userId': 'user123', 'chatId': 'chat456'};

      when(mockRepository.uploadFile(
        file: anyNamed('file'),
        storagePath: anyNamed('storagePath'),
        mediaType: anyNamed('mediaType'),
        compress: anyNamed('compress'),
        metadata: anyNamed('metadata'),
      )).thenAnswer((_) => controller.stream);

      final params = UploadFileParams(
        file: mockFile,
        storagePath: testPath,
        mediaType: MediaType.video,
        metadata: metadata,
      );

      // Act
      final progressStream = useCase(params);
      final subscription = progressStream.listen((_) {});

      await Future.delayed(const Duration(milliseconds: 50));
      await controller.close();
      await subscription.cancel();

      // Assert
      verify(mockRepository.uploadFile(
        file: mockFile,
        storagePath: testPath,
        mediaType: MediaType.video,
        compress: true,
        metadata: metadata,
      )).called(1);
    });

    test('should emit failure when upload fails', () async {
      // Arrange
      final controller = StreamController<Either<Failure, UploadProgress>>();

      when(mockRepository.uploadFile(
        file: anyNamed('file'),
        storagePath: anyNamed('storagePath'),
        mediaType: anyNamed('mediaType'),
        compress: anyNamed('compress'),
        metadata: anyNamed('metadata'),
      )).thenAnswer((_) => controller.stream);

      final params = UploadFileParams(
        file: mockFile,
        storagePath: testPath,
        mediaType: MediaType.image,
      );

      // Act
      final progressStream = useCase(params);

      final progressList = <Either<Failure, UploadProgress>>[];
      final subscription = progressStream.listen(progressList.add);

      // Emit failure
      controller.add(const Left(MediaUploadFailure('Upload failed')));
      await Future.delayed(const Duration(milliseconds: 50));

      await controller.close();
      await subscription.cancel();

      // Assert
      expect(progressList.length, 1);
      expect(progressList[0].isLeft(), true);
      final failure = progressList[0].fold((l) => l, (r) => throw Exception());
      expect(failure, isA<MediaUploadFailure>());
    });

    test('should handle different media types correctly', () async {
      // Arrange
      final controller = StreamController<Either<Failure, UploadProgress>>();

      when(mockRepository.uploadFile(
        file: anyNamed('file'),
        storagePath: anyNamed('storagePath'),
        mediaType: anyNamed('mediaType'),
        compress: anyNamed('compress'),
        metadata: anyNamed('metadata'),
      )).thenAnswer((_) => controller.stream);

      // Test each media type
      final mediaTypes = [
        MediaType.image,
        MediaType.video,
        MediaType.audio,
        MediaType.document,
        MediaType.voice,
        MediaType.gif,
      ];

      for (final mediaType in mediaTypes) {
        final params = UploadFileParams(
          file: mockFile,
          storagePath: testPath,
          mediaType: mediaType,
        );

        // Act
        final progressStream = useCase(params);
        final subscription = progressStream.listen((_) {});

        await Future.delayed(const Duration(milliseconds: 10));
        await subscription.cancel();

        // Assert
        verify(mockRepository.uploadFile(
          file: mockFile,
          storagePath: testPath,
          mediaType: mediaType,
          compress: true,
          metadata: null,
        )).called(1);
      }

      await controller.close();
    });
  });

  group('UploadFileParams', () {
    final mockFile = MockFile();

    test('should create params with required fields', () {
      // Act
      const params = UploadFileParams(
        file: File('test.jpg'),
        storagePath: 'path/to/file.jpg',
        mediaType: MediaType.image,
      );

      // Assert
      expect(params.file.path, 'test.jpg');
      expect(params.storagePath, 'path/to/file.jpg');
      expect(params.mediaType, MediaType.image);
      expect(params.compress, true); // Default value
      expect(params.metadata, null); // Default value
    });

    test('should create params with custom compress setting', () {
      // Act
      const params = UploadFileParams(
        file: File('test.jpg'),
        storagePath: 'path/to/file.jpg',
        mediaType: MediaType.image,
        compress: false,
      );

      // Assert
      expect(params.compress, false);
    });

    test('should create params with custom metadata', () {
      // Arrange
      const metadata = {'userId': 'user123'};

      // Act
      const params = UploadFileParams(
        file: File('test.jpg'),
        storagePath: 'path/to/file.jpg',
        mediaType: MediaType.image,
        metadata: metadata,
      );

      // Assert
      expect(params.metadata, metadata);
    });
  });
}
