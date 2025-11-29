import 'package:equatable/equatable.dart';

/// User entity representing the domain model
/// This is the core business object independent of data layer implementations
class UserEntity extends Equatable {
  final String id;
  final String? email;
  final String? phoneNumber;
  final String? displayName;
  final String? photoUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime? lastSeen;
  final bool isOnline;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final List<String> deviceTokens;
  final Map<String, dynamic>? metadata;

  const UserEntity({
    required this.id,
    this.email,
    this.phoneNumber,
    this.displayName,
    this.photoUrl,
    this.bio,
    required this.createdAt,
    this.lastSeen,
    this.isOnline = false,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.deviceTokens = const [],
    this.metadata,
  });

  /// Check if user has completed profile setup
  bool get hasCompletedProfile => displayName != null && displayName!.isNotEmpty;

  /// Get user's primary identifier (phone or email)
  String? get primaryIdentifier => phoneNumber ?? email;

  /// Check if user has any verification
  bool get isVerified => isEmailVerified || isPhoneVerified;

  @override
  List<Object?> get props => [
        id,
        email,
        phoneNumber,
        displayName,
        photoUrl,
        bio,
        createdAt,
        lastSeen,
        isOnline,
        isEmailVerified,
        isPhoneVerified,
        deviceTokens,
        metadata,
      ];

  /// Create a copy with updated fields
  UserEntity copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    String? displayName,
    String? photoUrl,
    String? bio,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isOnline,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    List<String>? deviceTokens,
    Map<String, dynamic>? metadata,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      deviceTokens: deviceTokens ?? this.deviceTokens,
      metadata: metadata ?? this.metadata,
    );
  }
}
