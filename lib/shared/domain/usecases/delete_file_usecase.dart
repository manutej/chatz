import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/errors/failures.dart';
import '../repositories/storage_repository.dart';

/// Use case for deleting a file from storage
@injectable
class DeleteFileUseCase {
  final StorageRepository _repository;

  DeleteFileUseCase(this._repository);

  /// Execute the use case
  Future<Either<Failure, void>> call(String storagePath) {
    return _repository.deleteFile(storagePath: storagePath);
  }
}

/// Use case for deleting multiple files from storage
@injectable
class DeleteMultipleFilesUseCase {
  final StorageRepository _repository;

  DeleteMultipleFilesUseCase(this._repository);

  /// Execute the use case
  Future<Either<Failure, void>> call(List<String> storagePaths) {
    return _repository.deleteMultipleFiles(storagePaths: storagePaths);
  }
}
