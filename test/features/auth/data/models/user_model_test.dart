import 'package:flutter_test/flutter_test.dart';
import 'package:chatz/features/auth/data/models/user_model.dart';
import 'package:chatz/features/auth/domain/entities/user_entity.dart';

void main() {
  final tDateTime = DateTime(2024, 1, 1);

  const tUserModel = UserModel(
    id: 'user_123',
    email: 'test@example.com',
    phoneNumber: '+1234567890',
    displayName: 'Test User',
    photoUrl: 'https://example.com/photo.jpg',
    bio: 'Test bio',
    createdAt: DateTime(2024, 1, 1),
    lastSeen: DateTime(2024, 1, 2),
    isOnline: true,
    isEmailVerified: true,
    isPhoneVerified: true,
    deviceTokens: ['token1', 'token2'],
    metadata: {'key': 'value'},
  );

  final tUserEntity = UserEntity(
    id: 'user_123',
    email: 'test@example.com',
    phoneNumber: '+1234567890',
    displayName: 'Test User',
    photoUrl: 'https://example.com/photo.jpg',
    bio: 'Test bio',
    createdAt: DateTime(2024, 1, 1),
    lastSeen: DateTime(2024, 1, 2),
    isOnline: true,
    isEmailVerified: true,
    isPhoneVerified: true,
    deviceTokens: const ['token1', 'token2'],
    metadata: const {'key': 'value'},
  );

  group('UserModel', () {
    group('fromJson', () {
      test('should return valid UserModel from JSON', () {
        // arrange
        final json = {
          'id': 'user_123',
          'email': 'test@example.com',
          'phoneNumber': '+1234567890',
          'displayName': 'Test User',
          'photoUrl': 'https://example.com/photo.jpg',
          'bio': 'Test bio',
          'createdAt': '2024-01-01T00:00:00.000',
          'lastSeen': '2024-01-02T00:00:00.000',
          'isOnline': true,
          'isEmailVerified': true,
          'isPhoneVerified': true,
          'deviceTokens': ['token1', 'token2'],
          'metadata': {'key': 'value'},
        };

        // act
        final result = UserModel.fromJson(json);

        // assert
        expect(result, isA<UserModel>());
        expect(result.id, 'user_123');
        expect(result.email, 'test@example.com');
        expect(result.displayName, 'Test User');
      });

      test('should handle null values in JSON', () {
        // arrange
        final json = {
          'id': 'user_123',
          'createdAt': '2024-01-01T00:00:00.000',
        };

        // act
        final result = UserModel.fromJson(json);

        // assert
        expect(result.id, 'user_123');
        expect(result.email, null);
        expect(result.phoneNumber, null);
        expect(result.displayName, null);
        expect(result.isOnline, false);
        expect(result.deviceTokens, []);
      });
    });

    group('toJson', () {
      test('should return valid JSON map from UserModel', () {
        // act
        final json = tUserModel.toJson();

        // assert
        expect(json, isA<Map<String, dynamic>>());
        expect(json['id'], 'user_123');
        expect(json['email'], 'test@example.com');
        expect(json['phoneNumber'], '+1234567890');
        expect(json['displayName'], 'Test User');
        expect(json['isOnline'], true);
      });
    });

    group('fromFirestore', () {
      test('should create UserModel from Firestore document', () {
        // arrange
        final doc = {
          'email': 'test@example.com',
          'phoneNumber': '+1234567890',
          'displayName': 'Test User',
          'photoUrl': 'https://example.com/photo.jpg',
          'bio': 'Test bio',
          'createdAt': 1704067200000, // 2024-01-01 00:00:00 in milliseconds
          'lastSeen': 1704153600000, // 2024-01-02 00:00:00 in milliseconds
          'isOnline': true,
          'isEmailVerified': true,
          'isPhoneVerified': true,
          'deviceTokens': ['token1', 'token2'],
          'metadata': {'key': 'value'},
        };
        const id = 'user_123';

        // act
        final result = UserModel.fromFirestore(doc, id);

        // assert
        expect(result.id, 'user_123');
        expect(result.email, 'test@example.com');
        expect(result.phoneNumber, '+1234567890');
        expect(result.displayName, 'Test User');
        expect(result.isOnline, true);
      });

      test('should handle missing fields in Firestore document', () {
        // arrange
        final doc = <String, dynamic>{};
        const id = 'user_123';

        // act
        final result = UserModel.fromFirestore(doc, id);

        // assert
        expect(result.id, 'user_123');
        expect(result.email, null);
        expect(result.phoneNumber, null);
        expect(result.displayName, null);
        expect(result.isOnline, false);
        expect(result.isEmailVerified, false);
        expect(result.isPhoneVerified, false);
        expect(result.deviceTokens, []);
      });

      test('should handle null timestamp values', () {
        // arrange
        final doc = {
          'email': 'test@example.com',
          'createdAt': null,
          'lastSeen': null,
        };
        const id = 'user_123';

        // act
        final result = UserModel.fromFirestore(doc, id);

        // assert
        expect(result.id, 'user_123');
        expect(result.email, 'test@example.com');
        expect(result.createdAt, isA<DateTime>());
        expect(result.lastSeen, null);
      });
    });

    group('toFirestore', () {
      test('should convert UserModel to Firestore document', () {
        // act
        final result = tUserModel.toFirestore();

        // assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['email'], 'test@example.com');
        expect(result['phoneNumber'], '+1234567890');
        expect(result['displayName'], 'Test User');
        expect(result['isOnline'], true);
        expect(result['createdAt'], isA<int>());
        expect(result['deviceTokens'], ['token1', 'token2']);
      });

      test('should convert DateTime to milliseconds', () {
        // act
        final result = tUserModel.toFirestore();

        // assert
        expect(result['createdAt'], isA<int>());
        expect(result['lastSeen'], isA<int>());
      });

      test('should handle null lastSeen', () {
        // arrange
        const model = UserModel(
          id: 'user_123',
          createdAt: DateTime(2024, 1, 1),
        );

        // act
        final result = model.toFirestore();

        // assert
        expect(result['lastSeen'], null);
      });
    });

    group('toEntity', () {
      test('should convert UserModel to UserEntity', () {
        // act
        final entity = tUserModel.toEntity();

        // assert
        expect(entity, isA<UserEntity>());
        expect(entity.id, tUserModel.id);
        expect(entity.email, tUserModel.email);
        expect(entity.phoneNumber, tUserModel.phoneNumber);
        expect(entity.displayName, tUserModel.displayName);
        expect(entity.photoUrl, tUserModel.photoUrl);
        expect(entity.bio, tUserModel.bio);
        expect(entity.isOnline, tUserModel.isOnline);
        expect(entity.isEmailVerified, tUserModel.isEmailVerified);
        expect(entity.isPhoneVerified, tUserModel.isPhoneVerified);
      });
    });

    group('fromEntity', () {
      test('should convert UserEntity to UserModel', () {
        // act
        final model = UserModel.fromEntity(tUserEntity);

        // assert
        expect(model, isA<UserModel>());
        expect(model.id, tUserEntity.id);
        expect(model.email, tUserEntity.email);
        expect(model.phoneNumber, tUserEntity.phoneNumber);
        expect(model.displayName, tUserEntity.displayName);
        expect(model.photoUrl, tUserEntity.photoUrl);
        expect(model.bio, tUserEntity.bio);
        expect(model.isOnline, tUserEntity.isOnline);
        expect(model.isEmailVerified, tUserEntity.isEmailVerified);
        expect(model.isPhoneVerified, tUserEntity.isPhoneVerified);
      });
    });

    group('copyWith', () {
      test('should return new instance with updated values', () {
        // act
        final updated = tUserModel.copyWith(
          displayName: 'Updated Name',
          isOnline: false,
        );

        // assert
        expect(updated.id, tUserModel.id);
        expect(updated.email, tUserModel.email);
        expect(updated.displayName, 'Updated Name');
        expect(updated.isOnline, false);
      });

      test('should return new instance with same values when no params', () {
        // act
        final updated = tUserModel.copyWith();

        // assert
        expect(updated.id, tUserModel.id);
        expect(updated.email, tUserModel.email);
        expect(updated.displayName, tUserModel.displayName);
        expect(updated.isOnline, tUserModel.isOnline);
      });
    });

    group('equality', () {
      test('should be equal when all properties are the same', () {
        // arrange
        const model1 = UserModel(
          id: 'user_123',
          email: 'test@example.com',
          createdAt: DateTime(2024, 1, 1),
        );
        const model2 = UserModel(
          id: 'user_123',
          email: 'test@example.com',
          createdAt: DateTime(2024, 1, 1),
        );

        // assert
        expect(model1, model2);
      });

      test('should not be equal when properties differ', () {
        // arrange
        const model1 = UserModel(
          id: 'user_123',
          email: 'test1@example.com',
          createdAt: DateTime(2024, 1, 1),
        );
        const model2 = UserModel(
          id: 'user_123',
          email: 'test2@example.com',
          createdAt: DateTime(2024, 1, 1),
        );

        // assert
        expect(model1, isNot(model2));
      });
    });
  });
}
