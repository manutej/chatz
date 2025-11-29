import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chatz/core/errors/failures.dart';
import 'package:chatz/shared/domain/repositories/storage_repository.dart';
import 'package:chatz/shared/domain/usecases/delete_file_usecase.dart';

@GenerateMocks([StorageRepository])
import 'delete_file_usecase_test.mocks.dart';

void main() {
  late DeleteFileUseCase deleteUseCase;
  late DeleteMultipleFilesUseCase deleteMultipleUseCase;
  late MockStorageRepository mockRepository;

  setUp(() {
    mockRepository = MockStorageRepository();
    deleteUseCase = DeleteFileUseCase(mockRepository);
    deleteMultipleUseCase = DeleteMultipleFilesUseCase(mockRepository);
  });

  group('DeleteFileUseCase', () {
    const testPath = 'test/path/file.jpg';

    test('should delete file successfully', () async {
      // Arrange
      when(mockRepository.deleteFile(storagePath: anyNamed('storagePath')))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await deleteUseCase(testPath);

      // Assert
      expect(result.isRight(), true);
      verify(mockRepository.deleteFile(storagePath: testPath)).called(1);
    });

    test('should return failure when deletion fails', () async {
      // Arrange
      when(mockRepository.deleteFile(storagePath: anyNamed('storagePath')))
          .thenAnswer((_) async => const Left(MediaUploadFailure('Delete failed')));

      // Act
      final result = await deleteUseCase(testPath);

      // Assert
      expect(result.isLeft(), true);
      final failure = result.fold((l) => l, (r) => throw Exception());
      expect(failure, isA<MediaUploadFailure>());
      expect(failure.message, 'Delete failed');
    });

    test('should return success when file not found', () async {
      // Arrange
      when(mockRepository.deleteFile(storagePath: anyNamed('storagePath')))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await deleteUseCase(testPath);

      // Assert
      expect(result.isRight(), true);
    });

    test('should return NetworkFailure on network error', () async {
      // Arrange
      when(mockRepository.deleteFile(storagePath: anyNamed('storagePath')))
          .thenAnswer((_) async => const Left(NetworkFailure('Network error')));

      // Act
      final result = await deleteUseCase(testPath);

      // Assert
      expect(result.isLeft(), true);
      final failure = result.fold((l) => l, (r) => throw Exception());
      expect(failure, isA<NetworkFailure>());
    });
  });

  group('DeleteMultipleFilesUseCase', () {
    final testPaths = ['path1.jpg', 'path2.jpg', 'path3.jpg'];

    test('should delete multiple files successfully', () async {
      // Arrange
      when(mockRepository.deleteMultipleFiles(
        storagePaths: anyNamed('storagePaths'),
      )).thenAnswer((_) async => const Right(null));

      // Act
      final result = await deleteMultipleUseCase(testPaths);

      // Assert
      expect(result.isRight(), true);
      verify(mockRepository.deleteMultipleFiles(storagePaths: testPaths))
          .called(1);
    });

    test('should return failure when any deletion fails', () async {
      // Arrange
      when(mockRepository.deleteMultipleFiles(
        storagePaths: anyNamed('storagePaths'),
      )).thenAnswer(
        (_) async => const Left(
          MediaUploadFailure('Failed to delete some files'),
        ),
      );

      // Act
      final result = await deleteMultipleUseCase(testPaths);

      // Assert
      expect(result.isLeft(), true);
      final failure = result.fold((l) => l, (r) => throw Exception());
      expect(failure, isA<MediaUploadFailure>());
    });

    test('should handle empty list of paths', () async {
      // Arrange
      when(mockRepository.deleteMultipleFiles(
        storagePaths: anyNamed('storagePaths'),
      )).thenAnswer((_) async => const Right(null));

      // Act
      final result = await deleteMultipleUseCase([]);

      // Assert
      expect(result.isRight(), true);
      verify(mockRepository.deleteMultipleFiles(storagePaths: [])).called(1);
    });

    test('should handle single file deletion', () async {
      // Arrange
      final singlePath = ['path1.jpg'];

      when(mockRepository.deleteMultipleFiles(
        storagePaths: anyNamed('storagePaths'),
      )).thenAnswer((_) async => const Right(null));

      // Act
      final result = await deleteMultipleUseCase(singlePath);

      // Assert
      expect(result.isRight(), true);
      verify(mockRepository.deleteMultipleFiles(storagePaths: singlePath))
          .called(1);
    });

    test('should return NetworkFailure on network error', () async {
      // Arrange
      when(mockRepository.deleteMultipleFiles(
        storagePaths: anyNamed('storagePaths'),
      )).thenAnswer((_) async => const Left(NetworkFailure('Network error')));

      // Act
      final result = await deleteMultipleUseCase(testPaths);

      // Assert
      expect(result.isLeft(), true);
      final failure = result.fold((l) => l, (r) => throw Exception());
      expect(failure, isA<NetworkFailure>());
    });
  });
}
