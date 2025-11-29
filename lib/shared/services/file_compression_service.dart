import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path/path.dart' as path;
import '../../core/errors/exceptions.dart';
import '../../core/utils/logger.dart';

/// Service for compressing images and videos
@lazySingleton
class FileCompressionService {
  // Compression quality settings
  static const int defaultImageQuality = 85;
  static const int maxImageDimension = 1920; // Max width or height for images
  static const int thumbnailSize = 300;

  // Video compression settings
  static const VideoQuality defaultVideoQuality = VideoQuality.MediumQuality;

  /// Compress an image file
  Future<File> compressImage(
    File imageFile, {
    int quality = defaultImageQuality,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      final fileSize = await imageFile.length();
      AppLogger.d(
        'Compressing image: ${imageFile.path} (${_formatBytes(fileSize)})',
      );

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basename(imageFile.path);
      final targetPath = path.join(
        tempDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}_$fileName',
      );

      // Compress image
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth ?? maxImageDimension,
        minHeight: maxHeight ?? maxImageDimension,
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        throw const MediaUploadException('Image compression failed');
      }

      final compressedFile = File(result.path);
      final compressedSize = await compressedFile.length();
      final compressionRatio = ((1 - compressedSize / fileSize) * 100).toInt();

      AppLogger.i(
        'Image compressed: ${_formatBytes(compressedSize)} '
        '(saved $compressionRatio%)',
      );

      return compressedFile;
    } catch (e) {
      AppLogger.e('Image compression failed: $e', error: e);
      if (e is MediaUploadException) rethrow;
      throw MediaUploadException('Image compression failed: $e');
    }
  }

  /// Compress multiple images
  Future<List<File>> compressMultipleImages(
    List<File> imageFiles, {
    int quality = defaultImageQuality,
    int? maxWidth,
    int? maxHeight,
  }) async {
    final compressedFiles = <File>[];

    for (final imageFile in imageFiles) {
      try {
        final compressed = await compressImage(
          imageFile,
          quality: quality,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        );
        compressedFiles.add(compressed);
      } catch (e) {
        AppLogger.e('Failed to compress image: ${imageFile.path}', error: e);
        // Continue with other images, add original if compression fails
        compressedFiles.add(imageFile);
      }
    }

    return compressedFiles;
  }

  /// Generate thumbnail from image
  Future<File> generateImageThumbnail(
    File imageFile, {
    int size = thumbnailSize,
  }) async {
    try {
      AppLogger.d('Generating thumbnail for: ${imageFile.path}');

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basename(imageFile.path);
      final targetPath = path.join(
        tempDir.path,
        'thumb_${DateTime.now().millisecondsSinceEpoch}_$fileName',
      );

      // Generate thumbnail
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: 70,
        minWidth: size,
        minHeight: size,
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        throw const MediaUploadException('Thumbnail generation failed');
      }

      AppLogger.i('Thumbnail generated: ${result.path}');
      return File(result.path);
    } catch (e) {
      AppLogger.e('Thumbnail generation failed: $e', error: e);
      if (e is MediaUploadException) rethrow;
      throw MediaUploadException('Thumbnail generation failed: $e');
    }
  }

  /// Compress a video file
  Future<File> compressVideo(
    File videoFile, {
    VideoQuality quality = defaultVideoQuality,
  }) async {
    try {
      final fileSize = await videoFile.length();
      AppLogger.d(
        'Compressing video: ${videoFile.path} (${_formatBytes(fileSize)})',
      );

      final info = await VideoCompress.compressVideo(
        videoFile.path,
        quality: quality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (info == null || info.file == null) {
        throw const MediaUploadException('Video compression failed');
      }

      final compressedFile = info.file!;
      final compressedSize = await compressedFile.length();
      final compressionRatio = ((1 - compressedSize / fileSize) * 100).toInt();

      AppLogger.i(
        'Video compressed: ${_formatBytes(compressedSize)} '
        '(saved $compressionRatio%)',
      );

      return compressedFile;
    } catch (e) {
      AppLogger.e('Video compression failed: $e', error: e);
      if (e is MediaUploadException) rethrow;
      throw MediaUploadException('Video compression failed: $e');
    }
  }

  /// Generate thumbnail from video
  Future<File> generateVideoThumbnail(
    File videoFile, {
    int timeMs = 0,
    int quality = 80,
  }) async {
    try {
      AppLogger.d('Generating video thumbnail: ${videoFile.path}');

      final thumbnailFile = await VideoCompress.getFileThumbnail(
        videoFile.path,
        quality: quality,
        position: timeMs,
      );

      AppLogger.i('Video thumbnail generated: ${thumbnailFile.path}');
      return thumbnailFile;
    } catch (e) {
      AppLogger.e('Video thumbnail generation failed: $e', error: e);
      throw MediaUploadException('Video thumbnail generation failed: $e');
    }
  }

  /// Get video metadata (duration, dimensions, size)
  Future<MediaInfo?> getVideoInfo(File videoFile) async {
    try {
      final info = await VideoCompress.getMediaInfo(videoFile.path);
      AppLogger.d(
        'Video info - Duration: ${info.duration}s, '
        'Size: ${info.width}x${info.height}',
      );
      return info;
    } catch (e) {
      AppLogger.e('Failed to get video info: $e', error: e);
      return null;
    }
  }

  /// Check if file needs compression
  Future<bool> shouldCompressImage(
    File imageFile, {
    int maxSizeInBytes = 1024 * 1024, // 1MB default
  }) async {
    final fileSize = await imageFile.length();
    return fileSize > maxSizeInBytes;
  }

  /// Check if video needs compression
  Future<bool> shouldCompressVideo(
    File videoFile, {
    int maxSizeInBytes = 50 * 1024 * 1024, // 50MB default
  }) async {
    final fileSize = await videoFile.length();
    return fileSize > maxSizeInBytes;
  }

  /// Delete video compression cache
  Future<void> deleteVideoCache() async {
    try {
      await VideoCompress.deleteAllCache();
      AppLogger.i('Video compression cache cleared');
    } catch (e) {
      AppLogger.e('Failed to clear video cache: $e', error: e);
    }
  }

  /// Cancel ongoing video compression
  void cancelVideoCompression() {
    VideoCompress.cancelCompression();
    AppLogger.i('Video compression cancelled');
  }

  /// Get compression progress stream for video
  Stream<double> get videoCompressionProgress {
    return VideoCompress.compressProgress$;
  }

  /// Format bytes to human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Dispose resources
  void dispose() {
    cancelVideoCompression();
  }
}
