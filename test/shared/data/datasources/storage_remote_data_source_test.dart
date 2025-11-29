import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chatz/shared/data/datasources/storage_remote_data_source.dart';
import 'package:chatz/shared/services/storage_service.dart';
import 'package:chatz/shared/services/file_compression_service.dart';
import 'package:chatz/shared/domain/entities/media_entity.dart';
import 'package:chatz/shared/domain/entities/upload_progress.dart';
import 'package:chatz/core/errors/exceptions.dart';

@GenerateMocks([StorageService, FileCompressionService, File])
import 'storage_remote_data_source_test.mocks.dart';

void main() {
  late StorageRemoteDataSource dataSource;
  late MockStorageService mockStorageService;
  late MockFileCompressionService mockCompressionService;

  setUp(() {
    mockStorageService = MockStorageService();
    mockCompressionService = MockFileCompressionService();
    dataSource = StorageRemoteDataSource(
      mockStorageService,
      mockCompressionService,
    );
  });

  group('StorageRemoteDataSource', () {
    group('uploadMedia', () {
      final mockFile = MockFile();
      const testPath = 'test/path/image.jpg';
      const downloadUrl = 'https://example.com/image.jpg';

      test('should upload without compression when compress is false',
          () async {
        // Arrange
        final controller = StreamController<UploadProgress>();
        final uploadId = DateTime.now().millisecondsSinceEpoch.toString();

        when(mockStorageService.uploadFile(
          file: anyNamed('file'),
          storagePath: anyNamed('storagePath'),
          metadata: anyNamed('metadata'),
        )).thenAnswer((_) => controller.stream);

        // Act
        final progressStream = dataSource.uploadMedia(
          file: mockFile,
          storagePath: testPath,
          mediaType: MediaType.image,
          compress: false,
        );

        final progressList = <UploadProgress>[];
        final subscription = progressStream.listen(progressList.add);

        // Emit completion
        controller.add(UploadProgress.completed(uploadId, downloadUrl: downloadUrl));
        await Future.delayed(const Duration(milliseconds: 50));
        await controller.close();
        await subscription.cancel();

        // Assert
        verifyNever(mockCompressionService.shouldCompressImage(any));
        verifyNever(mockCompressionService.compressImage(any));
        verify(mockStorageService.uploadFile(
          file: mockFile,
          storagePath: testPath,
          metadata: anyNamed('metadata'),
        )).called(1);
      });

      test('should compress image before upload when compress is true',
          () async {
        // Arrange
        final compressedFile = MockFile();
        final controller = StreamController<UploadProgress>();
        final uploadId = DateTime.now().millisecondsSinceEpoch.toString();

        when(mockCompressionService.shouldCompressImage(mockFile))
            .thenAnswer((_) async => true);
        when(mockCompressionService.compressImage(mockFile))
            .thenAnswer((_) async => compressedFile);
        when(mockStorageService.uploadFile(
          file: anyNamed('file'),
          storagePath: anyNamed('storagePath'),
          metadata: anyNamed('metadata'),
        )).thenAnswer((_) => controller.stream);

        // Act
        final progressStream = dataSource.uploadMedia(
          file: mockFile,
          storagePath: testPath,
          mediaType: MediaType.image,
          compress: true,
        );

        final progressList = <UploadProgress>[];
        final subscription = progressStream.listen(progressList.add);

        await Future.delayed(const Duration(milliseconds: 50));

        // Emit completion
        controller.add(UploadProgress.completed(uploadId, downloadUrl: downloadUrl));
        await Future.delayed(const Duration(milliseconds: 50));
        await controller.close();
        await subscription.cancel();

        // Assert
        verify(mockCompressionService.shouldCompressImage(mockFile)).called(1);
        verify(mockCompressionService.compressImage(mockFile)).called(1);
        verify(mockStorageService.uploadFile(
          file: compressedFile,
          storagePath: testPath,
          metadata: anyNamed('metadata'),
        )).called(1);
      });

      test('should emit compressing status before compression', () async {
        // Arrange
        final compressedFile = MockFile();
        final controller = StreamController<UploadProgress>();

        when(mockCompressionService.shouldCompressImage(mockFile))
            .thenAnswer((_) async => true);
        when(mockCompressionService.compressImage(mockFile))
            .thenAnswer((_) async => compressedFile);
        when(mockStorageService.uploadFile(
          file: anyNamed('file'),
          storagePath: anyNamed('storagePath'),
          metadata: anyNamed('metadata'),
        )).thenAnswer((_) => controller.stream);

        // Act
        final progressStream = dataSource.uploadMedia(
          file: mockFile,
          storagePath: testPath,
          mediaType: MediaType.image,
          compress: true,
        );

        final progressList = <UploadProgress>[];
        final subscription = progressStream.listen(progressList.add);

        await Future.delayed(const Duration(milliseconds: 100));
        await controller.close();
        await subscription.cancel();

        // Assert
        expect(
          progressList.any((p) => p.status == UploadStatus.compressing),
          true,
        );
      });

      test('should skip compression if image is already small enough', () async {
        // Arrange
        final controller = StreamController<UploadProgress>();
        final uploadId = DateTime.now().millisecondsSinceEpoch.toString();

        when(mockCompressionService.shouldCompressImage(mockFile))
            .thenAnswer((_) async => false);
        when(mockStorageService.uploadFile(
          file: anyNamed('file'),
          storagePath: anyNamed('storagePath'),
          metadata: anyNamed('metadata'),
        )).thenAnswer((_) => controller.stream);

        // Act
        final progressStream = dataSource.uploadMedia(
          file: mockFile,
          storagePath: testPath,
          mediaType: MediaType.image,
          compress: true,
        );

        final progressList = <UploadProgress>[];
        final subscription = progressStream.listen(progressList.add);

        // Emit completion
        controller.add(UploadProgress.completed(uploadId, downloadUrl: downloadUrl));
        await Future.delayed(const Duration(milliseconds: 50));
        await controller.close();
        await subscription.cancel();

        // Assert
        verify(mockCompressionService.shouldCompressImage(mockFile)).called(1);
        verifyNever(mockCompressionService.compressImage(any));
        verify(mockStorageService.uploadFile(
          file: mockFile,
          storagePath: testPath,
          metadata: anyNamed('metadata'),
        )).called(1);
      });

      test('should compress video before upload when needed', () async {
        // Arrange
        final compressedFile = MockFile();
        final controller = StreamController<UploadProgress>();
        final uploadId = DateTime.now().millisecondsSinceEpoch.toString();

        when(mockCompressionService.shouldCompressVideo(mockFile))
            .thenAnswer((_) async => true);
        when(mockCompressionService.compressVideo(mockFile))
            .thenAnswer((_) async => compressedFile);
        when(mockStorageService.uploadFile(
          file: anyNamed('file'),
          storagePath: anyNamed('storagePath'),
          metadata: anyNamed('metadata'),
        )).thenAnswer((_) => controller.stream);

        // Act
        final progressStream = dataSource.uploadMedia(
          file: mockFile,
          storagePath: testPath,
          mediaType: MediaType.video,
          compress: true,
        );

        final progressList = <UploadProgress>[];
        final subscription = progressStream.listen(progressList.add);

        await Future.delayed(const Duration(milliseconds: 50));

        // Emit completion
        controller.add(UploadProgress.completed(uploadId, downloadUrl: downloadUrl));
        await Future.delayed(const Duration(milliseconds: 50));
        await controller.close();
        await subscription.cancel();

        // Assert
        verify(mockCompressionService.shouldCompressVideo(mockFile)).called(1);
        verify(mockCompressionService.compressVideo(mockFile)).called(1);
      });

      test('should include custom metadata in upload', () async {
        // Arrange
        final controller = StreamController<UploadProgress>();

        when(mockStorageService.uploadFile(
          file: anyNamed('file'),
          storagePath: anyNamed('storagePath'),
          metadata: anyNamed('metadata'),
        )).thenAnswer((_) => controller.stream);

        const customMetadata = {
          'userId': 'user123',
          'messageId': 'msg456',
        };

        // Act
        final progressStream = dataSource.uploadMedia(
          file: mockFile,
          storagePath: testPath,
          mediaType: MediaType.image,
          compress: false,
          metadata: customMetadata,
        );

        final subscription = progressStream.listen((_) {});
        await Future.delayed(const Duration(milliseconds: 50));
        await controller.close();
        await subscription.cancel();

        // Assert
        verify(mockStorageService.uploadFile(
          file: mockFile,
          storagePath: testPath,
          metadata: argThat(
            predicate<Map<String, String>>((m) =>
                m['userId'] == 'user123' &&
                m['messageId'] == 'msg456' &&
                m.containsKey('contentType') &&
                m.containsKey('uploadedAt')),
            named: 'metadata',
          ),
        )).called(1);
      });
    });

    group('uploadProfileImage', () {
      final mockFile = MockFile();
      const userId = 'user123';

      test('should upload to correct profile path', () async {
        // Arrange
        final controller = StreamController<UploadProgress>();

        when(mockStorageService.uploadFile(
          file: anyNamed('file'),
          storagePath: anyNamed('storagePath'),
          metadata: anyNamed('metadata'),
        )).thenAnswer((_) => controller.stream);

        // Act
        final progressStream = dataSource.uploadProfileImage(
          imageFile: mockFile,
          userId: userId,
          compress: false,
        );

        final subscription = progressStream.listen((_) {});
        await Future.delayed(const Duration(milliseconds: 50));
        await controller.close();
        await subscription.cancel();

        // Assert
        verify(mockStorageService.uploadFile(
          file: mockFile,
          storagePath: 'profile_images/$userId/avatar.jpg',
          metadata: anyNamed('metadata'),
        )).called(1);
      });
    });

    group('uploadChatImage', () {
      final mockFile = MockFile();
      const chatId = 'chat123';
      const messageId = 'msg456';

      test('should upload to correct chat image path', () async {
        // Arrange
        final controller = StreamController<UploadProgress>();

        when(mockStorageService.uploadFile(
          file: anyNamed('file'),
          storagePath: anyNamed('storagePath'),
          metadata: anyNamed('metadata'),
        )).thenAnswer((_) => controller.stream);

        // Act
        final progressStream = dataSource.uploadChatImage(
          imageFile: mockFile,
          chatId: chatId,
          messageId: messageId,
          compress: false,
        );

        final subscription = progressStream.listen((_) {});
        await Future.delayed(const Duration(milliseconds: 50));
        await controller.close();
        await subscription.cancel();

        // Assert
        verify(mockStorageService.uploadFile(
          file: mockFile,
          storagePath: 'chat_media/$chatId/images/$messageId.jpg',
          metadata: anyNamed('metadata'),
        )).called(1);
      });
    });

    group('uploadChatVideo', () {
      final mockFile = MockFile();
      final mockThumbnail = MockFile();
      const chatId = 'chat123';
      const messageId = 'msg456';

      test('should upload video and generate thumbnail', () async {
        // Arrange
        final videoController = StreamController<UploadProgress>();
        final thumbnailController = StreamController<UploadProgress>();
        final uploadId = DateTime.now().millisecondsSinceEpoch.toString();

        when(mockCompressionService.generateVideoThumbnail(mockFile))
            .thenAnswer((_) async => mockThumbnail);

        when(mockStorageService.uploadFile(
          file: mockFile,
          storagePath: anyNamed('storagePath'),
          metadata: anyNamed('metadata'),
        )).thenAnswer((_) => videoController.stream);

        when(mockStorageService.uploadFile(
          file: mockThumbnail,
          storagePath: argThat(contains('_thumb.jpg'), named: 'storagePath'),
          metadata: anyNamed('metadata'),
        )).thenAnswer((_) => thumbnailController.stream);

        // Act
        final progressStream = dataSource.uploadChatVideo(
          videoFile: mockFile,
          chatId: chatId,
          messageId: messageId,
          compress: false,
          generateThumbnail: true,
        );

        final subscription = progressStream.listen((_) {});

        // Emit video upload completion
        videoController.add(
          UploadProgress.completed(uploadId, downloadUrl: 'https://example.com/video.mp4'),
        );
        await Future.delayed(const Duration(milliseconds: 100));

        // Complete thumbnail upload
        thumbnailController.add(
          UploadProgress.completed(uploadId, downloadUrl: 'https://example.com/thumb.jpg'),
        );
        await Future.delayed(const Duration(milliseconds: 100));

        await videoController.close();
        await thumbnailController.close();
        await subscription.cancel();

        // Assert
        verify(mockCompressionService.generateVideoThumbnail(mockFile)).called(1);
        verify(mockStorageService.uploadFile(
          file: mockThumbnail,
          storagePath: argThat(contains('_thumb.jpg'), named: 'storagePath'),
          metadata: anyNamed('metadata'),
        )).called(1);
      });

      test('should not fail if thumbnail generation fails', () async {
        // Arrange
        final videoController = StreamController<UploadProgress>();
        final uploadId = DateTime.now().millisecondsSinceEpoch.toString();

        when(mockCompressionService.generateVideoThumbnail(mockFile))
            .thenThrow(Exception('Thumbnail generation failed'));

        when(mockStorageService.uploadFile(
          file: mockFile,
          storagePath: anyNamed('storagePath'),
          metadata: anyNamed('metadata'),
        )).thenAnswer((_) => videoController.stream);

        // Act
        final progressStream = dataSource.uploadChatVideo(
          videoFile: mockFile,
          chatId: chatId,
          messageId: messageId,
          compress: false,
          generateThumbnail: true,
        );

        final progressList = <UploadProgress>[];
        final subscription = progressStream.listen(progressList.add);

        // Emit video upload completion
        videoController.add(
          UploadProgress.completed(uploadId, downloadUrl: 'https://example.com/video.mp4'),
        );
        await Future.delayed(const Duration(milliseconds: 100));
        await videoController.close();
        await subscription.cancel();

        // Assert - should still complete successfully
        expect(
          progressList.any((p) => p.status == UploadStatus.completed),
          true,
        );
      });
    });

    group('deleteMedia', () {
      const testPath = 'test/path/file.jpg';

      test('should call storage service delete', () async {
        // Arrange
        when(mockStorageService.deleteFile(testPath))
            .thenAnswer((_) async => {});

        // Act
        await dataSource.deleteMedia(testPath);

        // Assert
        verify(mockStorageService.deleteFile(testPath)).called(1);
      });

      test('should throw MediaUploadException on error', () async {
        // Arrange
        when(mockStorageService.deleteFile(testPath))
            .thenThrow(Exception('Delete failed'));

        // Act & Assert
        expect(
          () => dataSource.deleteMedia(testPath),
          throwsA(isA<MediaUploadException>()),
        );
      });
    });

    group('deleteChatMedia', () {
      const chatId = 'chat123';
      const messageId = 'msg456';

      test('should delete image media correctly', () async {
        // Arrange
        when(mockStorageService.deleteFile(any))
            .thenAnswer((_) async => {});

        // Act
        await dataSource.deleteChatMedia(
          chatId: chatId,
          messageId: messageId,
          mediaType: MediaType.image,
          fileName: null,
        );

        // Assert
        verify(mockStorageService.deleteFile(
          'chat_media/$chatId/images/$messageId.jpg',
        )).called(1);
      });

      test('should delete video and thumbnail', () async {
        // Arrange
        when(mockStorageService.deleteFile(any))
            .thenAnswer((_) async => {});

        // Act
        await dataSource.deleteChatMedia(
          chatId: chatId,
          messageId: messageId,
          mediaType: MediaType.video,
          fileName: null,
        );

        // Assert
        verify(mockStorageService.deleteFile(
          'chat_media/$chatId/videos/$messageId.mp4',
        )).called(1);
        verify(mockStorageService.deleteFile(
          argThat(contains('_thumb.jpg')),
        )).called(1);
      });

      test('should delete audio correctly', () async {
        // Arrange
        when(mockStorageService.deleteFile(any))
            .thenAnswer((_) async => {});

        // Act
        await dataSource.deleteChatMedia(
          chatId: chatId,
          messageId: messageId,
          mediaType: MediaType.audio,
          fileName: null,
        );

        // Assert
        verify(mockStorageService.deleteFile(
          'chat_media/$chatId/audio/$messageId.m4a',
        )).called(1);
      });

      test('should delete document with correct extension', () async {
        // Arrange
        when(mockStorageService.deleteFile(any))
            .thenAnswer((_) async => {});

        // Act
        await dataSource.deleteChatMedia(
          chatId: chatId,
          messageId: messageId,
          mediaType: MediaType.document,
          fileName: 'file.pdf',
        );

        // Assert
        verify(mockStorageService.deleteFile(
          'chat_media/$chatId/documents/$messageId.pdf',
        )).called(1);
      });
    });

    group('getDownloadUrl', () {
      const testPath = 'test/path/file.jpg';
      const downloadUrl = 'https://example.com/download-url';

      test('should return download URL successfully', () async {
        // Arrange
        when(mockStorageService.getDownloadUrl(testPath))
            .thenAnswer((_) async => downloadUrl);

        // Act
        final result = await dataSource.getDownloadUrl(testPath);

        // Assert
        expect(result, downloadUrl);
        verify(mockStorageService.getDownloadUrl(testPath)).called(1);
      });

      test('should throw MediaUploadException on error', () async {
        // Arrange
        when(mockStorageService.getDownloadUrl(testPath))
            .thenThrow(Exception('Failed to get URL'));

        // Act & Assert
        expect(
          () => dataSource.getDownloadUrl(testPath),
          throwsA(isA<MediaUploadException>()),
        );
      });
    });

    group('fileExists', () {
      const testPath = 'test/path/file.jpg';

      test('should return true when file exists', () async {
        // Arrange
        when(mockStorageService.fileExists(testPath))
            .thenAnswer((_) async => true);

        // Act
        final result = await dataSource.fileExists(testPath);

        // Assert
        expect(result, true);
      });

      test('should return false on error', () async {
        // Arrange
        when(mockStorageService.fileExists(testPath))
            .thenThrow(Exception('Check failed'));

        // Act
        final result = await dataSource.fileExists(testPath);

        // Assert
        expect(result, false);
      });
    });

    group('getUserStorageSize', () {
      const userId = 'user123';

      test('should calculate total user storage size', () async {
        // Arrange
        when(mockStorageService.getDirectorySize('profile_images/$userId'))
            .thenAnswer((_) async => 1000);
        when(mockStorageService.getDirectorySize('status_media/$userId'))
            .thenAnswer((_) async => 2000);

        // Act
        final result = await dataSource.getUserStorageSize(userId);

        // Assert
        expect(result, 3000);
      });

      test('should return 0 on error', () async {
        // Arrange
        when(mockStorageService.getDirectorySize(any))
            .thenThrow(Exception('Size check failed'));

        // Act
        final result = await dataSource.getUserStorageSize(userId);

        // Assert
        expect(result, 0);
      });
    });

    group('getChatStorageSize', () {
      const chatId = 'chat123';

      test('should return chat storage size', () async {
        // Arrange
        when(mockStorageService.getDirectorySize('chat_media/$chatId'))
            .thenAnswer((_) async => 5000);

        // Act
        final result = await dataSource.getChatStorageSize(chatId);

        // Assert
        expect(result, 5000);
      });
    });
  });
}
