import 'dart:async';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chatz/core/errors/exceptions.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/shared/data/repositories/storage_repository_impl.dart';
import 'package:chatz/shared/data/datasources/storage_remote_data_source.dart';
import 'package:chatz/shared/domain/entities/media_entity.dart';
import 'package:chatz/shared/domain/entities/upload_progress.dart';

@GenerateMocks([StorageRemoteDataSource, File])
import 'storage_repository_impl_test.mocks.dart';

void main() {
  late StorageRepositoryImpl repository;
  late MockStorageRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockStorageRemoteDataSource();
    repository = StorageRepositoryImpl(mockDataSource);
  });

  group('StorageRepositoryImpl', () {
    group('uploadFile', () {
      final mockFile = MockFile();
      const testPath = 'test/path/image.jpg';
      const downloadUrl = 'https://example.com/image.jpg';

      test('should forward upload progress from data source', () async {
        // Arrange
        final controller = StreamController<UploadProgress>();
        final uploadId = DateTime.now().millisecondsSinceEpoch.toString();

        when(mockDataSource.uploadMedia(
          file: anyNamed('file'),
          storagePath: anyNamed('storagePath'),
          mediaType: anyNamed('mediaType'),
          compress: anyNamed('compress'),
          metadata: anyNamed('metadata'),
        )).thenAnswer((_) => controller.stream);

        // Act
        final progressStream = repository.uploadFile(
          file: mockFile,
          storagePath: testPath,
          mediaType: MediaType.image,
        );

        final progressList = <Either<Failure, UploadProgress>>[];
        final subscription = progressStream.listen(progressList.add);

        // Emit progress
        controller.add(UploadProgress.uploading(
          uploadId,
          bytesTransferred: 500,
          totalBytes: 1000,
        ));
        await Future.delayed(const Duration(milliseconds: 50));

        controller.add(UploadProgress.completed(
          uploadId,
          downloadUrl: downloadUrl,
        ));
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
      });

      test('should return MediaUploadFailure on MediaUploadException', () async {
        // Arrange
        final controller = StreamController<UploadProgress>();

        when(mockDataSource.uploadMedia(
          file: anyNamed('file'),
          storagePath: anyNamed('storagePath'),
          mediaType: anyNamed('mediaType'),
          compress: anyNamed('compress'),
          metadata: anyNamed('metadata'),
        )).thenAnswer((_) {
          controller.addError(const MediaUploadException('Upload failed'));
          return controller.stream;
        });

        // Act
        final progressStream = repository.uploadFile(
          file: mockFile,
          storagePath: testPath,
          mediaType: MediaType.image,
        );

        final progressList = <Either<Failure, UploadProgress>>[];
        final subscription = progressStream.listen(
          progressList.add,
          onError: (_) {}, // Ignore errors
        );

        await Future.delayed(const Duration(milliseconds: 50));
        await controller.close();
        await subscription.cancel();

        // Assert
        expect(progressList.length, 1);
        expect(progressList[0].isLeft(), true);
        final failure = progressList[0].fold((l) => l, (r) => throw Exception());
        expect(failure, isA<MediaUploadFailure>());
      });

      test('should return NetworkFailure on NetworkException', () async {
        // Arrange
        final controller = StreamController<UploadProgress>();

        when(mockDataSource.uploadMedia(
          file: anyNamed('file'),
          storagePath: anyNamed('storagePath'),
          mediaType: anyNamed('mediaType'),
          compress: anyNamed('compress'),
          metadata: anyNamed('metadata'),
        )).thenAnswer((_) {
          controller.addError(const NetworkException('Network error'));
          return controller.stream;
        });

        // Act
        final progressStream = repository.uploadFile(
          file: mockFile,
          storagePath: testPath,
          mediaType: MediaType.image,
        );

        final progressList = <Either<Failure, UploadProgress>>[];
        final subscription = progressStream.listen(
          progressList.add,
          onError: (_) {},
        );

        await Future.delayed(const Duration(milliseconds: 50));
        await controller.close();
        await subscription.cancel();

        // Assert
        expect(progressList.length, 1);
        expect(progressList[0].isLeft(), true);
        final failure = progressList[0].fold((l) => l, (r) => throw Exception());
        expect(failure, isA<NetworkFailure>());
      });

      test('should return PermissionFailure on PermissionException', () async {
        // Arrange
        final controller = StreamController<UploadProgress>();

        when(mockDataSource.uploadMedia(
          file: anyNamed('file'),
          storagePath: anyNamed('storagePath'),
          mediaType: anyNamed('mediaType'),
          compress: anyNamed('compress'),
          metadata: anyNamed('metadata'),
        )).thenAnswer((_) {
          controller.addError(const PermissionException('Permission denied'));
          return controller.stream;
        });

        // Act
        final progressStream = repository.uploadFile(
          file: mockFile,
          storagePath: testPath,
          mediaType: MediaType.image,
        );

        final progressList = <Either<Failure, UploadProgress>>[];
        final subscription = progressStream.listen(
          progressList.add,
          onError: (_) {},
        );

        await Future.delayed(const Duration(milliseconds: 50));
        await controller.close();
        await subscription.cancel();

        // Assert
        expect(progressList.length, 1);
        expect(progressList[0].isLeft(), true);
        final failure = progressList[0].fold((l) => l, (r) => throw Exception());
        expect(failure, isA<PermissionFailure>());
      });
    });

    group('uploadMultipleFiles', () {
      test('should return ValidationFailure when files and paths mismatch',
          () async {
        // Arrange
        final files = [MockFile(), MockFile()];
        final paths = ['path1.jpg']; // Mismatch: 2 files, 1 path

        // Act
        final progressStream = repository.uploadMultipleFiles(
          files: files,
          storagePaths: paths,
          mediaType: MediaType.image,
        );

        final result = await progressStream.first;

        // Assert
        expect(result.isLeft(), true);
        final failure = result.fold((l) => l, (r) => throw Exception());
        expect(failure, isA<ValidationFailure>());
      });
    });

    group('getDownloadUrl', () {
      const testPath = 'test/path/file.jpg';
      const downloadUrl = 'https://example.com/download-url';

      test('should return download URL on success', () async {
        // Arrange
        when(mockDataSource.getDownloadUrl(testPath))
            .thenAnswer((_) async => downloadUrl);

        // Act
        final result = await repository.getDownloadUrl(storagePath: testPath);

        // Assert
        expect(result.isRight(), true);
        expect(result.getOrElse(() => ''), downloadUrl);
        verify(mockDataSource.getDownloadUrl(testPath)).called(1);
      });

      test('should return NotFoundFailure when file not found', () async {
        // Arrange
        when(mockDataSource.getDownloadUrl(testPath))
            .thenThrow(const NotFoundException('File not found'));

        // Act
        final result = await repository.getDownloadUrl(storagePath: testPath);

        // Assert
        expect(result.isLeft(), true);
        final failure = result.fold((l) => l, (r) => throw Exception());
        expect(failure, isA<NotFoundFailure>());
      });

      test('should return NetworkFailure on NetworkException', () async {
        // Arrange
        when(mockDataSource.getDownloadUrl(testPath))
            .thenThrow(const NetworkException('Network error'));

        // Act
        final result = await repository.getDownloadUrl(storagePath: testPath);

        // Assert
        expect(result.isLeft(), true);
        final failure = result.fold((l) => l, (r) => throw Exception());
        expect(failure, isA<NetworkFailure>());
      });

      test('should return MediaUploadFailure on MediaUploadException', () async {
        // Arrange
        when(mockDataSource.getDownloadUrl(testPath))
            .thenThrow(const MediaUploadException('Upload error'));

        // Act
        final result = await repository.getDownloadUrl(storagePath: testPath);

        // Assert
        expect(result.isLeft(), true);
        final failure = result.fold((l) => l, (r) => throw Exception());
        expect(failure, isA<MediaUploadFailure>());
      });
    });

    group('deleteFile', () {
      const testPath = 'test/path/file.jpg';

      test('should delete file successfully', () async {
        // Arrange
        when(mockDataSource.deleteMedia(testPath))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.deleteFile(storagePath: testPath);

        // Assert
        expect(result.isRight(), true);
        verify(mockDataSource.deleteMedia(testPath)).called(1);
      });

      test('should return success when file not found', () async {
        // Arrange
        when(mockDataSource.deleteMedia(testPath))
            .thenThrow(const NotFoundException('File not found'));

        // Act
        final result = await repository.deleteFile(storagePath: testPath);

        // Assert - should still be success
        expect(result.isRight(), true);
      });

      test('should return NetworkFailure on NetworkException', () async {
        // Arrange
        when(mockDataSource.deleteMedia(testPath))
            .thenThrow(const NetworkException('Network error'));

        // Act
        final result = await repository.deleteFile(storagePath: testPath);

        // Assert
        expect(result.isLeft(), true);
        final failure = result.fold((l) => l, (r) => throw Exception());
        expect(failure, isA<NetworkFailure>());
      });

      test('should return MediaUploadFailure on MediaUploadException', () async {
        // Arrange
        when(mockDataSource.deleteMedia(testPath))
            .thenThrow(const MediaUploadException('Delete failed'));

        // Act
        final result = await repository.deleteFile(storagePath: testPath);

        // Assert
        expect(result.isLeft(), true);
        final failure = result.fold((l) => l, (r) => throw Exception());
        expect(failure, isA<MediaUploadFailure>());
      });
    });

    group('deleteMultipleFiles', () {
      final testPaths = ['path1.jpg', 'path2.jpg'];

      test('should delete multiple files successfully', () async {
        // Arrange
        when(mockDataSource.deleteMedia(any))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.deleteMultipleFiles(
          storagePaths: testPaths,
        );

        // Assert
        expect(result.isRight(), true);
        verify(mockDataSource.deleteMedia('path1.jpg')).called(1);
        verify(mockDataSource.deleteMedia('path2.jpg')).called(1);
      });

      test('should return failure if any deletion fails', () async {
        // Arrange
        when(mockDataSource.deleteMedia('path1.jpg'))
            .thenAnswer((_) async => {});
        when(mockDataSource.deleteMedia('path2.jpg'))
            .thenThrow(const MediaUploadException('Delete failed'));

        // Act
        final result = await repository.deleteMultipleFiles(
          storagePaths: testPaths,
        );

        // Assert
        expect(result.isLeft(), true);
        final failure = result.fold((l) => l, (r) => throw Exception());
        expect(failure, isA<MediaUploadFailure>());
      });
    });

    group('fileExists', () {
      const testPath = 'test/path/file.jpg';

      test('should return true when file exists', () async {
        // Arrange
        when(mockDataSource.fileExists(testPath))
            .thenAnswer((_) async => true);

        // Act
        final result = await repository.fileExists(storagePath: testPath);

        // Assert
        expect(result.isRight(), true);
        expect(result.getOrElse(() => false), true);
      });

      test('should return false when file does not exist', () async {
        // Arrange
        when(mockDataSource.fileExists(testPath))
            .thenAnswer((_) async => false);

        // Act
        final result = await repository.fileExists(storagePath: testPath);

        // Assert
        expect(result.isRight(), true);
        expect(result.getOrElse(() => true), false);
      });

      test('should return NetworkFailure on NetworkException', () async {
        // Arrange
        when(mockDataSource.fileExists(testPath))
            .thenThrow(const NetworkException('Network error'));

        // Act
        final result = await repository.fileExists(storagePath: testPath);

        // Assert
        expect(result.isLeft(), true);
        final failure = result.fold((l) => l, (r) => throw Exception());
        expect(failure, isA<NetworkFailure>());
      });
    });

    group('getUserStorageSize', () {
      const userId = 'user123';

      test('should return user storage size', () async {
        // Arrange
        when(mockDataSource.getUserStorageSize(userId))
            .thenAnswer((_) async => 5000);

        // Act
        final result = await repository.getUserStorageSize(userId: userId);

        // Assert
        expect(result.isRight(), true);
        expect(result.getOrElse(() => 0), 5000);
      });

      test('should return NetworkFailure on NetworkException', () async {
        // Arrange
        when(mockDataSource.getUserStorageSize(userId))
            .thenThrow(const NetworkException('Network error'));

        // Act
        final result = await repository.getUserStorageSize(userId: userId);

        // Assert
        expect(result.isLeft(), true);
        final failure = result.fold((l) => l, (r) => throw Exception());
        expect(failure, isA<NetworkFailure>());
      });
    });

    group('downloadFile', () {
      const downloadUrl = 'https://example.com/file.jpg';

      test('should return download URL', () async {
        // Act
        final result = await repository.downloadFile(downloadUrl: downloadUrl);

        // Assert
        expect(result.isRight(), true);
        expect(result.getOrElse(() => ''), downloadUrl);
      });
    });

    group('getFileMetadata', () {
      const testPath = 'test/path/file.jpg';
      const downloadUrl = 'https://example.com/file.jpg';

      test('should return media entity with metadata', () async {
        // Arrange
        when(mockDataSource.getDownloadUrl(testPath))
            .thenAnswer((_) async => downloadUrl);

        // Act
        final result = await repository.getFileMetadata(storagePath: testPath);

        // Assert
        expect(result.isRight(), true);
        final entity = result.getOrElse(() => throw Exception());
        expect(entity, isA<MediaEntity>());
        expect(entity.url, downloadUrl);
      });

      test('should return NotFoundFailure when file not found', () async {
        // Arrange
        when(mockDataSource.getDownloadUrl(testPath))
            .thenThrow(const NotFoundException('File not found'));

        // Act
        final result = await repository.getFileMetadata(storagePath: testPath);

        // Assert
        expect(result.isLeft(), true);
        final failure = result.fold((l) => l, (r) => throw Exception());
        expect(failure, isA<NotFoundFailure>());
      });
    });

    group('cancelUpload', () {
      const uploadId = 'upload123';

      test('should return success', () async {
        // Act
        final result = await repository.cancelUpload(uploadId: uploadId);

        // Assert
        expect(result.isRight(), true);
      });
    });
  });
}
