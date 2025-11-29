import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:chatz/features/auth/domain/entities/user_entity.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// User model for data layer
/// Handles JSON serialization/deserialization for Firebase Firestore
@freezed
class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    required String id,
    String? email,
    String? phoneNumber,
    String? displayName,
    String? photoUrl,
    String? bio,
    required DateTime createdAt,
    DateTime? lastSeen,
    @Default(false) bool isOnline,
    @Default(false) bool isEmailVerified,
    @Default(false) bool isPhoneVerified,
    @Default([]) List<String> deviceTokens,
    Map<String, dynamic>? metadata,
  }) = _UserModel;

  /// Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Convert UserModel to UserEntity (domain layer)
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      phoneNumber: phoneNumber,
      displayName: displayName,
      photoUrl: photoUrl,
      bio: bio,
      createdAt: createdAt,
      lastSeen: lastSeen,
      isOnline: isOnline,
      isEmailVerified: isEmailVerified,
      isPhoneVerified: isPhoneVerified,
      deviceTokens: deviceTokens,
      metadata: metadata,
    );
  }

  /// Create UserModel from UserEntity (domain layer)
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      phoneNumber: entity.phoneNumber,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      bio: entity.bio,
      createdAt: entity.createdAt,
      lastSeen: entity.lastSeen,
      isOnline: entity.isOnline,
      isEmailVerified: entity.isEmailVerified,
      isPhoneVerified: entity.isPhoneVerified,
      deviceTokens: entity.deviceTokens,
      metadata: entity.metadata,
    );
  }

  /// Create UserModel from Firestore DocumentSnapshot
  factory UserModel.fromFirestore(Map<String, dynamic> doc, String id) {
    return UserModel(
      id: id,
      email: doc['email'] as String?,
      phoneNumber: doc['phoneNumber'] as String?,
      displayName: doc['displayName'] as String?,
      photoUrl: doc['photoUrl'] as String?,
      bio: doc['bio'] as String?,
      createdAt: (doc['createdAt'] as num?)?.toInt() != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (doc['createdAt'] as num).toInt())
          : DateTime.now(),
      lastSeen: (doc['lastSeen'] as num?)?.toInt() != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (doc['lastSeen'] as num).toInt())
          : null,
      isOnline: doc['isOnline'] as bool? ?? false,
      isEmailVerified: doc['isEmailVerified'] as bool? ?? false,
      isPhoneVerified: doc['isPhoneVerified'] as bool? ?? false,
      deviceTokens: (doc['deviceTokens'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      metadata: doc['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert UserModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bio': bio,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
      'isOnline': isOnline,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'deviceTokens': deviceTokens,
      'metadata': metadata,
    };
  }
}
