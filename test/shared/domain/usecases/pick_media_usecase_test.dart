import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chatz/core/errors/exceptions.dart';
import 'package:chatz/shared/services/image_picker_service.dart';
import 'package:chatz/shared/domain/usecases/pick_media_usecase.dart';

@GenerateMocks([ImagePickerService, File])
import 'pick_media_usecase_test.mocks.dart';

void main() {
  late PickImageFromGalleryUseCase pickImageGalleryUseCase;
  late PickImageFromCameraUseCase pickImageCameraUseCase;
  late PickMultipleImagesUseCase pickMultipleImagesUseCase;
  late PickVideoFromGalleryUseCase pickVideoGalleryUseCase;
  late RecordVideoWithCameraUseCase recordVideoUseCase;
  late MockImagePickerService mockPickerService;

  setUp(() {
    mockPickerService = MockImagePickerService();
    pickImageGalleryUseCase = PickImageFromGalleryUseCase(mockPickerService);
    pickImageCameraUseCase = PickImageFromCameraUseCase(mockPickerService);
    pickMultipleImagesUseCase = PickMultipleImagesUseCase(mockPickerService);
    pickVideoGalleryUseCase = PickVideoFromGalleryUseCase(mockPickerService);
    recordVideoUseCase = RecordVideoWithCameraUseCase(mockPickerService);
  });

  group('PickImageFromGalleryUseCase', () {
    final mockFile = MockFile();

    test('should return File when image is picked', () async {
      // Arrange
      when(mockPickerService.pickImageFromGallery(
        imageQuality: anyNamed('imageQuality'),
        maxWidth: anyNamed('maxWidth'),
        maxHeight: anyNamed('maxHeight'),
      )).thenAnswer((_) async => mockFile);

      // Act
      final result = await pickImageGalleryUseCase();

      // Assert
      expect(result, mockFile);
      verify(mockPickerService.pickImageFromGallery(
        imageQuality: 85,
        maxWidth: null,
        maxHeight: null,
      )).called(1);
    });

    test('should return null when user cancels', () async {
      // Arrange
      when(mockPickerService.pickImageFromGallery(
        imageQuality: anyNamed('imageQuality'),
        maxWidth: anyNamed('maxWidth'),
        maxHeight: anyNamed('maxHeight'),
      )).thenAnswer((_) async => null);

      // Act
      final result = await pickImageGalleryUseCase();

      // Assert
      expect(result, null);
    });

    test('should use custom quality parameter', () async {
      // Arrange
      when(mockPickerService.pickImageFromGallery(
        imageQuality: anyNamed('imageQuality'),
        maxWidth: anyNamed('maxWidth'),
        maxHeight: anyNamed('maxHeight'),
      )).thenAnswer((_) async => mockFile);

      // Act
      await pickImageGalleryUseCase(imageQuality: 70);

      // Assert
      verify(mockPickerService.pickImageFromGallery(
        imageQuality: 70,
        maxWidth: null,
        maxHeight: null,
      )).called(1);
    });

    test('should use custom dimensions parameters', () async {
      // Arrange
      when(mockPickerService.pickImageFromGallery(
        imageQuality: anyNamed('imageQuality'),
        maxWidth: anyNamed('maxWidth'),
        maxHeight: anyNamed('maxHeight'),
      )).thenAnswer((_) async => mockFile);

      // Act
      await pickImageGalleryUseCase(
        maxWidth: 1920.0,
        maxHeight: 1080.0,
      );

      // Assert
      verify(mockPickerService.pickImageFromGallery(
        imageQuality: 85,
        maxWidth: 1920.0,
        maxHeight: 1080.0,
      )).called(1);
    });

    test('should throw PermissionException when permission denied', () async {
      // Arrange
      when(mockPickerService.pickImageFromGallery(
        imageQuality: anyNamed('imageQuality'),
        maxWidth: anyNamed('maxWidth'),
        maxHeight: anyNamed('maxHeight'),
      )).thenThrow(const PermissionException('Permission denied'));

      // Act & Assert
      expect(
        () => pickImageGalleryUseCase(),
        throwsA(isA<PermissionException>()),
      );
    });

    test('should throw MediaUploadException on picker error', () async {
      // Arrange
      when(mockPickerService.pickImageFromGallery(
        imageQuality: anyNamed('imageQuality'),
        maxWidth: anyNamed('maxWidth'),
        maxHeight: anyNamed('maxHeight'),
      )).thenThrow(const MediaUploadException('Picker error'));

      // Act & Assert
      expect(
        () => pickImageGalleryUseCase(),
        throwsA(isA<MediaUploadException>()),
      );
    });
  });

  group('PickImageFromCameraUseCase', () {
    final mockFile = MockFile();

    test('should return File when image is captured', () async {
      // Arrange
      when(mockPickerService.pickImageFromCamera(
        imageQuality: anyNamed('imageQuality'),
        maxWidth: anyNamed('maxWidth'),
        maxHeight: anyNamed('maxHeight'),
      )).thenAnswer((_) async => mockFile);

      // Act
      final result = await pickImageCameraUseCase();

      // Assert
      expect(result, mockFile);
      verify(mockPickerService.pickImageFromCamera(
        imageQuality: 85,
        maxWidth: null,
        maxHeight: null,
      )).called(1);
    });

    test('should return null when user cancels', () async {
      // Arrange
      when(mockPickerService.pickImageFromCamera(
        imageQuality: anyNamed('imageQuality'),
        maxWidth: anyNamed('maxWidth'),
        maxHeight: anyNamed('maxHeight'),
      )).thenAnswer((_) async => null);

      // Act
      final result = await pickImageCameraUseCase();

      // Assert
      expect(result, null);
    });

    test('should use custom parameters', () async {
      // Arrange
      when(mockPickerService.pickImageFromCamera(
        imageQuality: anyNamed('imageQuality'),
        maxWidth: anyNamed('maxWidth'),
        maxHeight: anyNamed('maxHeight'),
      )).thenAnswer((_) async => mockFile);

      // Act
      await pickImageCameraUseCase(
        imageQuality: 90,
        maxWidth: 2048.0,
        maxHeight: 1536.0,
      );

      // Assert
      verify(mockPickerService.pickImageFromCamera(
        imageQuality: 90,
        maxWidth: 2048.0,
        maxHeight: 1536.0,
      )).called(1);
    });
  });

  group('PickMultipleImagesUseCase', () {
    final mockFile1 = MockFile();
    final mockFile2 = MockFile();
    final mockFile3 = MockFile();

    test('should return list of Files when images are picked', () async {
      // Arrange
      when(mockPickerService.pickMultipleImages(
        imageQuality: anyNamed('imageQuality'),
        maxWidth: anyNamed('maxWidth'),
        maxHeight: anyNamed('maxHeight'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => [mockFile1, mockFile2, mockFile3]);

      // Act
      final result = await pickMultipleImagesUseCase();

      // Assert
      expect(result.length, 3);
      expect(result, contains(mockFile1));
      expect(result, contains(mockFile2));
      expect(result, contains(mockFile3));
      verify(mockPickerService.pickMultipleImages(
        imageQuality: 85,
        maxWidth: null,
        maxHeight: null,
        limit: null,
      )).called(1);
    });

    test('should return empty list when user cancels', () async {
      // Arrange
      when(mockPickerService.pickMultipleImages(
        imageQuality: anyNamed('imageQuality'),
        maxWidth: anyNamed('maxWidth'),
        maxHeight: anyNamed('maxHeight'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await pickMultipleImagesUseCase();

      // Assert
      expect(result, isEmpty);
    });

    test('should respect limit parameter', () async {
      // Arrange
      when(mockPickerService.pickMultipleImages(
        imageQuality: anyNamed('imageQuality'),
        maxWidth: anyNamed('maxWidth'),
        maxHeight: anyNamed('maxHeight'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => [mockFile1, mockFile2]);

      // Act
      await pickMultipleImagesUseCase(limit: 5);

      // Assert
      verify(mockPickerService.pickMultipleImages(
        imageQuality: 85,
        maxWidth: null,
        maxHeight: null,
        limit: 5,
      )).called(1);
    });

    test('should use all custom parameters', () async {
      // Arrange
      when(mockPickerService.pickMultipleImages(
        imageQuality: anyNamed('imageQuality'),
        maxWidth: anyNamed('maxWidth'),
        maxHeight: anyNamed('maxHeight'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => []);

      // Act
      await pickMultipleImagesUseCase(
        imageQuality: 75,
        maxWidth: 1024.0,
        maxHeight: 768.0,
        limit: 10,
      );

      // Assert
      verify(mockPickerService.pickMultipleImages(
        imageQuality: 75,
        maxWidth: 1024.0,
        maxHeight: 768.0,
        limit: 10,
      )).called(1);
    });
  });

  group('PickVideoFromGalleryUseCase', () {
    final mockFile = MockFile();

    test('should return File when video is picked', () async {
      // Arrange
      when(mockPickerService.pickVideoFromGallery(
        maxDuration: anyNamed('maxDuration'),
      )).thenAnswer((_) async => mockFile);

      // Act
      final result = await pickVideoGalleryUseCase();

      // Assert
      expect(result, mockFile);
      verify(mockPickerService.pickVideoFromGallery(maxDuration: null))
          .called(1);
    });

    test('should return null when user cancels', () async {
      // Arrange
      when(mockPickerService.pickVideoFromGallery(
        maxDuration: anyNamed('maxDuration'),
      )).thenAnswer((_) async => null);

      // Act
      final result = await pickVideoGalleryUseCase();

      // Assert
      expect(result, null);
    });

    test('should respect maxDuration parameter', () async {
      // Arrange
      when(mockPickerService.pickVideoFromGallery(
        maxDuration: anyNamed('maxDuration'),
      )).thenAnswer((_) async => mockFile);

      const maxDuration = Duration(seconds: 30);

      // Act
      await pickVideoGalleryUseCase(maxDuration: maxDuration);

      // Assert
      verify(mockPickerService.pickVideoFromGallery(maxDuration: maxDuration))
          .called(1);
    });

    test('should throw PermissionException when permission denied', () async {
      // Arrange
      when(mockPickerService.pickVideoFromGallery(
        maxDuration: anyNamed('maxDuration'),
      )).thenThrow(const PermissionException('Permission denied'));

      // Act & Assert
      expect(
        () => pickVideoGalleryUseCase(),
        throwsA(isA<PermissionException>()),
      );
    });
  });

  group('RecordVideoWithCameraUseCase', () {
    final mockFile = MockFile();

    test('should return File when video is recorded', () async {
      // Arrange
      when(mockPickerService.recordVideoWithCamera(
        maxDuration: anyNamed('maxDuration'),
      )).thenAnswer((_) async => mockFile);

      // Act
      final result = await recordVideoUseCase();

      // Assert
      expect(result, mockFile);
      verify(mockPickerService.recordVideoWithCamera(maxDuration: null))
          .called(1);
    });

    test('should return null when user cancels', () async {
      // Arrange
      when(mockPickerService.recordVideoWithCamera(
        maxDuration: anyNamed('maxDuration'),
      )).thenAnswer((_) async => null);

      // Act
      final result = await recordVideoUseCase();

      // Assert
      expect(result, null);
    });

    test('should respect maxDuration parameter', () async {
      // Arrange
      when(mockPickerService.recordVideoWithCamera(
        maxDuration: anyNamed('maxDuration'),
      )).thenAnswer((_) async => mockFile);

      const maxDuration = Duration(minutes: 1);

      // Act
      await recordVideoUseCase(maxDuration: maxDuration);

      // Assert
      verify(mockPickerService.recordVideoWithCamera(maxDuration: maxDuration))
          .called(1);
    });

    test('should throw PermissionException when camera permission denied',
        () async {
      // Arrange
      when(mockPickerService.recordVideoWithCamera(
        maxDuration: anyNamed('maxDuration'),
      )).thenThrow(const PermissionException('Camera permission denied'));

      // Act & Assert
      expect(
        () => recordVideoUseCase(),
        throwsA(isA<PermissionException>()),
      );
    });

    test('should throw MediaUploadException on recording error', () async {
      // Arrange
      when(mockPickerService.recordVideoWithCamera(
        maxDuration: anyNamed('maxDuration'),
      )).thenThrow(const MediaUploadException('Recording failed'));

      // Act & Assert
      expect(
        () => recordVideoUseCase(),
        throwsA(isA<MediaUploadException>()),
      );
    });
  });
}
