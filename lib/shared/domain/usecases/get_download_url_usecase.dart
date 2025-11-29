import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/errors/failures.dart';
import '../repositories/storage_repository.dart';

/// Use case for getting a download URL for a file
@injectable
class GetDownloadUrlUseCase {
  final StorageRepository _repository;

  GetDownloadUrlUseCase(this._repository);

  /// Execute the use case
  Future<Either<Failure, String>> call(String storagePath) {
    return _repository.getDownloadUrl(storagePath: storagePath);
  }
}
