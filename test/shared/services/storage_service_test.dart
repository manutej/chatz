import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chatz/core/errors/exceptions.dart';
import 'package:chatz/shared/services/storage_service.dart';
import 'package:chatz/shared/domain/entities/upload_progress.dart';

@GenerateMocks([
  FirebaseStorage,
  Reference,
  UploadTask,
  TaskSnapshot,
  FullMetadata,
])
import 'storage_service_test.mocks.dart';

void main() {
  late StorageService storageService;
  late MockFirebaseStorage mockStorage;
  late MockReference mockReference;
  late MockUploadTask mockUploadTask;
  late MockTaskSnapshot mockSnapshot;
  late MockFullMetadata mockMetadata;

  setUp(() {
    mockStorage = MockFirebaseStorage();
    mockReference = MockReference();
    mockUploadTask = MockUploadTask();
    mockSnapshot = MockTaskSnapshot();
    mockMetadata = MockFullMetadata();
    storageService = StorageService(mockStorage);
  });

  group('StorageService', () {
    group('uploadFile', () {
      final testFile = File('test/fixtures/test_image.jpg');
      const testPath = 'test/path/image.jpg';

      test('should emit upload progress and complete successfully', () async {
        // Arrange
        const downloadUrl = 'https://example.com/download-url';
        final controller = StreamController<TaskSnapshot>();

        // Setup mocks
        when(mockStorage.ref()).thenReturn(mockReference);
        when(mockReference.child(any)).thenReturn(mockReference);
        when(mockReference.putFile(any, any)).thenReturn(mockUploadTask);
        when(mockUploadTask.snapshotEvents).thenAnswer((_) => controller.stream);
        when(mockReference.getDownloadURL())
            .thenAnswer((_) async => downloadUrl);

        // Setup file mock
        final mockFile = _MockFile();
        when(mockFile.exists()).thenAnswer((_) async => true);
        when(mockFile.length()).thenAnswer((_) async => 1000);

        // Act
        final progressStream = storageService.uploadFile(
          file: mockFile,
          storagePath: testPath,
        );

        // Emit progress events
        final progressList = <UploadProgress>[];
        final subscription = progressStream.listen(progressList.add);

        // Emit uploading progress
        when(mockSnapshot.state).thenReturn(TaskState.running);
        when(mockSnapshot.bytesTransferred).thenReturn(500);
        when(mockSnapshot.totalBytes).thenReturn(1000);
        controller.add(mockSnapshot);

        await Future.delayed(const Duration(milliseconds: 50));

        // Emit success
        when(mockSnapshot.state).thenReturn(TaskState.success);
        when(mockSnapshot.bytesTransferred).thenReturn(1000);
        when(mockSnapshot.totalBytes).thenReturn(1000);
        controller.add(mockSnapshot);

        await Future.delayed(const Duration(milliseconds: 50));
        await controller.close();
        await subscription.cancel();

        // Assert
        expect(progressList.length, 2);

        // First progress: 50% uploaded
        expect(progressList[0].status, UploadStatus.uploading);
        expect(progressList[0].bytesTransferred, 500);
        expect(progressList[0].totalBytes, 1000);
        expect(progressList[0].percentage, 50);

        // Second progress: completed
        expect(progressList[1].status, UploadStatus.completed);
        expect(progressList[1].downloadUrl, downloadUrl);
        expect(progressList[1].percentage, 100);

        verify(mockStorage.ref()).called(1);
        verify(mockReference.child(testPath)).called(1);
        verify(mockReference.putFile(mockFile, any)).called(1);
        verify(mockReference.getDownloadURL()).called(1);
      });

      test('should throw MediaUploadException when file does not exist',
          () async {
        // Arrange
        final mockFile = _MockFile();
        when(mockFile.exists()).thenAnswer((_) async => false);

        // Act
        final progressStream = storageService.uploadFile(
          file: mockFile,
          storagePath: testPath,
        );

        // Assert
        await expectLater(
          progressStream,
          emitsInOrder([
            predicate<UploadProgress>(
              (p) => p.status == UploadStatus.failed &&
                     p.error == 'File does not exist',
            ),
          ]),
        );
      });

      test('should throw MediaUploadException when file is empty', () async {
        // Arrange
        final mockFile = _MockFile();
        when(mockFile.exists()).thenAnswer((_) async => true);
        when(mockFile.length()).thenAnswer((_) async => 0);

        // Act
        final progressStream = storageService.uploadFile(
          file: mockFile,
          storagePath: testPath,
        );

        // Assert
        await expectLater(
          progressStream,
          emitsInOrder([
            predicate<UploadProgress>(
              (p) => p.status == UploadStatus.failed &&
                     p.error == 'File is empty',
            ),
          ]),
        );
      });

      test('should emit failed progress on upload error', () async {
        // Arrange
        final controller = StreamController<TaskSnapshot>();
        final mockFile = _MockFile();
        when(mockFile.exists()).thenAnswer((_) async => true);
        when(mockFile.length()).thenAnswer((_) async => 1000);

        when(mockStorage.ref()).thenReturn(mockReference);
        when(mockReference.child(any)).thenReturn(mockReference);
        when(mockReference.putFile(any, any)).thenReturn(mockUploadTask);
        when(mockUploadTask.snapshotEvents).thenAnswer((_) => controller.stream);

        // Act
        final progressStream = storageService.uploadFile(
          file: mockFile,
          storagePath: testPath,
        );

        final progressList = <UploadProgress>[];
        final subscription = progressStream.listen(progressList.add);

        // Emit error state
        when(mockSnapshot.state).thenReturn(TaskState.error);
        controller.add(mockSnapshot);

        await Future.delayed(const Duration(milliseconds: 50));
        await controller.close();
        await subscription.cancel();

        // Assert
        expect(progressList.length, 1);
        expect(progressList[0].status, UploadStatus.failed);
      });

      test('should emit cancelled progress when upload is cancelled', () async {
        // Arrange
        final controller = StreamController<TaskSnapshot>();
        final mockFile = _MockFile();
        when(mockFile.exists()).thenAnswer((_) async => true);
        when(mockFile.length()).thenAnswer((_) async => 1000);

        when(mockStorage.ref()).thenReturn(mockReference);
        when(mockReference.child(any)).thenReturn(mockReference);
        when(mockReference.putFile(any, any)).thenReturn(mockUploadTask);
        when(mockUploadTask.snapshotEvents).thenAnswer((_) => controller.stream);

        // Act
        final progressStream = storageService.uploadFile(
          file: mockFile,
          storagePath: testPath,
        );

        final progressList = <UploadProgress>[];
        final subscription = progressStream.listen(progressList.add);

        // Emit cancelled state
        when(mockSnapshot.state).thenReturn(TaskState.canceled);
        controller.add(mockSnapshot);

        await Future.delayed(const Duration(milliseconds: 50));
        await controller.close();
        await subscription.cancel();

        // Assert
        expect(progressList.length, 1);
        expect(progressList[0].status, UploadStatus.cancelled);
      });

      test('should include custom metadata in upload', () async {
        // Arrange
        final controller = StreamController<TaskSnapshot>();
        final mockFile = _MockFile();
        when(mockFile.exists()).thenAnswer((_) async => true);
        when(mockFile.length()).thenAnswer((_) async => 1000);

        when(mockStorage.ref()).thenReturn(mockReference);
        when(mockReference.child(any)).thenReturn(mockReference);
        when(mockReference.putFile(any, any)).thenReturn(mockUploadTask);
        when(mockUploadTask.snapshotEvents).thenAnswer((_) => controller.stream);

        const metadata = {
          'contentType': 'image/jpeg',
          'userId': 'test-user',
        };

        // Act
        storageService.uploadFile(
          file: mockFile,
          storagePath: testPath,
          metadata: metadata,
        );

        await Future.delayed(const Duration(milliseconds: 50));
        await controller.close();

        // Assert
        verify(
          mockReference.putFile(
            mockFile,
            argThat(
              predicate<SettableMetadata>((m) =>
                  m.contentType == 'image/jpeg' &&
                  m.customMetadata?['userId'] == 'test-user'),
            ),
          ),
        ).called(1);
      });
    });

    group('getDownloadUrl', () {
      const testPath = 'test/path/file.jpg';
      const downloadUrl = 'https://example.com/download-url';

      test('should return download URL successfully', () async {
        // Arrange
        when(mockStorage.ref()).thenReturn(mockReference);
        when(mockReference.child(testPath)).thenReturn(mockReference);
        when(mockReference.getDownloadURL())
            .thenAnswer((_) async => downloadUrl);

        // Act
        final result = await storageService.getDownloadUrl(testPath);

        // Assert
        expect(result, downloadUrl);
        verify(mockStorage.ref()).called(1);
        verify(mockReference.child(testPath)).called(1);
        verify(mockReference.getDownloadURL()).called(1);
      });

      test('should throw NotFoundException when file not found', () async {
        // Arrange
        when(mockStorage.ref()).thenReturn(mockReference);
        when(mockReference.child(testPath)).thenReturn(mockReference);
        when(mockReference.getDownloadURL()).thenThrow(
          FirebaseException(
            plugin: 'storage',
            code: 'object-not-found',
            message: 'File not found',
          ),
        );

        // Act & Assert
        expect(
          () => storageService.getDownloadUrl(testPath),
          throwsA(isA<NotFoundException>()),
        );
      });

      test('should throw MediaUploadException on other Firebase errors',
          () async {
        // Arrange
        when(mockStorage.ref()).thenReturn(mockReference);
        when(mockReference.child(testPath)).thenReturn(mockReference);
        when(mockReference.getDownloadURL()).thenThrow(
          FirebaseException(
            plugin: 'storage',
            code: 'unknown',
            message: 'Unknown error',
          ),
        );

        // Act & Assert
        expect(
          () => storageService.getDownloadUrl(testPath),
          throwsA(isA<MediaUploadException>()),
        );
      });
    });

    group('deleteFile', () {
      const testPath = 'test/path/file.jpg';

      test('should delete file successfully', () async {
        // Arrange
        when(mockStorage.ref()).thenReturn(mockReference);
        when(mockReference.child(testPath)).thenReturn(mockReference);
        when(mockReference.delete()).thenAnswer((_) async => {});

        // Act
        await storageService.deleteFile(testPath);

        // Assert
        verify(mockStorage.ref()).called(1);
        verify(mockReference.child(testPath)).called(1);
        verify(mockReference.delete()).called(1);
      });

      test('should not throw when file does not exist', () async {
        // Arrange
        when(mockStorage.ref()).thenReturn(mockReference);
        when(mockReference.child(testPath)).thenReturn(mockReference);
        when(mockReference.delete()).thenThrow(
          FirebaseException(
            plugin: 'storage',
            code: 'object-not-found',
            message: 'File not found',
          ),
        );

        // Act & Assert - should not throw
        await storageService.deleteFile(testPath);

        verify(mockReference.delete()).called(1);
      });

      test('should throw MediaUploadException on other errors', () async {
        // Arrange
        when(mockStorage.ref()).thenReturn(mockReference);
        when(mockReference.child(testPath)).thenReturn(mockReference);
        when(mockReference.delete()).thenThrow(
          FirebaseException(
            plugin: 'storage',
            code: 'unauthorized',
            message: 'Unauthorized',
          ),
        );

        // Act & Assert
        expect(
          () => storageService.deleteFile(testPath),
          throwsA(isA<MediaUploadException>()),
        );
      });
    });

    group('deleteMultipleFiles', () {
      final testPaths = ['path1.jpg', 'path2.jpg', 'path3.jpg'];

      test('should delete all files successfully', () async {
        // Arrange
        when(mockStorage.ref()).thenReturn(mockReference);
        when(mockReference.child(any)).thenReturn(mockReference);
        when(mockReference.delete()).thenAnswer((_) async => {});

        // Act
        await storageService.deleteMultipleFiles(testPaths);

        // Assert
        verify(mockReference.delete()).called(3);
      });

      test('should throw exception with error details when some deletions fail',
          () async {
        // Arrange
        when(mockStorage.ref()).thenReturn(mockReference);
        when(mockReference.child(any)).thenReturn(mockReference);
        when(mockReference.delete())
            .thenAnswer((_) async => {})
            .thenThrow(Exception('Delete failed'))
            .thenAnswer((_) async => {});

        // Act & Assert
        expect(
          () => storageService.deleteMultipleFiles(testPaths),
          throwsA(
            predicate<MediaUploadException>(
              (e) => e.message.contains('Failed to delete some files'),
            ),
          ),
        );
      });
    });

    group('fileExists', () {
      const testPath = 'test/path/file.jpg';

      test('should return true when file exists', () async {
        // Arrange
        when(mockStorage.ref()).thenReturn(mockReference);
        when(mockReference.child(testPath)).thenReturn(mockReference);
        when(mockReference.getMetadata()).thenAnswer((_) async => mockMetadata);

        // Act
        final result = await storageService.fileExists(testPath);

        // Assert
        expect(result, true);
        verify(mockReference.getMetadata()).called(1);
      });

      test('should return false when file does not exist', () async {
        // Arrange
        when(mockStorage.ref()).thenReturn(mockReference);
        when(mockReference.child(testPath)).thenReturn(mockReference);
        when(mockReference.getMetadata()).thenThrow(
          FirebaseException(
            plugin: 'storage',
            code: 'object-not-found',
          ),
        );

        // Act
        final result = await storageService.fileExists(testPath);

        // Assert
        expect(result, false);
      });

      test('should rethrow other Firebase exceptions', () async {
        // Arrange
        when(mockStorage.ref()).thenReturn(mockReference);
        when(mockReference.child(testPath)).thenReturn(mockReference);
        when(mockReference.getMetadata()).thenThrow(
          FirebaseException(
            plugin: 'storage',
            code: 'unauthorized',
          ),
        );

        // Act & Assert
        expect(
          () => storageService.fileExists(testPath),
          throwsA(isA<FirebaseException>()),
        );
      });
    });

    group('getFileMetadata', () {
      const testPath = 'test/path/file.jpg';

      test('should return metadata successfully', () async {
        // Arrange
        when(mockStorage.ref()).thenReturn(mockReference);
        when(mockReference.child(testPath)).thenReturn(mockReference);
        when(mockReference.getMetadata()).thenAnswer((_) async => mockMetadata);

        // Act
        final result = await storageService.getFileMetadata(testPath);

        // Assert
        expect(result, mockMetadata);
        verify(mockReference.getMetadata()).called(1);
      });

      test('should throw NotFoundException when file not found', () async {
        // Arrange
        when(mockStorage.ref()).thenReturn(mockReference);
        when(mockReference.child(testPath)).thenReturn(mockReference);
        when(mockReference.getMetadata()).thenThrow(
          FirebaseException(
            plugin: 'storage',
            code: 'object-not-found',
          ),
        );

        // Act & Assert
        expect(
          () => storageService.getFileMetadata(testPath),
          throwsA(isA<NotFoundException>()),
        );
      });
    });

    group('path generation helpers', () {
      test('getProfileImagePath should generate correct path', () {
        // Act
        final path = StorageService.getProfileImagePath('user123');

        // Assert
        expect(path, 'profile_images/user123/avatar.jpg');
      });

      test('getChatImagePath should generate correct path', () {
        // Act
        final path = StorageService.getChatImagePath('chat123', 'msg456');

        // Assert
        expect(path, 'chat_media/chat123/images/msg456.jpg');
      });

      test('getChatVideoPath should generate correct path', () {
        // Act
        final path = StorageService.getChatVideoPath('chat123', 'msg456');

        // Assert
        expect(path, 'chat_media/chat123/videos/msg456.mp4');
      });

      test('getChatAudioPath should generate correct path', () {
        // Act
        final path = StorageService.getChatAudioPath('chat123', 'msg456');

        // Assert
        expect(path, 'chat_media/chat123/audio/msg456.m4a');
      });

      test('getChatDocumentPath should generate correct path with extension',
          () {
        // Act
        final path = StorageService.getChatDocumentPath(
          'chat123',
          'msg456',
          'document.pdf',
        );

        // Assert
        expect(path, 'chat_media/chat123/documents/msg456.pdf');
      });

      test('getStatusMediaPath should generate correct path', () {
        // Act
        final path = StorageService.getStatusMediaPath('user123', 'status789');

        // Assert
        expect(path, 'status_media/user123/status789.jpg');
      });

      test('getVideoThumbnailPath should replace mp4 with thumb.jpg', () {
        // Act
        final path = StorageService.getVideoThumbnailPath(
          'chat_media/chat123/videos/msg456.mp4',
        );

        // Assert
        expect(path, 'chat_media/chat123/videos/msg456_thumb.jpg');
      });
    });

    group('listFiles', () {
      const directoryPath = 'test/directory';

      test('should list files successfully', () async {
        // Arrange
        final mockListResult = _MockListResult();
        final mockItems = [mockReference, mockReference];

        when(mockStorage.ref()).thenReturn(mockReference);
        when(mockReference.child(directoryPath)).thenReturn(mockReference);
        when(mockReference.listAll()).thenAnswer((_) async => mockListResult);
        when(mockListResult.items).thenReturn(mockItems);

        // Act
        final result = await storageService.listFiles(directoryPath);

        // Assert
        expect(result, mockItems);
        expect(result.length, 2);
        verify(mockReference.listAll()).called(1);
      });

      test('should throw MediaUploadException on error', () async {
        // Arrange
        when(mockStorage.ref()).thenReturn(mockReference);
        when(mockReference.child(directoryPath)).thenReturn(mockReference);
        when(mockReference.listAll()).thenThrow(
          FirebaseException(plugin: 'storage', code: 'unknown'),
        );

        // Act & Assert
        expect(
          () => storageService.listFiles(directoryPath),
          throwsA(isA<MediaUploadException>()),
        );
      });
    });

    group('getDirectorySize', () {
      const directoryPath = 'test/directory';

      test('should calculate total directory size', () async {
        // Arrange
        final mockListResult = _MockListResult();
        final mockRef1 = MockReference();
        final mockRef2 = MockReference();
        final mockMetadata1 = MockFullMetadata();
        final mockMetadata2 = MockFullMetadata();

        when(mockStorage.ref()).thenReturn(mockReference);
        when(mockReference.child(directoryPath)).thenReturn(mockReference);
        when(mockReference.listAll()).thenAnswer((_) async => mockListResult);
        when(mockListResult.items).thenReturn([mockRef1, mockRef2]);

        when(mockRef1.getMetadata()).thenAnswer((_) async => mockMetadata1);
        when(mockRef2.getMetadata()).thenAnswer((_) async => mockMetadata2);
        when(mockMetadata1.size).thenReturn(1000);
        when(mockMetadata2.size).thenReturn(2000);

        // Act
        final result = await storageService.getDirectorySize(directoryPath);

        // Assert
        expect(result, 3000);
        verify(mockRef1.getMetadata()).called(1);
        verify(mockRef2.getMetadata()).called(1);
      });

      test('should handle null size values', () async {
        // Arrange
        final mockListResult = _MockListResult();
        final mockRef1 = MockReference();
        final mockMetadata1 = MockFullMetadata();

        when(mockStorage.ref()).thenReturn(mockReference);
        when(mockReference.child(directoryPath)).thenReturn(mockReference);
        when(mockReference.listAll()).thenAnswer((_) async => mockListResult);
        when(mockListResult.items).thenReturn([mockRef1]);

        when(mockRef1.getMetadata()).thenAnswer((_) async => mockMetadata1);
        when(mockMetadata1.size).thenReturn(null);

        // Act
        final result = await storageService.getDirectorySize(directoryPath);

        // Assert
        expect(result, 0);
      });
    });
  });
}

// Mock classes for File and ListResult
class _MockFile extends Mock implements File {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'MockFile';
}

class _MockListResult extends Mock implements ListResult {}
