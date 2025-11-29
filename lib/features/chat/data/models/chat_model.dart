import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:chatz/features/chat/domain/entities/chat_entity.dart';
import 'package:chatz/features/chat/domain/entities/participant_entity.dart';
import 'package:chatz/features/chat/data/models/participant_model.dart';

part 'chat_model.g.dart';

/// Last message model
@JsonSerializable()
class LastMessageModel {
  final String content;
  final String senderId;
  final String senderName;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime timestamp;
  final String type;

  const LastMessageModel({
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    required this.type,
  });

  factory LastMessageModel.fromJson(Map<String, dynamic> json) =>
      _$LastMessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$LastMessageModelToJson(this);

  LastMessage toEntity() {
    return LastMessage(
      content: content,
      senderId: senderId,
      senderName: senderName,
      timestamp: timestamp,
      type: type,
    );
  }

  factory LastMessageModel.fromEntity(LastMessage entity) {
    return LastMessageModel(
      content: entity.content,
      senderId: entity.senderId,
      senderName: entity.senderName,
      timestamp: entity.timestamp,
      type: entity.type,
    );
  }

  static DateTime _timestampFromJson(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    }
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    if (timestamp is String) {
      return DateTime.parse(timestamp);
    }
    return DateTime.now();
  }

  static Timestamp _timestampToJson(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }
}

/// Chat model with Firestore serialization
@JsonSerializable(explicitToJson: true)
class ChatModel {
  final String id;
  final String type;
  final String? name;
  final String? description;
  final String? photoUrl;
  final List<String> participants;
  final Map<String, dynamic> participantDetails;
  final String createdBy;
  final List<String> admins;
  final LastMessageModel? lastMessage;
  final Map<String, int> unreadCount;
  final Map<String, bool> isArchived;
  final Map<String, bool> isPinned;
  final Map<String, bool> isMuted;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime createdAt;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime updatedAt;

  const ChatModel({
    required this.id,
    required this.type,
    this.name,
    this.description,
    this.photoUrl,
    required this.participants,
    required this.participantDetails,
    required this.createdBy,
    required this.admins,
    this.lastMessage,
    required this.unreadCount,
    required this.isArchived,
    required this.isPinned,
    required this.isMuted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) =>
      _$ChatModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatModelToJson(this);

  /// Convert from Firestore DocumentSnapshot
  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel.fromJson({
      ...data,
      'id': doc.id,
    });
  }

  /// Convert to Firestore map (without id)
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Firestore uses document ID separately
    return json;
  }

  /// Convert to domain entity
  ChatEntity toEntity() {
    // Convert participantDetails map to ParticipantEntity map
    final Map<String, ParticipantEntity> participantEntities = {};
    participantDetails.forEach((userId, details) {
      if (details is Map<String, dynamic>) {
        final model = ParticipantModel.fromJson(details);
        participantEntities[userId] = model.toEntity(
          userId,
          isAdmin: admins.contains(userId),
        );
      }
    });

    return ChatEntity(
      id: id,
      type: ChatType.fromString(type),
      name: name,
      description: description,
      photoUrl: photoUrl,
      participantIds: participants,
      participantDetails: participantEntities,
      createdBy: createdBy,
      admins: admins,
      lastMessage: lastMessage?.toEntity(),
      unreadCount: unreadCount,
      isArchived: isArchived,
      isPinned: isPinned,
      isMuted: isMuted,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create from domain entity
  factory ChatModel.fromEntity(ChatEntity entity) {
    // Convert ParticipantEntity map to JSON map
    final Map<String, dynamic> participantDetailsJson = {};
    entity.participantDetails.forEach((userId, participant) {
      participantDetailsJson[userId] =
          ParticipantModel.fromEntity(participant).toJson();
    });

    return ChatModel(
      id: entity.id,
      type: entity.type.toFirestoreValue(),
      name: entity.name,
      description: entity.description,
      photoUrl: entity.photoUrl,
      participants: entity.participantIds,
      participantDetails: participantDetailsJson,
      createdBy: entity.createdBy,
      admins: entity.admins,
      lastMessage: entity.lastMessage != null
          ? LastMessageModel.fromEntity(entity.lastMessage!)
          : null,
      unreadCount: entity.unreadCount,
      isArchived: entity.isArchived,
      isPinned: entity.isPinned,
      isMuted: entity.isMuted,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  static DateTime _timestampFromJson(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    }
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    if (timestamp is String) {
      return DateTime.parse(timestamp);
    }
    return DateTime.now();
  }

  static Timestamp _timestampToJson(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }
}
