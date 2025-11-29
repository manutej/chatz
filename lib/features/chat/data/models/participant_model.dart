import 'package:json_annotation/json_annotation.dart';
import 'package:chatz/features/chat/domain/entities/participant_entity.dart';

part 'participant_model.g.dart';

/// Participant model with JSON serialization
@JsonSerializable()
class ParticipantModel {
  final String displayName;
  final String? photoUrl;

  const ParticipantModel({
    required this.displayName,
    this.photoUrl,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) =>
      _$ParticipantModelFromJson(json);

  Map<String, dynamic> toJson() => _$ParticipantModelToJson(this);

  /// Convert to domain entity
  ParticipantEntity toEntity(String userId, {bool isAdmin = false}) {
    return ParticipantEntity(
      userId: userId,
      displayName: displayName,
      photoUrl: photoUrl,
      isAdmin: isAdmin,
    );
  }

  /// Create from domain entity
  factory ParticipantModel.fromEntity(ParticipantEntity entity) {
    return ParticipantModel(
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
    );
  }
}
