import 'package:flutter_test/flutter_test.dart';
import 'package:chatz/features/chat/data/models/participant_model.dart';
import 'package:chatz/features/chat/domain/entities/participant_entity.dart';

void main() {
  group('ParticipantModel', () {
    const testUserId = 'test-user-id';
    const testDisplayName = 'Test User';
    const testPhotoUrl = 'https://example.com/photo.jpg';

    const testParticipantModel = ParticipantModel(
      displayName: testDisplayName,
      photoUrl: testPhotoUrl,
    );

    const testJson = {
      'displayName': testDisplayName,
      'photoUrl': testPhotoUrl,
    };

    group('fromJson', () {
      test('should return a valid model from JSON', () {
        // Act
        final result = ParticipantModel.fromJson(testJson);

        // Assert
        expect(result, equals(testParticipantModel));
        expect(result.displayName, testDisplayName);
        expect(result.photoUrl, testPhotoUrl);
      });

      test('should handle null photoUrl', () {
        // Arrange
        const jsonWithNullPhoto = {
          'displayName': testDisplayName,
          'photoUrl': null,
        };

        // Act
        final result = ParticipantModel.fromJson(jsonWithNullPhoto);

        // Assert
        expect(result.displayName, testDisplayName);
        expect(result.photoUrl, isNull);
      });
    });

    group('toJson', () {
      test('should return a JSON map containing proper data', () {
        // Act
        final result = testParticipantModel.toJson();

        // Assert
        expect(result, testJson);
        expect(result['displayName'], testDisplayName);
        expect(result['photoUrl'], testPhotoUrl);
      });

      test('should handle null photoUrl in JSON', () {
        // Arrange
        const modelWithNullPhoto = ParticipantModel(
          displayName: testDisplayName,
          photoUrl: null,
        );

        // Act
        final result = modelWithNullPhoto.toJson();

        // Assert
        expect(result['photoUrl'], isNull);
      });
    });

    group('toEntity', () {
      test('should return a valid ParticipantEntity', () {
        // Act
        final result = testParticipantModel.toEntity(testUserId);

        // Assert
        expect(result, isA<ParticipantEntity>());
        expect(result.userId, testUserId);
        expect(result.displayName, testDisplayName);
        expect(result.photoUrl, testPhotoUrl);
        expect(result.isAdmin, false);
      });

      test('should set isAdmin correctly when provided', () {
        // Act
        final result = testParticipantModel.toEntity(
          testUserId,
          isAdmin: true,
        );

        // Assert
        expect(result.isAdmin, true);
      });

      test('should handle null photoUrl', () {
        // Arrange
        const modelWithNullPhoto = ParticipantModel(
          displayName: testDisplayName,
          photoUrl: null,
        );

        // Act
        final result = modelWithNullPhoto.toEntity(testUserId);

        // Assert
        expect(result.photoUrl, isNull);
      });
    });

    group('fromEntity', () {
      test('should return a valid model from entity', () {
        // Arrange
        const entity = ParticipantEntity(
          userId: testUserId,
          displayName: testDisplayName,
          photoUrl: testPhotoUrl,
          isAdmin: true,
        );

        // Act
        final result = ParticipantModel.fromEntity(entity);

        // Assert
        expect(result.displayName, testDisplayName);
        expect(result.photoUrl, testPhotoUrl);
        // Note: isAdmin is not stored in model, it's in the admins array of ChatModel
      });

      test('should handle null photoUrl in entity', () {
        // Arrange
        const entity = ParticipantEntity(
          userId: testUserId,
          displayName: testDisplayName,
          photoUrl: null,
          isAdmin: false,
        );

        // Act
        final result = ParticipantModel.fromEntity(entity);

        // Assert
        expect(result.photoUrl, isNull);
      });
    });

    group('roundtrip conversion', () {
      test('should maintain data through JSON serialization', () {
        // Act - Convert to JSON and back
        final json = testParticipantModel.toJson();
        final result = ParticipantModel.fromJson(json);

        // Assert
        expect(result, equals(testParticipantModel));
      });

      test('should maintain data through entity conversion', () {
        // Arrange
        const entity = ParticipantEntity(
          userId: testUserId,
          displayName: testDisplayName,
          photoUrl: testPhotoUrl,
          isAdmin: false,
        );

        // Act - Convert to model and back
        final model = ParticipantModel.fromEntity(entity);
        final resultEntity = model.toEntity(testUserId);

        // Assert
        expect(resultEntity.displayName, entity.displayName);
        expect(resultEntity.photoUrl, entity.photoUrl);
        expect(resultEntity.userId, entity.userId);
      });
    });
  });
}
