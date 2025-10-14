import 'package:equatable/equatable.dart';

/// User entity representing a user in the domain layer
class UserEntity extends Equatable {
  final String id;
  final String phoneNumber;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final String? about;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.phoneNumber,
    this.displayName,
    this.email,
    this.photoUrl,
    this.about,
    required this.isOnline,
    this.lastSeen,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of the entity with updated fields
  UserEntity copyWith({
    String? id,
    String? phoneNumber,
    String? displayName,
    String? email,
    String? photoUrl,
    String? about,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      about: about ?? this.about,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        phoneNumber,
        displayName,
        email,
        photoUrl,
        about,
        isOnline,
        lastSeen,
        createdAt,
        updatedAt,
      ];
}
