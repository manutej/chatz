import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/logger.dart';

/// Service for picking images and videos from gallery or camera
@lazySingleton
class ImagePickerService {
  final ImagePicker _picker;

  ImagePickerService(this._picker);

  /// Pick an image from gallery
  Future<File?> pickImageFromGallery({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      // Request permission
      if (!await _requestGalleryPermission()) {
        throw const PermissionException('Gallery permission denied');
      }

      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (pickedFile != null) {
        AppLogger.i('Image picked from gallery: ${pickedFile.path}');
        return File(pickedFile.path);
      }

      return null;
    } catch (e) {
      AppLogger.e('Failed to pick image from gallery: $e', error: e);
      if (e is PermissionException) rethrow;
      throw MediaUploadException('Failed to pick image: $e');
    }
  }

  /// Pick an image from camera
  Future<File?> pickImageFromCamera({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    try {
      // Request permission
      if (!await _requestCameraPermission()) {
        throw const PermissionException('Camera permission denied');
      }

      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        preferredCameraDevice: preferredCameraDevice,
      );

      if (pickedFile != null) {
        AppLogger.i('Image captured from camera: ${pickedFile.path}');
        return File(pickedFile.path);
      }

      return null;
    } catch (e) {
      AppLogger.e('Failed to capture image from camera: $e', error: e);
      if (e is PermissionException) rethrow;
      throw MediaUploadException('Failed to capture image: $e');
    }
  }

  /// Pick multiple images from gallery
  Future<List<File>> pickMultipleImages({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
    int? limit,
  }) async {
    try {
      // Request permission
      if (!await _requestGalleryPermission()) {
        throw const PermissionException('Gallery permission denied');
      }

      final pickedFiles = await _picker.pickMultiImage(
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        limit: limit,
      );

      final files = pickedFiles.map((xFile) => File(xFile.path)).toList();
      AppLogger.i('Picked ${files.length} images from gallery');

      return files;
    } catch (e) {
      AppLogger.e('Failed to pick multiple images: $e', error: e);
      if (e is PermissionException) rethrow;
      throw MediaUploadException('Failed to pick images: $e');
    }
  }

  /// Pick a video from gallery
  Future<File?> pickVideoFromGallery({
    Duration? maxDuration,
  }) async {
    try {
      // Request permission
      if (!await _requestGalleryPermission()) {
        throw const PermissionException('Gallery permission denied');
      }

      final pickedFile = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: maxDuration,
      );

      if (pickedFile != null) {
        AppLogger.i('Video picked from gallery: ${pickedFile.path}');
        return File(pickedFile.path);
      }

      return null;
    } catch (e) {
      AppLogger.e('Failed to pick video from gallery: $e', error: e);
      if (e is PermissionException) rethrow;
      throw MediaUploadException('Failed to pick video: $e');
    }
  }

  /// Record a video with camera
  Future<File?> recordVideoWithCamera({
    Duration? maxDuration,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    try {
      // Request permission
      if (!await _requestCameraPermission()) {
        throw const PermissionException('Camera permission denied');
      }

      final pickedFile = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: maxDuration,
        preferredCameraDevice: preferredCameraDevice,
      );

      if (pickedFile != null) {
        AppLogger.i('Video recorded with camera: ${pickedFile.path}');
        return File(pickedFile.path);
      }

      return null;
    } catch (e) {
      AppLogger.e('Failed to record video with camera: $e', error: e);
      if (e is PermissionException) rethrow;
      throw MediaUploadException('Failed to record video: $e');
    }
  }

  /// Pick media (image or video)
  Future<File?> pickMedia({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
    Duration? maxDuration,
  }) async {
    try {
      // Request permission
      if (!await _requestGalleryPermission()) {
        throw const PermissionException('Gallery permission denied');
      }

      final pickedFile = await _picker.pickMedia(
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (pickedFile != null) {
        AppLogger.i('Media picked: ${pickedFile.path}');
        return File(pickedFile.path);
      }

      return null;
    } catch (e) {
      AppLogger.e('Failed to pick media: $e', error: e);
      if (e is PermissionException) rethrow;
      throw MediaUploadException('Failed to pick media: $e');
    }
  }

  /// Pick multiple media files (images or videos)
  Future<List<File>> pickMultipleMedia({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
    int? limit,
  }) async {
    try {
      // Request permission
      if (!await _requestGalleryPermission()) {
        throw const PermissionException('Gallery permission denied');
      }

      final pickedFiles = await _picker.pickMultipleMedia(
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        limit: limit,
      );

      final files = pickedFiles.map((xFile) => File(xFile.path)).toList();
      AppLogger.i('Picked ${files.length} media files');

      return files;
    } catch (e) {
      AppLogger.e('Failed to pick multiple media: $e', error: e);
      if (e is PermissionException) rethrow;
      throw MediaUploadException('Failed to pick media: $e');
    }
  }

  /// Request gallery permission
  Future<bool> _requestGalleryPermission() async {
    if (Platform.isAndroid) {
      // Android 13+ uses different permissions
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 33) {
        final status = await Permission.photos.request();
        return status.isGranted;
      } else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }
    return true; // Other platforms
  }

  /// Request camera permission
  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Get Android SDK version
  Future<int> _getAndroidVersion() async {
    if (Platform.isAndroid) {
      // For simplicity, we assume Android 13+
      // In production, use device_info_plus to get actual version
      return 33;
    }
    return 0;
  }

  /// Check if gallery permission is granted
  Future<bool> isGalleryPermissionGranted() async {
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 33) {
        return await Permission.photos.isGranted;
      } else {
        return await Permission.storage.isGranted;
      }
    } else if (Platform.isIOS) {
      return await Permission.photos.isGranted;
    }
    return true;
  }

  /// Check if camera permission is granted
  Future<bool> isCameraPermissionGranted() async {
    return await Permission.camera.isGranted;
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
