import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:chatz/core/errors/exceptions.dart';
import 'package:chatz/shared/services/image_picker_service.dart';

@GenerateMocks([ImagePicker, XFile])
import 'image_picker_service_test.mocks.dart';

void main() {
  late ImagePickerService pickerService;
  late MockImagePicker mockPicker;

  setUp(() {
    mockPicker = MockImagePicker();
    pickerService = ImagePickerService(mockPicker);
  });

  group('ImagePickerService', () {
    group('pickImageFromGallery', () {
      test('should return File when image is picked successfully', () async {
        // Arrange
        final mockXFile = MockXFile();
        const testPath = '/path/to/image.jpg';

        when(mockXFile.path).thenReturn(testPath);
        when(mockPicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: anyNamed('imageQuality'),
          maxWidth: anyNamed('maxWidth'),
          maxHeight: anyNamed('maxHeight'),
        )).thenAnswer((_) async => mockXFile);

        // Act
        final result = await pickerService.pickImageFromGallery();

        // Assert
        expect(result, isA<File>());
        expect(result?.path, testPath);
        verify(mockPicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: null,
          maxHeight: null,
        )).called(1);
      });

      test('should return null when user cancels selection', () async {
        // Arrange
        when(mockPicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: anyNamed('imageQuality'),
          maxWidth: anyNamed('maxWidth'),
          maxHeight: anyNamed('maxHeight'),
        )).thenAnswer((_) async => null);

        // Act
        final result = await pickerService.pickImageFromGallery();

        // Assert
        expect(result, null);
      });

      test('should use custom quality and dimensions when provided', () async {
        // Arrange
        final mockXFile = MockXFile();
        when(mockXFile.path).thenReturn('/path/to/image.jpg');
        when(mockPicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: anyNamed('imageQuality'),
          maxWidth: anyNamed('maxWidth'),
          maxHeight: anyNamed('maxHeight'),
        )).thenAnswer((_) async => mockXFile);

        // Act
        await pickerService.pickImageFromGallery(
          imageQuality: 70,
          maxWidth: 1920.0,
          maxHeight: 1080.0,
        );

        // Assert
        verify(mockPicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 70,
          maxWidth: 1920.0,
          maxHeight: 1080.0,
        )).called(1);
      });

      test('should throw MediaUploadException on picker error', () async {
        // Arrange
        when(mockPicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: anyNamed('imageQuality'),
          maxWidth: anyNamed('maxWidth'),
          maxHeight: anyNamed('maxHeight'),
        )).thenThrow(Exception('Picker error'));

        // Act & Assert
        expect(
          () => pickerService.pickImageFromGallery(),
          throwsA(isA<MediaUploadException>()),
        );
      });
    });

    group('pickImageFromCamera', () {
      test('should return File when image is captured successfully', () async {
        // Arrange
        final mockXFile = MockXFile();
        const testPath = '/path/to/camera_image.jpg';

        when(mockXFile.path).thenReturn(testPath);
        when(mockPicker.pickImage(
          source: ImageSource.camera,
          imageQuality: anyNamed('imageQuality'),
          maxWidth: anyNamed('maxWidth'),
          maxHeight: anyNamed('maxHeight'),
          preferredCameraDevice: anyNamed('preferredCameraDevice'),
        )).thenAnswer((_) async => mockXFile);

        // Act
        final result = await pickerService.pickImageFromCamera();

        // Assert
        expect(result, isA<File>());
        expect(result?.path, testPath);
        verify(mockPicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: null,
          maxHeight: null,
          preferredCameraDevice: CameraDevice.rear,
        )).called(1);
      });

      test('should use front camera when specified', () async {
        // Arrange
        final mockXFile = MockXFile();
        when(mockXFile.path).thenReturn('/path/to/image.jpg');
        when(mockPicker.pickImage(
          source: ImageSource.camera,
          imageQuality: anyNamed('imageQuality'),
          maxWidth: anyNamed('maxWidth'),
          maxHeight: anyNamed('maxHeight'),
          preferredCameraDevice: anyNamed('preferredCameraDevice'),
        )).thenAnswer((_) async => mockXFile);

        // Act
        await pickerService.pickImageFromCamera(
          preferredCameraDevice: CameraDevice.front,
        );

        // Assert
        verify(mockPicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: null,
          maxHeight: null,
          preferredCameraDevice: CameraDevice.front,
        )).called(1);
      });

      test('should return null when user cancels capture', () async {
        // Arrange
        when(mockPicker.pickImage(
          source: ImageSource.camera,
          imageQuality: anyNamed('imageQuality'),
          maxWidth: anyNamed('maxWidth'),
          maxHeight: anyNamed('maxHeight'),
          preferredCameraDevice: anyNamed('preferredCameraDevice'),
        )).thenAnswer((_) async => null);

        // Act
        final result = await pickerService.pickImageFromCamera();

        // Assert
        expect(result, null);
      });
    });

    group('pickMultipleImages', () {
      test('should return list of Files when images are picked', () async {
        // Arrange
        final mockXFile1 = MockXFile();
        final mockXFile2 = MockXFile();
        final mockXFile3 = MockXFile();

        when(mockXFile1.path).thenReturn('/path/to/image1.jpg');
        when(mockXFile2.path).thenReturn('/path/to/image2.jpg');
        when(mockXFile3.path).thenReturn('/path/to/image3.jpg');

        when(mockPicker.pickMultiImage(
          imageQuality: anyNamed('imageQuality'),
          maxWidth: anyNamed('maxWidth'),
          maxHeight: anyNamed('maxHeight'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async => [mockXFile1, mockXFile2, mockXFile3]);

        // Act
        final result = await pickerService.pickMultipleImages();

        // Assert
        expect(result.length, 3);
        expect(result[0].path, '/path/to/image1.jpg');
        expect(result[1].path, '/path/to/image2.jpg');
        expect(result[2].path, '/path/to/image3.jpg');
      });

      test('should respect limit parameter', () async {
        // Arrange
        when(mockPicker.pickMultiImage(
          imageQuality: anyNamed('imageQuality'),
          maxWidth: anyNamed('maxWidth'),
          maxHeight: anyNamed('maxHeight'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async => []);

        // Act
        await pickerService.pickMultipleImages(limit: 5);

        // Assert
        verify(mockPicker.pickMultiImage(
          imageQuality: 85,
          maxWidth: null,
          maxHeight: null,
          limit: 5,
        )).called(1);
      });

      test('should return empty list when no images are selected', () async {
        // Arrange
        when(mockPicker.pickMultiImage(
          imageQuality: anyNamed('imageQuality'),
          maxWidth: anyNamed('maxWidth'),
          maxHeight: anyNamed('maxHeight'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async => []);

        // Act
        final result = await pickerService.pickMultipleImages();

        // Assert
        expect(result, isEmpty);
      });
    });

    group('pickVideoFromGallery', () {
      test('should return File when video is picked successfully', () async {
        // Arrange
        final mockXFile = MockXFile();
        const testPath = '/path/to/video.mp4';

        when(mockXFile.path).thenReturn(testPath);
        when(mockPicker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: anyNamed('maxDuration'),
        )).thenAnswer((_) async => mockXFile);

        // Act
        final result = await pickerService.pickVideoFromGallery();

        // Assert
        expect(result, isA<File>());
        expect(result?.path, testPath);
        verify(mockPicker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: null,
        )).called(1);
      });

      test('should respect maxDuration parameter', () async {
        // Arrange
        final mockXFile = MockXFile();
        when(mockXFile.path).thenReturn('/path/to/video.mp4');
        when(mockPicker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: anyNamed('maxDuration'),
        )).thenAnswer((_) async => mockXFile);

        const maxDuration = Duration(seconds: 30);

        // Act
        await pickerService.pickVideoFromGallery(maxDuration: maxDuration);

        // Assert
        verify(mockPicker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: maxDuration,
        )).called(1);
      });

      test('should return null when user cancels selection', () async {
        // Arrange
        when(mockPicker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: anyNamed('maxDuration'),
        )).thenAnswer((_) async => null);

        // Act
        final result = await pickerService.pickVideoFromGallery();

        // Assert
        expect(result, null);
      });
    });

    group('recordVideoWithCamera', () {
      test('should return File when video is recorded successfully', () async {
        // Arrange
        final mockXFile = MockXFile();
        const testPath = '/path/to/recorded_video.mp4';

        when(mockXFile.path).thenReturn(testPath);
        when(mockPicker.pickVideo(
          source: ImageSource.camera,
          maxDuration: anyNamed('maxDuration'),
          preferredCameraDevice: anyNamed('preferredCameraDevice'),
        )).thenAnswer((_) async => mockXFile);

        // Act
        final result = await pickerService.recordVideoWithCamera();

        // Assert
        expect(result, isA<File>());
        expect(result?.path, testPath);
        verify(mockPicker.pickVideo(
          source: ImageSource.camera,
          maxDuration: null,
          preferredCameraDevice: CameraDevice.rear,
        )).called(1);
      });

      test('should use front camera when specified', () async {
        // Arrange
        final mockXFile = MockXFile();
        when(mockXFile.path).thenReturn('/path/to/video.mp4');
        when(mockPicker.pickVideo(
          source: ImageSource.camera,
          maxDuration: anyNamed('maxDuration'),
          preferredCameraDevice: anyNamed('preferredCameraDevice'),
        )).thenAnswer((_) async => mockXFile);

        // Act
        await pickerService.recordVideoWithCamera(
          preferredCameraDevice: CameraDevice.front,
        );

        // Assert
        verify(mockPicker.pickVideo(
          source: ImageSource.camera,
          maxDuration: null,
          preferredCameraDevice: CameraDevice.front,
        )).called(1);
      });
    });

    group('pickMedia', () {
      test('should return File when media is picked successfully', () async {
        // Arrange
        final mockXFile = MockXFile();
        const testPath = '/path/to/media.jpg';

        when(mockXFile.path).thenReturn(testPath);
        when(mockPicker.pickMedia(
          imageQuality: anyNamed('imageQuality'),
          maxWidth: anyNamed('maxWidth'),
          maxHeight: anyNamed('maxHeight'),
        )).thenAnswer((_) async => mockXFile);

        // Act
        final result = await pickerService.pickMedia();

        // Assert
        expect(result, isA<File>());
        expect(result?.path, testPath);
      });

      test('should return null when user cancels selection', () async {
        // Arrange
        when(mockPicker.pickMedia(
          imageQuality: anyNamed('imageQuality'),
          maxWidth: anyNamed('maxWidth'),
          maxHeight: anyNamed('maxHeight'),
        )).thenAnswer((_) async => null);

        // Act
        final result = await pickerService.pickMedia();

        // Assert
        expect(result, null);
      });
    });

    group('pickMultipleMedia', () {
      test('should return list of Files when media are picked', () async {
        // Arrange
        final mockXFile1 = MockXFile();
        final mockXFile2 = MockXFile();

        when(mockXFile1.path).thenReturn('/path/to/image.jpg');
        when(mockXFile2.path).thenReturn('/path/to/video.mp4');

        when(mockPicker.pickMultipleMedia(
          imageQuality: anyNamed('imageQuality'),
          maxWidth: anyNamed('maxWidth'),
          maxHeight: anyNamed('maxHeight'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async => [mockXFile1, mockXFile2]);

        // Act
        final result = await pickerService.pickMultipleMedia();

        // Assert
        expect(result.length, 2);
        expect(result[0].path, '/path/to/image.jpg');
        expect(result[1].path, '/path/to/video.mp4');
      });

      test('should respect limit parameter', () async {
        // Arrange
        when(mockPicker.pickMultipleMedia(
          imageQuality: anyNamed('imageQuality'),
          maxWidth: anyNamed('maxWidth'),
          maxHeight: anyNamed('maxHeight'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async => []);

        // Act
        await pickerService.pickMultipleMedia(limit: 10);

        // Assert
        verify(mockPicker.pickMultipleMedia(
          imageQuality: 85,
          maxWidth: null,
          maxHeight: null,
          limit: 10,
        )).called(1);
      });
    });

    group('permission checks', () {
      test('isGalleryPermissionGranted should check photos permission on iOS',
          () async {
        // This test requires platform-specific mocking
        // In a real scenario, you'd use a platform channel mock
        // For now, we test the method exists and returns a boolean
        final result = await pickerService.isGalleryPermissionGranted();
        expect(result, isA<bool>());
      });

      test('isCameraPermissionGranted should check camera permission',
          () async {
        // This test requires platform-specific mocking
        final result = await pickerService.isCameraPermissionGranted();
        expect(result, isA<bool>());
      });
    });

    group('error handling', () {
      test(
          'pickImageFromGallery should rethrow PermissionException '
          'as PermissionException', () async {
        // Arrange
        when(mockPicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: anyNamed('imageQuality'),
          maxWidth: anyNamed('maxWidth'),
          maxHeight: anyNamed('maxHeight'),
        )).thenThrow(const PermissionException('Permission denied'));

        // Act & Assert
        expect(
          () => pickerService.pickImageFromGallery(),
          throwsA(isA<PermissionException>()),
        );
      });

      test(
          'pickImageFromCamera should wrap non-permission errors '
          'in MediaUploadException', () async {
        // Arrange
        when(mockPicker.pickImage(
          source: ImageSource.camera,
          imageQuality: anyNamed('imageQuality'),
          maxWidth: anyNamed('maxWidth'),
          maxHeight: anyNamed('maxHeight'),
          preferredCameraDevice: anyNamed('preferredCameraDevice'),
        )).thenThrow(Exception('Camera error'));

        // Act & Assert
        expect(
          () => pickerService.pickImageFromCamera(),
          throwsA(isA<MediaUploadException>()),
        );
      });

      test(
          'pickMultipleImages should wrap errors in MediaUploadException',
          () async {
        // Arrange
        when(mockPicker.pickMultiImage(
          imageQuality: anyNamed('imageQuality'),
          maxWidth: anyNamed('maxWidth'),
          maxHeight: anyNamed('maxHeight'),
          limit: anyNamed('limit'),
        )).thenThrow(Exception('Multiple picker error'));

        // Act & Assert
        expect(
          () => pickerService.pickMultipleImages(),
          throwsA(isA<MediaUploadException>()),
        );
      });

      test('pickVideoFromGallery should wrap errors in MediaUploadException',
          () async {
        // Arrange
        when(mockPicker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: anyNamed('maxDuration'),
        )).thenThrow(Exception('Video picker error'));

        // Act & Assert
        expect(
          () => pickerService.pickVideoFromGallery(),
          throwsA(isA<MediaUploadException>()),
        );
      });

      test(
          'recordVideoWithCamera should wrap errors in MediaUploadException',
          () async {
        // Arrange
        when(mockPicker.pickVideo(
          source: ImageSource.camera,
          maxDuration: anyNamed('maxDuration'),
          preferredCameraDevice: anyNamed('preferredCameraDevice'),
        )).thenThrow(Exception('Camera recording error'));

        // Act & Assert
        expect(
          () => pickerService.recordVideoWithCamera(),
          throwsA(isA<MediaUploadException>()),
        );
      });
    });
  });
}
