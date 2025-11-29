import 'dart:io';
import 'package:injectable/injectable.dart';
import '../../services/image_picker_service.dart';

/// Use case for picking images from gallery
@injectable
class PickImageFromGalleryUseCase {
  final ImagePickerService _pickerService;

  PickImageFromGalleryUseCase(this._pickerService);

  /// Execute the use case
  Future<File?> call({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) {
    return _pickerService.pickImageFromGallery(
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }
}

/// Use case for picking images from camera
@injectable
class PickImageFromCameraUseCase {
  final ImagePickerService _pickerService;

  PickImageFromCameraUseCase(this._pickerService);

  /// Execute the use case
  Future<File?> call({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) {
    return _pickerService.pickImageFromCamera(
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }
}

/// Use case for picking multiple images
@injectable
class PickMultipleImagesUseCase {
  final ImagePickerService _pickerService;

  PickMultipleImagesUseCase(this._pickerService);

  /// Execute the use case
  Future<List<File>> call({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
    int? limit,
  }) {
    return _pickerService.pickMultipleImages(
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      limit: limit,
    );
  }
}

/// Use case for picking videos from gallery
@injectable
class PickVideoFromGalleryUseCase {
  final ImagePickerService _pickerService;

  PickVideoFromGalleryUseCase(this._pickerService);

  /// Execute the use case
  Future<File?> call({Duration? maxDuration}) {
    return _pickerService.pickVideoFromGallery(maxDuration: maxDuration);
  }
}

/// Use case for recording video with camera
@injectable
class RecordVideoWithCameraUseCase {
  final ImagePickerService _pickerService;

  RecordVideoWithCameraUseCase(this._pickerService);

  /// Execute the use case
  Future<File?> call({Duration? maxDuration}) {
    return _pickerService.recordVideoWithCamera(maxDuration: maxDuration);
  }
}
