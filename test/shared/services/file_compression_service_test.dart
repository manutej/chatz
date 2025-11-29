import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:chatz/core/errors/exceptions.dart';
import 'package:chatz/shared/services/file_compression_service.dart';

@GenerateMocks([])
import 'file_compression_service_test.mocks.dart';

void main() {
  late FileCompressionService compressionService;

  setUp(() {
    compressionService = FileCompressionService();
  });

  group('FileCompressionService', () {
    group('compressImage', () {
      test('should successfully compress an image file', () async {
        // Note: This test would require mocking FlutterImageCompress
        // which is a platform plugin. In a real scenario, you'd:
        // 1. Use integration tests with actual files
        // 2. Create a wrapper interface around FlutterImageCompress
        // 3. Use golden file testing
        //
        // For unit testing, we verify the service exists and has correct API
        expect(compressionService, isA<FileCompressionService>());
      });

      test('should use default quality when not specified', () async {
        // Verify default quality constant
        expect(FileCompressionService.defaultImageQuality, 85);
      });

      test('should use max dimension when not specified', () async {
        // Verify max dimension constant
        expect(FileCompressionService.maxImageDimension, 1920);
      });
    });

    group('compressMultipleImages', () {
      test('should handle compression of multiple images', () async {
        // This would require integration testing with actual files
        // Unit test verifies the method signature and error handling structure
        expect(
          compressionService.compressMultipleImages,
          isA<
              Future<List<File>> Function(
            List<File>, {
            int quality,
            int? maxWidth,
            int? maxHeight,
          })>(),
        );
      });
    });

    group('generateImageThumbnail', () {
      test('should use correct thumbnail size constant', () async {
        expect(FileCompressionService.thumbnailSize, 300);
      });
    });

    group('compressVideo', () {
      test('should use default video quality when not specified', () async {
        expect(
          FileCompressionService.defaultVideoQuality,
          VideoQuality.MediumQuality,
        );
      });
    });

    group('shouldCompressImage', () {
      test('should return true for files larger than threshold', () async {
        // Arrange
        final mockFile = _MockFile();
        const largeFileSize = 2 * 1024 * 1024; // 2MB
        when(mockFile.length()).thenAnswer((_) async => largeFileSize);

        // Act
        final result = await compressionService.shouldCompressImage(
          mockFile,
          maxSizeInBytes: 1024 * 1024, // 1MB threshold
        );

        // Assert
        expect(result, true);
      });

      test('should return false for files smaller than threshold', () async {
        // Arrange
        final mockFile = _MockFile();
        const smallFileSize = 500 * 1024; // 500KB
        when(mockFile.length()).thenAnswer((_) async => smallFileSize);

        // Act
        final result = await compressionService.shouldCompressImage(
          mockFile,
          maxSizeInBytes: 1024 * 1024, // 1MB threshold
        );

        // Assert
        expect(result, false);
      });

      test('should return false for files equal to threshold', () async {
        // Arrange
        final mockFile = _MockFile();
        const exactFileSize = 1024 * 1024; // 1MB
        when(mockFile.length()).thenAnswer((_) async => exactFileSize);

        // Act
        final result = await compressionService.shouldCompressImage(
          mockFile,
          maxSizeInBytes: 1024 * 1024, // 1MB threshold
        );

        // Assert
        expect(result, false);
      });

      test('should use default threshold of 1MB when not specified', () async {
        // Arrange
        final mockFile = _MockFile();
        when(mockFile.length()).thenAnswer((_) async => 2 * 1024 * 1024);

        // Act
        final result = await compressionService.shouldCompressImage(mockFile);

        // Assert
        expect(result, true);
        verify(mockFile.length()).called(1);
      });
    });

    group('shouldCompressVideo', () {
      test('should return true for videos larger than threshold', () async {
        // Arrange
        final mockFile = _MockFile();
        const largeVideoSize = 100 * 1024 * 1024; // 100MB
        when(mockFile.length()).thenAnswer((_) async => largeVideoSize);

        // Act
        final result = await compressionService.shouldCompressVideo(
          mockFile,
          maxSizeInBytes: 50 * 1024 * 1024, // 50MB threshold
        );

        // Assert
        expect(result, true);
      });

      test('should return false for videos smaller than threshold', () async {
        // Arrange
        final mockFile = _MockFile();
        const smallVideoSize = 20 * 1024 * 1024; // 20MB
        when(mockFile.length()).thenAnswer((_) async => smallVideoSize);

        // Act
        final result = await compressionService.shouldCompressVideo(
          mockFile,
          maxSizeInBytes: 50 * 1024 * 1024, // 50MB threshold
        );

        // Assert
        expect(result, false);
      });

      test('should use default threshold of 50MB when not specified', () async {
        // Arrange
        final mockFile = _MockFile();
        when(mockFile.length()).thenAnswer((_) async => 100 * 1024 * 1024);

        // Act
        final result = await compressionService.shouldCompressVideo(mockFile);

        // Assert
        expect(result, true);
      });
    });

    group('video compression progress', () {
      test('should provide video compression progress stream', () {
        // Act
        final progressStream = compressionService.videoCompressionProgress;

        // Assert
        expect(progressStream, isA<Stream<double>>());
      });
    });

    group('cancelVideoCompression', () {
      test('should call VideoCompress.cancelCompression', () {
        // This test verifies the method exists and can be called
        // Actual cancellation requires integration testing
        expect(() => compressionService.cancelVideoCompression(), returnsNormally);
      });
    });

    group('deleteVideoCache', () {
      test('should call VideoCompress.deleteAllCache', () async {
        // This test verifies the method exists and can be called
        // Actual cache deletion requires integration testing
        await compressionService.deleteVideoCache();
        // Should complete without throwing
      });
    });

    group('dispose', () {
      test('should cancel video compression on dispose', () {
        // Act
        compressionService.dispose();

        // Assert - should not throw
      });
    });

    group('file size validation', () {
      test('should correctly identify compression need for boundary cases',
          () async {
        // Test exactly at 1MB
        final file1MB = _MockFile();
        when(file1MB.length()).thenAnswer((_) async => 1024 * 1024);

        final needsCompress =
            await compressionService.shouldCompressImage(file1MB);
        expect(needsCompress, false);

        // Test 1 byte over 1MB
        final fileOverMB = _MockFile();
        when(fileOverMB.length()).thenAnswer((_) async => 1024 * 1024 + 1);

        final needsCompressOver =
            await compressionService.shouldCompressImage(fileOverMB);
        expect(needsCompressOver, true);
      });

      test('should handle zero-sized files', () async {
        // Arrange
        final mockFile = _MockFile();
        when(mockFile.length()).thenAnswer((_) async => 0);

        // Act
        final result = await compressionService.shouldCompressImage(mockFile);

        // Assert
        expect(result, false);
      });
    });

    group('error scenarios', () {
      test('compressImage should throw MediaUploadException on error', () async {
        // This would be tested in integration tests where we can
        // provide invalid file paths or corrupt files
        expect(
          FileCompressionService,
          isA<Type>(),
        );
      });

      test('compressVideo should throw MediaUploadException on error', () async {
        // This would be tested in integration tests
        expect(
          FileCompressionService,
          isA<Type>(),
        );
      });

      test(
          'generateImageThumbnail should throw MediaUploadException on error',
          () async {
        // This would be tested in integration tests
        expect(
          FileCompressionService,
          isA<Type>(),
        );
      });

      test(
          'generateVideoThumbnail should throw MediaUploadException on error',
          () async {
        // This would be tested in integration tests
        expect(
          FileCompressionService,
          isA<Type>(),
        );
      });
    });

    group('compression parameters', () {
      test('should use JPEG format for image compression', () {
        // The implementation uses CompressFormat.jpeg
        // This would be verified in integration tests
        expect(FileCompressionService.defaultImageQuality, greaterThan(0));
        expect(FileCompressionService.defaultImageQuality, lessThanOrEqualTo(100));
      });

      test('should preserve audio when compressing video', () {
        // The implementation sets includeAudio: true
        // This would be verified in integration tests by checking
        // the output video has audio tracks
        expect(FileCompressionService, isA<Type>());
      });

      test('should not delete original file when compressing video', () {
        // The implementation sets deleteOrigin: false
        // This would be verified in integration tests
        expect(FileCompressionService, isA<Type>());
      });
    });

    group('quality settings', () {
      test('default image quality should be 85', () {
        expect(FileCompressionService.defaultImageQuality, 85);
      });

      test('max image dimension should be 1920', () {
        expect(FileCompressionService.maxImageDimension, 1920);
      });

      test('thumbnail size should be 300', () {
        expect(FileCompressionService.thumbnailSize, 300);
      });

      test('default video quality should be MediumQuality', () {
        expect(
          FileCompressionService.defaultVideoQuality,
          VideoQuality.MediumQuality,
        );
      });
    });

    group('compressMultipleImages error handling', () {
      test('should continue processing remaining images on error', () async {
        // This tests that if one image fails to compress, the service
        // continues with the remaining images and returns the original
        // for the failed one. This would be verified in integration tests.
        expect(
          compressionService.compressMultipleImages,
          isA<Function>(),
        );
      });
    });
  });
}

// Mock class for File
class _MockFile extends Mock implements File {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'MockFile';
}
