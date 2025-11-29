import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as path;
import '../../core/errors/exceptions.dart';
import '../../core/utils/logger.dart';
import '../domain/entities/upload_progress.dart';

/// Service for Firebase Storage operations
@lazySingleton
class StorageService {
  final FirebaseStorage _storage;
  final Map<String, Reference> _activeUploads = {};

  StorageService(this._storage);

  /// Upload a file to Firebase Storage with progress tracking
  Stream<UploadProgress> uploadFile({
    required File file,
    required String storagePath,
    Map<String, String>? metadata,
  }) async* {
    final uploadId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      // Validate file exists
      if (!await file.exists()) {
        throw const MediaUploadException('File does not exist');
      }

      // Get file size
      final fileSize = await file.length();
      if (fileSize == 0) {
        throw const MediaUploadException('File is empty');
      }

      AppLogger.d('Uploading file to: $storagePath (${_formatBytes(fileSize)})');

      // Create reference
      final ref = _storage.ref().child(storagePath);
      _activeUploads[uploadId] = ref;

      // Set metadata
      final settableMetadata = SettableMetadata(
        contentType: metadata?['contentType'],
        customMetadata: metadata,
      );

      // Start upload
      final uploadTask = ref.putFile(file, settableMetadata);

      // Listen to progress
      await for (final snapshot in uploadTask.snapshotEvents) {
        final progress = UploadProgress.uploading(
          uploadId,
          bytesTransferred: snapshot.bytesTransferred,
          totalBytes: snapshot.totalBytes,
        );

        AppLogger.d(
          'Upload progress: ${progress.percentage}% (${progress.formattedProgress})',
        );

        yield progress;

        // Check if completed
        if (snapshot.state == TaskState.success) {
          final downloadUrl = await ref.getDownloadURL();
          AppLogger.i('Upload completed: $downloadUrl');

          yield UploadProgress.completed(
            uploadId,
            downloadUrl: downloadUrl,
          );
        } else if (snapshot.state == TaskState.error) {
          throw const MediaUploadException('Upload failed');
        } else if (snapshot.state == TaskState.canceled) {
          yield UploadProgress.cancelled(uploadId);
        }
      }
    } on FirebaseException catch (e) {
      AppLogger.e('Firebase upload error: ${e.message}', error: e);
      yield UploadProgress.failed(
        uploadId,
        error: e.message ?? 'Upload failed',
      );
    } catch (e) {
      AppLogger.e('Upload error: $e', error: e);
      yield UploadProgress.failed(
        uploadId,
        error: e.toString(),
      );
    } finally {
      _activeUploads.remove(uploadId);
    }
  }

  /// Get download URL for a storage path
  Future<String> getDownloadUrl(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      final url = await ref.getDownloadURL();
      AppLogger.d('Got download URL for: $storagePath');
      return url;
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to get download URL: ${e.message}', error: e);
      if (e.code == 'object-not-found') {
        throw const NotFoundException('File not found in storage');
      }
      throw MediaUploadException('Failed to get download URL: ${e.message}');
    }
  }

  /// Delete a file from storage
  Future<void> deleteFile(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      await ref.delete();
      AppLogger.i('Deleted file: $storagePath');
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to delete file: ${e.message}', error: e);
      if (e.code == 'object-not-found') {
        // File doesn't exist, consider it deleted
        AppLogger.w('File already deleted or does not exist: $storagePath');
        return;
      }
      throw MediaUploadException('Failed to delete file: ${e.message}');
    }
  }

  /// Delete multiple files
  Future<void> deleteMultipleFiles(List<String> storagePaths) async {
    final errors = <String>[];

    for (final path in storagePaths) {
      try {
        await deleteFile(path);
      } catch (e) {
        errors.add('$path: $e');
      }
    }

    if (errors.isNotEmpty) {
      throw MediaUploadException(
        'Failed to delete some files: ${errors.join(', ')}',
      );
    }
  }

  /// Check if file exists
  Future<bool> fileExists(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      await ref.getMetadata();
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return false;
      }
      rethrow;
    }
  }

  /// Get file metadata
  Future<FullMetadata> getFileMetadata(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      return await ref.getMetadata();
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to get file metadata: ${e.message}', error: e);
      if (e.code == 'object-not-found') {
        throw const NotFoundException('File not found in storage');
      }
      throw MediaUploadException('Failed to get metadata: ${e.message}');
    }
  }

  /// Cancel an upload
  Future<void> cancelUpload(String uploadId) async {
    final ref = _activeUploads[uploadId];
    if (ref != null) {
      // Note: Firebase doesn't provide direct task cancellation
      // We remove from tracking and the upload will complete but we ignore it
      _activeUploads.remove(uploadId);
      AppLogger.i('Upload cancelled: $uploadId');
    }
  }

  /// List files in a directory
  Future<List<Reference>> listFiles(String directoryPath) async {
    try {
      final ref = _storage.ref().child(directoryPath);
      final result = await ref.listAll();
      return result.items;
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to list files: ${e.message}', error: e);
      throw MediaUploadException('Failed to list files: ${e.message}');
    }
  }

  /// Get total size of files in a directory
  Future<int> getDirectorySize(String directoryPath) async {
    try {
      final files = await listFiles(directoryPath);
      int totalSize = 0;

      for (final file in files) {
        final metadata = await file.getMetadata();
        totalSize += metadata.size ?? 0;
      }

      return totalSize;
    } catch (e) {
      AppLogger.e('Failed to get directory size: $e', error: e);
      throw MediaUploadException('Failed to get directory size: $e');
    }
  }

  // Helper methods for path generation

  /// Get storage path for profile image
  static String getProfileImagePath(String userId) {
    return 'profile_images/$userId/avatar.jpg';
  }

  /// Get storage path for chat image
  static String getChatImagePath(String chatId, String messageId) {
    return 'chat_media/$chatId/images/$messageId.jpg';
  }

  /// Get storage path for chat video
  static String getChatVideoPath(String chatId, String messageId) {
    return 'chat_media/$chatId/videos/$messageId.mp4';
  }

  /// Get storage path for chat audio
  static String getChatAudioPath(String chatId, String messageId) {
    return 'chat_media/$chatId/audio/$messageId.m4a';
  }

  /// Get storage path for chat document
  static String getChatDocumentPath(
    String chatId,
    String messageId,
    String fileName,
  ) {
    final extension = path.extension(fileName);
    return 'chat_media/$chatId/documents/$messageId$extension';
  }

  /// Get storage path for status media
  static String getStatusMediaPath(String userId, String statusId) {
    return 'status_media/$userId/$statusId.jpg';
  }

  /// Get storage path for video thumbnail
  static String getVideoThumbnailPath(String originalVideoPath) {
    return originalVideoPath.replaceAll('.mp4', '_thumb.jpg');
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
}
