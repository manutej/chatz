import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/logger.dart';
import '../../domain/entities/media_entity.dart';
import '../../domain/entities/upload_progress.dart';
import '../../domain/repositories/storage_repository.dart';
import '../datasources/storage_remote_data_source.dart';

/// Implementation of StorageRepository
@LazySingleton(as: StorageRepository)
class StorageRepositoryImpl implements StorageRepository {
  final StorageRemoteDataSource _remoteDataSource;

  StorageRepositoryImpl(this._remoteDataSource);

  @override
  Stream<Either<Failure, UploadProgress>> uploadFile({
    required File file,
    required String storagePath,
    required MediaType mediaType,
    bool compress = true,
    Map<String, String>? metadata,
  }) async* {
    try {
      await for (final progress in _remoteDataSource.uploadMedia(
        file: file,
        storagePath: storagePath,
        mediaType: mediaType,
        compress: compress,
        metadata: metadata,
      )) {
        yield Right(progress);
      }
    } on NetworkException catch (e) {
      AppLogger.e('Network error during upload: ${e.message}', error: e);
      yield Left(NetworkFailure(e.message));
    } on MediaUploadException catch (e) {
      AppLogger.e('Upload error: ${e.message}', error: e);
      yield Left(MediaUploadFailure(e.message));
    } on PermissionException catch (e) {
      AppLogger.e('Permission error: ${e.message}', error: e);
      yield Left(PermissionFailure(e.message));
    } catch (e) {
      AppLogger.e('Unexpected upload error: $e', error: e);
      yield Left(MediaUploadFailure('Unexpected error: $e'));
    }
  }

  @override
  Stream<Either<Failure, Map<String, UploadProgress>>> uploadMultipleFiles({
    required List<File> files,
    required List<String> storagePaths,
    required MediaType mediaType,
    bool compress = true,
  }) async* {
    if (files.length != storagePaths.length) {
      yield const Left(
        ValidationFailure('Files and storage paths count mismatch'),
      );
      return;
    }

    try {
      final progressMap = <String, UploadProgress>{};

      // Initialize progress for all files
      for (var i = 0; i < files.length; i++) {
        progressMap[storagePaths[i]] = UploadProgress.initial(
          storagePaths[i],
        );
      }

      // Upload all files concurrently
      final uploadStreams = <Stream<UploadProgress>>[];
      for (var i = 0; i < files.length; i++) {
        uploadStreams.add(
          _remoteDataSource.uploadMedia(
            file: files[i],
            storagePath: storagePaths[i],
            mediaType: mediaType,
            compress: compress,
          ),
        );
      }

      // Merge streams and update progress map
      for (var i = 0; i < uploadStreams.length; i++) {
        await for (final progress in uploadStreams[i]) {
          progressMap[storagePaths[i]] = progress;
          yield Right(Map.from(progressMap));
        }
      }
    } on NetworkException catch (e) {
      yield Left(NetworkFailure(e.message));
    } on MediaUploadException catch (e) {
      yield Left(MediaUploadFailure(e.message));
    } catch (e) {
      yield Left(MediaUploadFailure('Failed to upload multiple files: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> downloadFile({
    required String downloadUrl,
    String? fileName,
  }) async {
    try {
      // For now, we just return the download URL
      // In a full implementation, you could download to local storage
      return Right(downloadUrl);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(MediaUploadFailure('Failed to download file: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> getDownloadUrl({
    required String storagePath,
  }) async {
    try {
      final url = await _remoteDataSource.getDownloadUrl(storagePath);
      return Right(url);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on MediaUploadException catch (e) {
      return Left(MediaUploadFailure(e.message));
    } catch (e) {
      return Left(MediaUploadFailure('Failed to get download URL: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFile({
    required String storagePath,
  }) async {
    try {
      await _remoteDataSource.deleteMedia(storagePath);
      return const Right(null);
    } on NotFoundException catch (e) {
      // File not found is considered success for deletion
      AppLogger.w('File not found for deletion: ${e.message}');
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on MediaUploadException catch (e) {
      return Left(MediaUploadFailure(e.message));
    } catch (e) {
      return Left(MediaUploadFailure('Failed to delete file: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMultipleFiles({
    required List<String> storagePaths,
  }) async {
    try {
      for (final path in storagePaths) {
        await _remoteDataSource.deleteMedia(path);
      }
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on MediaUploadException catch (e) {
      return Left(MediaUploadFailure(e.message));
    } catch (e) {
      return Left(MediaUploadFailure('Failed to delete multiple files: $e'));
    }
  }

  @override
  Future<Either<Failure, MediaEntity>> getFileMetadata({
    required String storagePath,
  }) async {
    try {
      // This would require implementing metadata retrieval in data source
      // For now, return a simple implementation
      final url = await _remoteDataSource.getDownloadUrl(storagePath);
      final entity = MediaEntity(
        id: storagePath,
        type: MediaType.document,
        url: url,
        sizeInBytes: 0,
        uploadedAt: DateTime.now(),
      );
      return Right(entity);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(MediaUploadFailure('Failed to get file metadata: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelUpload({
    required String uploadId,
  }) async {
    try {
      // Firebase Storage doesn't support direct cancellation
      // This is a placeholder for future implementation
      return const Right(null);
    } catch (e) {
      return Left(MediaUploadFailure('Failed to cancel upload: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> fileExists({
    required String storagePath,
  }) async {
    try {
      final exists = await _remoteDataSource.fileExists(storagePath);
      return Right(exists);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(MediaUploadFailure('Failed to check file existence: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getUserStorageSize({
    required String userId,
  }) async {
    try {
      final size = await _remoteDataSource.getUserStorageSize(userId);
      return Right(size);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(MediaUploadFailure('Failed to get storage size: $e'));
    }
  }
}
