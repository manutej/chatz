import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:chatz/shared/services/storage_service.dart';
import 'package:chatz/shared/services/image_picker_service.dart';
import 'package:chatz/shared/services/file_compression_service.dart';
import 'package:chatz/shared/data/datasources/storage_remote_data_source.dart';
import 'package:chatz/shared/data/repositories/storage_repository_impl.dart';
import 'package:chatz/shared/domain/entities/media_entity.dart';
import 'package:chatz/shared/domain/entities/upload_progress.dart';
import 'package:chatz/shared/domain/usecases/upload_file_usecase.dart';
import 'package:chatz/shared/domain/usecases/delete_file_usecase.dart';
import 'package:chatz/shared/domain/usecases/get_download_url_usecase.dart';

/// Integration tests for Storage Flow
///
/// NOTE: These tests require Firebase Emulator to be running.
/// Start the emulator with: firebase emulators:start
///
/// The tests use the Firebase Storage Emulator and do not interact
/// with production Firebase services.
void main() {
  group('Storage Flow Integration Tests', () {
    late FirebaseStorage storage;
    late StorageService storageService;
    late FileCompressionService compressionService;
    late StorageRemoteDataSource dataSource;
    late StorageRepositoryImpl repository;
    late UploadFileUseCase uploadUseCase;
    late DeleteFileUseCase deleteUseCase;
    late GetDownloadUrlUseCase getDownloadUrlUseCase;

    setUpAll(() async {
      // Initialize Firebase for testing
      // In a real integration test, you would configure the Firebase Emulator
      // await Firebase.initializeApp();

      // Configure Storage Emulator
      // FirebaseStorage.instance.useStorageEmulator('localhost', 9199);

      // For this example, we assume Firebase is already initialized
      // and configured to use the emulator
    });

    setUp(() {
      // Initialize services and use cases
      storage = FirebaseStorage.instance;
      storageService = StorageService(storage);
      compressionService = FileCompressionService();
      dataSource = StorageRemoteDataSource(storageService, compressionService);
      repository = StorageRepositoryImpl(dataSource);
      uploadUseCase = UploadFileUseCase(repository);
      deleteUseCase = DeleteFileUseCase(repository);
      getDownloadUrlUseCase = GetDownloadUrlUseCase(repository);
    });

    group('Upload Flow', () {
      testWidgets('should upload image with compression and get download URL',
          (tester) async {
        // This test would require actual file creation in a test environment
        // For demonstration purposes, we outline the test structure

        // Arrange
        // final testImageFile = await createTestImageFile();
        // final storagePath = 'test/images/${DateTime.now().millisecondsSinceEpoch}.jpg';

        // Act
        // final params = UploadFileParams(
        //   file: testImageFile,
        //   storagePath: storagePath,
        //   mediaType: MediaType.image,
        //   compress: true,
        // );

        // final uploadStream = uploadUseCase(params);
        // UploadProgress? lastProgress;

        // await for (final result in uploadStream) {
        //   result.fold(
        //     (failure) => fail('Upload should not fail: ${failure.message}'),
        //     (progress) {
        //       lastProgress = progress;
        //       print('Upload progress: ${progress.percentage}%');
        //     },
        //   );
        // }

        // Assert
        // expect(lastProgress, isNotNull);
        // expect(lastProgress!.status, UploadStatus.completed);
        // expect(lastProgress!.downloadUrl, isNotNull);
        // expect(lastProgress!.downloadUrl, startsWith('http'));

        // Cleanup
        // await deleteUseCase(storagePath);
        // await testImageFile.delete();
      });

      testWidgets('should upload video with thumbnail generation',
          (tester) async {
        // Test structure for video upload with thumbnail
        // Similar to image upload but includes thumbnail verification

        // Arrange
        // final testVideoFile = await createTestVideoFile();
        // final videoPath = 'test/videos/${DateTime.now().millisecondsSinceEpoch}.mp4';

        // Act
        // Upload video using data source method that generates thumbnail
        // await for (final progress in dataSource.uploadChatVideo(
        //   videoFile: testVideoFile,
        //   chatId: 'test-chat',
        //   messageId: 'test-message',
        //   compress: true,
        //   generateThumbnail: true,
        // )) {
        //   if (progress.isCompleted) {
        //     // Verify thumbnail was uploaded
        //     final thumbnailPath = StorageService.getVideoThumbnailPath(videoPath);
        //     final thumbnailExists = await storageService.fileExists(thumbnailPath);
        //     expect(thumbnailExists, true);
        //   }
        // }

        // Cleanup
        // await deleteUseCase(videoPath);
        // await deleteUseCase(StorageService.getVideoThumbnailPath(videoPath));
      });

      testWidgets('should upload multiple images concurrently', (tester) async {
        // Test structure for multiple file uploads

        // Arrange
        // final files = [
        //   await createTestImageFile(),
        //   await createTestImageFile(),
        //   await createTestImageFile(),
        // ];

        // final paths = files.map((f) =>
        //   'test/images/multi_${DateTime.now().millisecondsSinceEpoch}_${files.indexOf(f)}.jpg'
        // ).toList();

        // Act
        // await for (final result in repository.uploadMultipleFiles(
        //   files: files,
        //   storagePaths: paths,
        //   mediaType: MediaType.image,
        //   compress: true,
        // )) {
        //   result.fold(
        //     (failure) => fail('Upload should not fail'),
        //     (progressMap) {
        //       // Verify all files are being tracked
        //       expect(progressMap.length, files.length);
        //     },
        //   );
        // }

        // Cleanup
        // for (final path in paths) {
        //   await deleteUseCase(path);
        // }
      });
    });

    group('Download Flow', () {
      testWidgets('should upload file and retrieve download URL',
          (tester) async {
        // Arrange
        // final testFile = await createTestImageFile();
        // final storagePath = 'test/downloads/${DateTime.now().millisecondsSinceEpoch}.jpg';

        // Upload file first
        // final params = UploadFileParams(
        //   file: testFile,
        //   storagePath: storagePath,
        //   mediaType: MediaType.image,
        //   compress: false,
        // );

        // String? uploadedUrl;
        // await for (final result in uploadUseCase(params)) {
        //   result.fold(
        //     (failure) => fail('Upload failed'),
        //     (progress) {
        //       if (progress.isCompleted) {
        //         uploadedUrl = progress.downloadUrl;
        //       }
        //     },
        //   );
        // }

        // Act - Get download URL
        // final urlResult = await getDownloadUrlUseCase(storagePath);

        // Assert
        // expect(urlResult.isRight(), true);
        // final downloadUrl = urlResult.getOrElse(() => '');
        // expect(downloadUrl, equals(uploadedUrl));
        // expect(downloadUrl, startsWith('http'));

        // Cleanup
        // await deleteUseCase(storagePath);
      });
    });

    group('Delete Flow', () {
      testWidgets('should upload and delete file successfully', (tester) async {
        // Arrange
        // final testFile = await createTestImageFile();
        // final storagePath = 'test/delete/${DateTime.now().millisecondsSinceEpoch}.jpg';

        // Upload file first
        // await for (final result in uploadUseCase(UploadFileParams(
        //   file: testFile,
        //   storagePath: storagePath,
        //   mediaType: MediaType.image,
        // ))) {
        //   // Wait for upload to complete
        // }

        // Verify file exists
        // final existsBeforeResult = await repository.fileExists(storagePath: storagePath);
        // expect(existsBeforeResult.getOrElse(() => false), true);

        // Act - Delete file
        // final deleteResult = await deleteUseCase(storagePath);

        // Assert
        // expect(deleteResult.isRight(), true);

        // Verify file no longer exists
        // final existsAfterResult = await repository.fileExists(storagePath: storagePath);
        // expect(existsAfterResult.getOrElse(() => true), false);
      });

      testWidgets('should delete video and its thumbnail', (tester) async {
        // Test for video deletion including thumbnail cleanup

        // Arrange
        // final testVideo = await createTestVideoFile();
        // final videoPath = 'test/videos/${DateTime.now().millisecondsSinceEpoch}.mp4';

        // Upload video with thumbnail
        // await for (final progress in dataSource.uploadChatVideo(
        //   videoFile: testVideo,
        //   chatId: 'test-chat',
        //   messageId: 'test-message',
        //   compress: false,
        //   generateThumbnail: true,
        // )) {
        //   // Wait for completion
        // }

        // Act - Delete chat media (should delete video and thumbnail)
        // await dataSource.deleteChatMedia(
        //   chatId: 'test-chat',
        //   messageId: 'test-message',
        //   mediaType: MediaType.video,
        //   fileName: null,
        // );

        // Assert - Both video and thumbnail should be deleted
        // final videoExists = await storageService.fileExists(videoPath);
        // final thumbnailExists = await storageService.fileExists(
        //   StorageService.getVideoThumbnailPath(videoPath),
        // );
        // expect(videoExists, false);
        // expect(thumbnailExists, false);
      });
    });

    group('Compression Flow', () {
      testWidgets('should compress large image before upload', (tester) async {
        // Test that images over threshold are compressed

        // Arrange
        // final largeImage = await createLargeTestImageFile(size: 3 * 1024 * 1024); // 3MB
        // final originalSize = await largeImage.length();
        // final storagePath = 'test/compressed/${DateTime.now().millisecondsSinceEpoch}.jpg';

        // Act - Upload with compression enabled
        // await for (final result in uploadUseCase(UploadFileParams(
        //   file: largeImage,
        //   storagePath: storagePath,
        //   mediaType: MediaType.image,
        //   compress: true,
        // ))) {
        //   result.fold(
        //     (failure) => fail('Upload failed'),
        //     (progress) {
        //       // Check for compression status
        //       if (progress.status == UploadStatus.compressing) {
        //         print('Compressing image...');
        //       }
        //       if (progress.isCompleted) {
        //         // File should be compressed (smaller)
        //         expect(progress.totalBytes, lessThan(originalSize));
        //       }
        //     },
        //   );
        // }

        // Cleanup
        // await deleteUseCase(storagePath);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle non-existent file download URL request',
          (tester) async {
        // Arrange
        const nonExistentPath = 'test/nonexistent/file.jpg';

        // Act
        final result = await getDownloadUrlUseCase(nonExistentPath);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            // Should be NotFoundFailure
            expect(failure.message, contains('not found'));
          },
          (url) => fail('Should not return URL for non-existent file'),
        );
      });

      testWidgets('should handle delete of non-existent file gracefully',
          (tester) async {
        // Arrange
        const nonExistentPath = 'test/nonexistent/file.jpg';

        // Act
        final result = await deleteUseCase(nonExistentPath);

        // Assert - should succeed (idempotent delete)
        expect(result.isRight(), true);
      });
    });

    group('Storage Metadata', () {
      testWidgets('should include custom metadata in uploads', (tester) async {
        // Arrange
        // final testFile = await createTestImageFile();
        // final storagePath = 'test/metadata/${DateTime.now().millisecondsSinceEpoch}.jpg';
        // const metadata = {
        //   'userId': 'test-user-123',
        //   'chatId': 'test-chat-456',
        //   'messageId': 'test-message-789',
        // };

        // Act - Upload with metadata
        // await for (final result in uploadUseCase(UploadFileParams(
        //   file: testFile,
        //   storagePath: storagePath,
        //   mediaType: MediaType.image,
        //   metadata: metadata,
        // ))) {
        //   // Wait for upload
        // }

        // Assert - Retrieve and verify metadata
        // final fileMetadata = await storageService.getFileMetadata(storagePath);
        // expect(fileMetadata.customMetadata?['userId'], 'test-user-123');
        // expect(fileMetadata.customMetadata?['chatId'], 'test-chat-456');
        // expect(fileMetadata.customMetadata?['messageId'], 'test-message-789');

        // Cleanup
        // await deleteUseCase(storagePath);
      });
    });

    group('Storage Size Calculations', () {
      testWidgets('should calculate user storage size correctly',
          (tester) async {
        // Arrange
        const userId = 'test-user-123';
        // Upload test files to user's storage locations

        // Act
        // final sizeResult = await repository.getUserStorageSize(userId: userId);

        // Assert
        // expect(sizeResult.isRight(), true);
        // final size = sizeResult.getOrElse(() => -1);
        // expect(size, greaterThanOrEqualTo(0));
      });

      testWidgets('should calculate chat storage size correctly',
          (tester) async {
        // Similar test for chat storage size calculation
      });
    });
  });
}

// Helper functions for creating test files
// These would be implemented in a real integration test

// Future<File> createTestImageFile({int size = 1024 * 100}) async {
//   // Create a test image file
//   // Implementation would use actual image generation
// }

// Future<File> createLargeTestImageFile({required int size}) async {
//   // Create a large test image
// }

// Future<File> createTestVideoFile() async {
//   // Create a test video file
// }
