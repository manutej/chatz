import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../entities/media_entity.dart';
import '../entities/upload_progress.dart';

/// Repository interface for storage operations
abstract class StorageRepository {
  /// Upload a file to storage
  /// Returns a stream of upload progress
  Stream<Either<Failure, UploadProgress>> uploadFile({
    required File file,
    required String storagePath,
    required MediaType mediaType,
    bool compress = true,
    Map<String, String>? metadata,
  });

  /// Upload multiple files
  Stream<Either<Failure, Map<String, UploadProgress>>> uploadMultipleFiles({
    required List<File> files,
    required List<String> storagePaths,
    required MediaType mediaType,
    bool compress = true,
  });

  /// Download a file from storage
  /// Returns the local file path
  Future<Either<Failure, String>> downloadFile({
    required String downloadUrl,
    String? fileName,
  });

  /// Get download URL for a storage path
  Future<Either<Failure, String>> getDownloadUrl({
    required String storagePath,
  });

  /// Delete a file from storage
  Future<Either<Failure, void>> deleteFile({
    required String storagePath,
  });

  /// Delete multiple files from storage
  Future<Either<Failure, void>> deleteMultipleFiles({
    required List<String> storagePaths,
  });

  /// Get file metadata
  Future<Either<Failure, MediaEntity>> getFileMetadata({
    required String storagePath,
  });

  /// Cancel an ongoing upload
  Future<Either<Failure, void>> cancelUpload({
    required String uploadId,
  });

  /// Check if file exists in storage
  Future<Either<Failure, bool>> fileExists({
    required String storagePath,
  });

  /// Get total storage used by user
  Future<Either<Failure, int>> getUserStorageSize({
    required String userId,
  });
}
