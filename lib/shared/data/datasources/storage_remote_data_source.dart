import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:mime/mime.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../domain/entities/media_entity.dart';
import '../../domain/entities/upload_progress.dart';
import '../../services/file_compression_service.dart';
import '../../services/storage_service.dart';

/// Remote data source for storage operations
@lazySingleton
class StorageRemoteDataSource {
  final StorageService _storageService;
  final FileCompressionService _compressionService;

  StorageRemoteDataSource(
    this._storageService,
    this._compressionService,
  );

  /// Upload media file with compression and progress tracking
  Stream<UploadProgress> uploadMedia({
    required File file,
    required String storagePath,
    required MediaType mediaType,
    bool compress = true,
    Map<String, String>? metadata,
  }) async* {
    final uploadId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      File fileToUpload = file;

      // Compress if needed
      if (compress) {
        yield UploadProgress.compressing(uploadId);

        if (mediaType == MediaType.image || mediaType == MediaType.gif) {
          if (await _compressionService.shouldCompressImage(file)) {
            fileToUpload = await _compressionService.compressImage(file);
          }
        } else if (mediaType == MediaType.video) {
          if (await _compressionService.shouldCompressVideo(file)) {
            fileToUpload = await _compressionService.compressVideo(file);
          }
        }
      }

      // Determine MIME type
      final mimeType = metadata?['contentType'] ??
          lookupMimeType(fileToUpload.path) ??
          _getDefaultMimeType(mediaType);

      final uploadMetadata = {
        ...?metadata,
        'contentType': mimeType,
        'uploadedAt': DateTime.now().toIso8601String(),
      };

      // Upload to Firebase Storage
      await for (final progress in _storageService.uploadFile(
        file: fileToUpload,
        storagePath: storagePath,
        metadata: uploadMetadata,
      )) {
        yield progress;
      }
    } catch (e) {
      AppLogger.e('Media upload failed: $e', error: e);
      yield UploadProgress.failed(
        uploadId,
        error: e.toString(),
      );
    }
  }

  /// Upload profile image
  Stream<UploadProgress> uploadProfileImage({
    required File imageFile,
    required String userId,
    bool compress = true,
  }) async* {
    final storagePath = StorageService.getProfileImagePath(userId);

    await for (final progress in uploadMedia(
      file: imageFile,
      storagePath: storagePath,
      mediaType: MediaType.image,
      compress: compress,
      metadata: {
        'userId': userId,
        'type': 'profile_image',
      },
    )) {
      yield progress;
    }
  }

  /// Upload chat image
  Stream<UploadProgress> uploadChatImage({
    required File imageFile,
    required String chatId,
    required String messageId,
    bool compress = true,
  }) async* {
    final storagePath = StorageService.getChatImagePath(chatId, messageId);

    await for (final progress in uploadMedia(
      file: imageFile,
      storagePath: storagePath,
      mediaType: MediaType.image,
      compress: compress,
      metadata: {
        'chatId': chatId,
        'messageId': messageId,
        'type': 'chat_image',
      },
    )) {
      yield progress;
    }
  }

  /// Upload chat video with thumbnail generation
  Stream<UploadProgress> uploadChatVideo({
    required File videoFile,
    required String chatId,
    required String messageId,
    bool compress = true,
    bool generateThumbnail = true,
  }) async* {
    final uploadId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      // Upload video
      final videoPath = StorageService.getChatVideoPath(chatId, messageId);

      await for (final progress in uploadMedia(
        file: videoFile,
        storagePath: videoPath,
        mediaType: MediaType.video,
        compress: compress,
        metadata: {
          'chatId': chatId,
          'messageId': messageId,
          'type': 'chat_video',
        },
      )) {
        yield progress;

        // If video upload is complete and thumbnail needed, upload thumbnail
        if (generateThumbnail && progress.isCompleted) {
          try {
            final thumbnail = await _compressionService.generateVideoThumbnail(
              videoFile,
            );

            final thumbnailPath = StorageService.getVideoThumbnailPath(
              videoPath,
            );

            // Upload thumbnail silently (don't yield progress)
            await for (final _ in _storageService.uploadFile(
              file: thumbnail,
              storagePath: thumbnailPath,
              metadata: {
                'chatId': chatId,
                'messageId': messageId,
                'type': 'video_thumbnail',
              },
            )) {
              // Consume stream but don't yield
            }

            AppLogger.i('Video thumbnail uploaded: $thumbnailPath');
          } catch (e) {
            AppLogger.e('Failed to upload video thumbnail: $e', error: e);
            // Don't fail the entire operation if thumbnail upload fails
          }
        }
      }
    } catch (e) {
      AppLogger.e('Video upload failed: $e', error: e);
      yield UploadProgress.failed(uploadId, error: e.toString());
    }
  }

  /// Upload chat audio
  Stream<UploadProgress> uploadChatAudio({
    required File audioFile,
    required String chatId,
    required String messageId,
  }) async* {
    final storagePath = StorageService.getChatAudioPath(chatId, messageId);

    await for (final progress in uploadMedia(
      file: audioFile,
      storagePath: storagePath,
      mediaType: MediaType.audio,
      compress: false, // Don't compress audio
      metadata: {
        'chatId': chatId,
        'messageId': messageId,
        'type': 'chat_audio',
      },
    )) {
      yield progress;
    }
  }

  /// Upload chat document
  Stream<UploadProgress> uploadChatDocument({
    required File documentFile,
    required String chatId,
    required String messageId,
    required String fileName,
  }) async* {
    final storagePath = StorageService.getChatDocumentPath(
      chatId,
      messageId,
      fileName,
    );

    await for (final progress in uploadMedia(
      file: documentFile,
      storagePath: storagePath,
      mediaType: MediaType.document,
      compress: false, // Don't compress documents
      metadata: {
        'chatId': chatId,
        'messageId': messageId,
        'fileName': fileName,
        'type': 'chat_document',
      },
    )) {
      yield progress;
    }
  }

  /// Upload status media
  Stream<UploadProgress> uploadStatusMedia({
    required File mediaFile,
    required String userId,
    required String statusId,
    required MediaType mediaType,
    bool compress = true,
  }) async* {
    final storagePath = StorageService.getStatusMediaPath(userId, statusId);

    await for (final progress in uploadMedia(
      file: mediaFile,
      storagePath: storagePath,
      mediaType: mediaType,
      compress: compress,
      metadata: {
        'userId': userId,
        'statusId': statusId,
        'type': 'status_media',
      },
    )) {
      yield progress;
    }
  }

  /// Delete media file
  Future<void> deleteMedia(String storagePath) async {
    try {
      await _storageService.deleteFile(storagePath);
      AppLogger.i('Media deleted: $storagePath');
    } catch (e) {
      AppLogger.e('Failed to delete media: $e', error: e);
      throw MediaUploadException('Failed to delete media: $e');
    }
  }

  /// Delete chat media (including thumbnail if video)
  Future<void> deleteChatMedia({
    required String chatId,
    required String messageId,
    required MediaType mediaType,
    required String? fileName,
  }) async {
    try {
      String storagePath;

      switch (mediaType) {
        case MediaType.image:
        case MediaType.gif:
          storagePath = StorageService.getChatImagePath(chatId, messageId);
          break;
        case MediaType.video:
          storagePath = StorageService.getChatVideoPath(chatId, messageId);
          // Also delete thumbnail
          final thumbnailPath = StorageService.getVideoThumbnailPath(
            storagePath,
          );
          try {
            await _storageService.deleteFile(thumbnailPath);
          } catch (e) {
            AppLogger.w('Failed to delete video thumbnail: $e');
          }
          break;
        case MediaType.audio:
        case MediaType.voice:
          storagePath = StorageService.getChatAudioPath(chatId, messageId);
          break;
        case MediaType.document:
          storagePath = StorageService.getChatDocumentPath(
            chatId,
            messageId,
            fileName ?? 'document',
          );
          break;
      }

      await deleteMedia(storagePath);
    } catch (e) {
      AppLogger.e('Failed to delete chat media: $e', error: e);
      throw MediaUploadException('Failed to delete chat media: $e');
    }
  }

  /// Get download URL
  Future<String> getDownloadUrl(String storagePath) async {
    try {
      return await _storageService.getDownloadUrl(storagePath);
    } catch (e) {
      AppLogger.e('Failed to get download URL: $e', error: e);
      throw MediaUploadException('Failed to get download URL: $e');
    }
  }

  /// Check if file exists
  Future<bool> fileExists(String storagePath) async {
    try {
      return await _storageService.fileExists(storagePath);
    } catch (e) {
      AppLogger.e('Failed to check file existence: $e', error: e);
      return false;
    }
  }

  /// Get user storage size
  Future<int> getUserStorageSize(String userId) async {
    try {
      int totalSize = 0;

      // Profile images
      totalSize += await _storageService.getDirectorySize(
        'profile_images/$userId',
      );

      // Status media
      totalSize += await _storageService.getDirectorySize(
        'status_media/$userId',
      );

      return totalSize;
    } catch (e) {
      AppLogger.e('Failed to get user storage size: $e', error: e);
      return 0;
    }
  }

  /// Get chat storage size
  Future<int> getChatStorageSize(String chatId) async {
    try {
      return await _storageService.getDirectorySize('chat_media/$chatId');
    } catch (e) {
      AppLogger.e('Failed to get chat storage size: $e', error: e);
      return 0;
    }
  }

  /// Get default MIME type for media type
  String _getDefaultMimeType(MediaType mediaType) {
    switch (mediaType) {
      case MediaType.image:
        return 'image/jpeg';
      case MediaType.gif:
        return 'image/gif';
      case MediaType.video:
        return 'video/mp4';
      case MediaType.audio:
      case MediaType.voice:
        return 'audio/m4a';
      case MediaType.document:
        return 'application/octet-stream';
    }
  }
}
