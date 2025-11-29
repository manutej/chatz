import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/errors/failures.dart';
import '../entities/media_entity.dart';
import '../entities/upload_progress.dart';
import '../repositories/storage_repository.dart';

/// Use case for uploading a file to storage
@injectable
class UploadFileUseCase {
  final StorageRepository _repository;

  UploadFileUseCase(this._repository);

  /// Execute the use case
  Stream<Either<Failure, UploadProgress>> call(UploadFileParams params) {
    return _repository.uploadFile(
      file: params.file,
      storagePath: params.storagePath,
      mediaType: params.mediaType,
      compress: params.compress,
      metadata: params.metadata,
    );
  }
}

/// Parameters for UploadFileUseCase
class UploadFileParams {
  final File file;
  final String storagePath;
  final MediaType mediaType;
  final bool compress;
  final Map<String, String>? metadata;

  const UploadFileParams({
    required this.file,
    required this.storagePath,
    required this.mediaType,
    this.compress = true,
    this.metadata,
  });
}
