import 'package:flutter_test/flutter_test.dart';
import 'package:chatz/shared/data/models/media_model.dart';
import 'package:chatz/shared/domain/entities/media_entity.dart';

void main() {
  group('MediaModel', () {
    final testDateTime = DateTime(2025, 1, 15, 12, 0, 0);

    final tMediaModel = MediaModel(
      id: 'test-id-123',
      type: 'image',
      url: 'https://example.com/image.jpg',
      localPath: '/local/path/image.jpg',
      sizeInBytes: 1024000,
      mimeType: 'image/jpeg',
      width: 1920,
      height: 1080,
      durationInSeconds: null,
      thumbnailUrl: 'https://example.com/thumb.jpg',
      uploadedAt: testDateTime,
    );

    final tMediaEntity = MediaEntity(
      id: 'test-id-123',
      type: MediaType.image,
      url: 'https://example.com/image.jpg',
      localPath: '/local/path/image.jpg',
      sizeInBytes: 1024000,
      mimeType: 'image/jpeg',
      width: 1920,
      height: 1080,
      durationInSeconds: null,
      thumbnailUrl: 'https://example.com/thumb.jpg',
      uploadedAt: testDateTime,
    );

    group('fromJson', () {
      test('should deserialize from JSON correctly', () {
        // Arrange
        final json = {
          'id': 'test-id-123',
          'type': 'image',
          'url': 'https://example.com/image.jpg',
          'localPath': '/local/path/image.jpg',
          'sizeInBytes': 1024000,
          'mimeType': 'image/jpeg',
          'width': 1920,
          'height': 1080,
          'durationInSeconds': null,
          'thumbnailUrl': 'https://example.com/thumb.jpg',
          'uploadedAt': testDateTime.toIso8601String(),
        };

        // Act
        final result = MediaModel.fromJson(json);

        // Assert
        expect(result.id, 'test-id-123');
        expect(result.type, 'image');
        expect(result.url, 'https://example.com/image.jpg');
        expect(result.localPath, '/local/path/image.jpg');
        expect(result.sizeInBytes, 1024000);
        expect(result.mimeType, 'image/jpeg');
        expect(result.width, 1920);
        expect(result.height, 1080);
        expect(result.durationInSeconds, null);
        expect(result.thumbnailUrl, 'https://example.com/thumb.jpg');
        expect(result.uploadedAt, testDateTime);
      });

      test('should deserialize video type correctly', () {
        // Arrange
        final json = {
          'id': 'video-id',
          'type': 'video',
          'url': 'https://example.com/video.mp4',
          'sizeInBytes': 5000000,
          'width': 1920,
          'height': 1080,
          'durationInSeconds': 120,
          'thumbnailUrl': 'https://example.com/video-thumb.jpg',
          'uploadedAt': testDateTime.toIso8601String(),
        };

        // Act
        final result = MediaModel.fromJson(json);

        // Assert
        expect(result.type, 'video');
        expect(result.durationInSeconds, 120);
      });

      test('should handle null optional fields', () {
        // Arrange
        final json = {
          'id': 'minimal-id',
          'type': 'document',
          'url': 'https://example.com/doc.pdf',
          'sizeInBytes': 50000,
          'uploadedAt': testDateTime.toIso8601String(),
        };

        // Act
        final result = MediaModel.fromJson(json);

        // Assert
        expect(result.localPath, null);
        expect(result.mimeType, null);
        expect(result.width, null);
        expect(result.height, null);
        expect(result.durationInSeconds, null);
        expect(result.thumbnailUrl, null);
      });
    });

    group('toJson', () {
      test('should serialize to JSON correctly', () {
        // Act
        final result = tMediaModel.toJson();

        // Assert
        expect(result['id'], 'test-id-123');
        expect(result['type'], 'image');
        expect(result['url'], 'https://example.com/image.jpg');
        expect(result['localPath'], '/local/path/image.jpg');
        expect(result['sizeInBytes'], 1024000);
        expect(result['mimeType'], 'image/jpeg');
        expect(result['width'], 1920);
        expect(result['height'], 1080);
        expect(result['durationInSeconds'], null);
        expect(result['thumbnailUrl'], 'https://example.com/thumb.jpg');
        expect(result['uploadedAt'], testDateTime.toIso8601String());
      });

      test('should serialize with null fields correctly', () {
        // Arrange
        final model = MediaModel(
          id: 'minimal-id',
          type: 'audio',
          url: 'https://example.com/audio.mp3',
          sizeInBytes: 30000,
          uploadedAt: testDateTime,
        );

        // Act
        final result = model.toJson();

        // Assert
        expect(result['localPath'], null);
        expect(result['width'], null);
        expect(result['height'], null);
      });
    });

    group('toEntity', () {
      test('should convert to MediaEntity correctly', () {
        // Act
        final result = tMediaModel.toEntity();

        // Assert
        expect(result, isA<MediaEntity>());
        expect(result.id, tMediaEntity.id);
        expect(result.type, tMediaEntity.type);
        expect(result.url, tMediaEntity.url);
        expect(result.localPath, tMediaEntity.localPath);
        expect(result.sizeInBytes, tMediaEntity.sizeInBytes);
        expect(result.mimeType, tMediaEntity.mimeType);
        expect(result.width, tMediaEntity.width);
        expect(result.height, tMediaEntity.height);
        expect(result.durationInSeconds, tMediaEntity.durationInSeconds);
        expect(result.thumbnailUrl, tMediaEntity.thumbnailUrl);
        expect(result.uploadedAt, tMediaEntity.uploadedAt);
      });

      test('should parse all MediaType enums correctly', () {
        // Test image type
        expect(
          MediaModel(
            id: '1',
            type: 'image',
            url: 'url',
            sizeInBytes: 100,
            uploadedAt: testDateTime,
          ).toEntity().type,
          MediaType.image,
        );

        // Test video type
        expect(
          MediaModel(
            id: '1',
            type: 'video',
            url: 'url',
            sizeInBytes: 100,
            uploadedAt: testDateTime,
          ).toEntity().type,
          MediaType.video,
        );

        // Test audio type
        expect(
          MediaModel(
            id: '1',
            type: 'audio',
            url: 'url',
            sizeInBytes: 100,
            uploadedAt: testDateTime,
          ).toEntity().type,
          MediaType.audio,
        );

        // Test document type
        expect(
          MediaModel(
            id: '1',
            type: 'document',
            url: 'url',
            sizeInBytes: 100,
            uploadedAt: testDateTime,
          ).toEntity().type,
          MediaType.document,
        );

        // Test voice type
        expect(
          MediaModel(
            id: '1',
            type: 'voice',
            url: 'url',
            sizeInBytes: 100,
            uploadedAt: testDateTime,
          ).toEntity().type,
          MediaType.voice,
        );

        // Test gif type
        expect(
          MediaModel(
            id: '1',
            type: 'gif',
            url: 'url',
            sizeInBytes: 100,
            uploadedAt: testDateTime,
          ).toEntity().type,
          MediaType.gif,
        );
      });

      test('should default to document type for unknown types', () {
        // Arrange
        final model = MediaModel(
          id: '1',
          type: 'unknown_type',
          url: 'url',
          sizeInBytes: 100,
          uploadedAt: testDateTime,
        );

        // Act
        final result = model.toEntity();

        // Assert
        expect(result.type, MediaType.document);
      });

      test('should handle case-insensitive type parsing', () {
        // Test uppercase
        expect(
          MediaModel(
            id: '1',
            type: 'IMAGE',
            url: 'url',
            sizeInBytes: 100,
            uploadedAt: testDateTime,
          ).toEntity().type,
          MediaType.image,
        );

        // Test mixed case
        expect(
          MediaModel(
            id: '1',
            type: 'ViDeO',
            url: 'url',
            sizeInBytes: 100,
            uploadedAt: testDateTime,
          ).toEntity().type,
          MediaType.video,
        );
      });
    });

    group('fromEntity', () {
      test('should convert from MediaEntity correctly', () {
        // Act
        final result = MediaModel.fromEntity(tMediaEntity);

        // Assert
        expect(result, isA<MediaModel>());
        expect(result.id, tMediaModel.id);
        expect(result.type, tMediaModel.type);
        expect(result.url, tMediaModel.url);
        expect(result.localPath, tMediaModel.localPath);
        expect(result.sizeInBytes, tMediaModel.sizeInBytes);
        expect(result.mimeType, tMediaModel.mimeType);
        expect(result.width, tMediaModel.width);
        expect(result.height, tMediaModel.height);
        expect(result.durationInSeconds, tMediaModel.durationInSeconds);
        expect(result.thumbnailUrl, tMediaModel.thumbnailUrl);
        expect(result.uploadedAt, tMediaModel.uploadedAt);
      });

      test('should convert MediaType enums to strings correctly', () {
        // Test all media types
        final types = [
          MediaType.image,
          MediaType.video,
          MediaType.audio,
          MediaType.document,
          MediaType.voice,
          MediaType.gif,
        ];

        for (final type in types) {
          final entity = MediaEntity(
            id: '1',
            type: type,
            url: 'url',
            sizeInBytes: 100,
            uploadedAt: testDateTime,
          );

          final result = MediaModel.fromEntity(entity);
          expect(result.type, type.name);
        }
      });

      test('should handle entity with null optional fields', () {
        // Arrange
        final entity = MediaEntity(
          id: 'minimal-id',
          type: MediaType.audio,
          url: 'https://example.com/audio.mp3',
          sizeInBytes: 30000,
          uploadedAt: testDateTime,
        );

        // Act
        final result = MediaModel.fromEntity(entity);

        // Assert
        expect(result.localPath, null);
        expect(result.mimeType, null);
        expect(result.width, null);
        expect(result.height, null);
        expect(result.durationInSeconds, null);
        expect(result.thumbnailUrl, null);
      });
    });

    group('round-trip conversion', () {
      test('should maintain data integrity through entity conversion', () {
        // Act
        final entity = tMediaModel.toEntity();
        final modelAgain = MediaModel.fromEntity(entity);

        // Assert
        expect(modelAgain.id, tMediaModel.id);
        expect(modelAgain.type, tMediaModel.type);
        expect(modelAgain.url, tMediaModel.url);
        expect(modelAgain.sizeInBytes, tMediaModel.sizeInBytes);
      });

      test('should maintain data integrity through JSON serialization', () {
        // Act
        final json = tMediaModel.toJson();
        final modelAgain = MediaModel.fromJson(json);

        // Assert
        expect(modelAgain.id, tMediaModel.id);
        expect(modelAgain.type, tMediaModel.type);
        expect(modelAgain.url, tMediaModel.url);
        expect(modelAgain.sizeInBytes, tMediaModel.sizeInBytes);
      });
    });
  });
}
