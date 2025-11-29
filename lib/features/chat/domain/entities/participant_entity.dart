import 'package:equatable/equatable.dart';

/// Participant entity representing a chat participant
/// Used within ChatEntity to store participant details
class ParticipantEntity extends Equatable {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final bool isAdmin; // For group chats

  const ParticipantEntity({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    this.isAdmin = false,
  });

  @override
  List<Object?> get props => [userId, displayName, photoUrl, isAdmin];

  ParticipantEntity copyWith({
    String? userId,
    String? displayName,
    String? photoUrl,
    bool? isAdmin,
  }) {
    return ParticipantEntity(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }

  /// Create from map
  factory ParticipantEntity.fromMap(String userId, Map<String, dynamic> map) {
    return ParticipantEntity(
      userId: userId,
      displayName: map['displayName'] as String? ?? 'Unknown',
      photoUrl: map['photoUrl'] as String?,
      isAdmin: false, // This is determined from admins array in ChatEntity
    );
  }
}
