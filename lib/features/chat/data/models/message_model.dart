import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:chatz/features/chat/domain/entities/message_entity.dart';

part 'message_model.g.dart';

/// Media metadata model
@JsonSerializable()
class MediaMetadataModel {
  final String? fileName;
  final int? fileSize;
  final int? duration;
  final String? mimeType;
  final String? thumbnailUrl;

  const MediaMetadataModel({
    this.fileName,
    this.fileSize,
    this.duration,
    this.mimeType,
    this.thumbnailUrl,
  });

  factory MediaMetadataModel.fromJson(Map<String, dynamic> json) =>
      _$MediaMetadataModelFromJson(json);

  Map<String, dynamic> toJson() => _$MediaMetadataModelToJson(this);

  MediaMetadata toEntity() {
    return MediaMetadata(
      fileName: fileName,
      fileSize: fileSize,
      duration: duration,
      mimeType: mimeType,
      thumbnailUrl: thumbnailUrl,
    );
  }

  factory MediaMetadataModel.fromEntity(MediaMetadata entity) {
    return MediaMetadataModel(
      fileName: entity.fileName,
      fileSize: entity.fileSize,
      duration: entity.duration,
      mimeType: entity.mimeType,
      thumbnailUrl: entity.thumbnailUrl,
    );
  }
}

/// Reply metadata model
@JsonSerializable()
class ReplyMetadataModel {
  final String messageId;
  final String content;
  final String senderName;

  const ReplyMetadataModel({
    required this.messageId,
    required this.content,
    required this.senderName,
  });

  factory ReplyMetadataModel.fromJson(Map<String, dynamic> json) =>
      _$ReplyMetadataModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReplyMetadataModelToJson(this);

  ReplyMetadata toEntity() {
    return ReplyMetadata(
      messageId: messageId,
      content: content,
      senderName: senderName,
    );
  }

  factory ReplyMetadataModel.fromEntity(ReplyMetadata entity) {
    return ReplyMetadataModel(
      messageId: entity.messageId,
      content: entity.content,
      senderName: entity.senderName,
    );
  }
}

/// Message model with Firestore serialization
@JsonSerializable(explicitToJson: true)
class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String content;
  final String type;
  final String? mediaUrl;
  final MediaMetadataModel? mediaMetadata;
  final ReplyMetadataModel? replyTo;
  final List<String> readBy;
  final List<String> deliveredTo;
  final Map<String, String> reactions;
  final bool isDeleted;
  final List<String> deletedFor;
  final bool isEdited;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? editedAt;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime createdAt;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime updatedAt;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.content,
    required this.type,
    this.mediaUrl,
    this.mediaMetadata,
    this.replyTo,
    required this.readBy,
    required this.deliveredTo,
    required this.reactions,
    required this.isDeleted,
    required this.deletedFor,
    required this.isEdited,
    this.editedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$MessageModelToJson(this);

  /// Convert from Firestore DocumentSnapshot
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel.fromJson({
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
  MessageEntity toEntity() {
    return MessageEntity(
      id: id,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      content: content,
      type: MessageType.fromString(type),
      mediaUrl: mediaUrl,
      mediaMetadata: mediaMetadata?.toEntity(),
      replyTo: replyTo?.toEntity(),
      readBy: readBy,
      deliveredTo: deliveredTo,
      reactions: reactions,
      isDeleted: isDeleted,
      deletedFor: deletedFor,
      isEdited: isEdited,
      editedAt: editedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create from domain entity
  factory MessageModel.fromEntity(MessageEntity entity) {
    return MessageModel(
      id: entity.id,
      chatId: entity.chatId,
      senderId: entity.senderId,
      senderName: entity.senderName,
      senderPhotoUrl: entity.senderPhotoUrl,
      content: entity.content,
      type: entity.type.value,
      mediaUrl: entity.mediaUrl,
      mediaMetadata: entity.mediaMetadata != null
          ? MediaMetadataModel.fromEntity(entity.mediaMetadata!)
          : null,
      replyTo: entity.replyTo != null
          ? ReplyMetadataModel.fromEntity(entity.replyTo!)
          : null,
      readBy: entity.readBy,
      deliveredTo: entity.deliveredTo,
      reactions: entity.reactions,
      isDeleted: entity.isDeleted,
      deletedFor: entity.deletedFor,
      isEdited: entity.isEdited,
      editedAt: entity.editedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Helper method to convert Firestore Timestamp to DateTime
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

  /// Helper method to convert DateTime to Firestore Timestamp
  static Timestamp _timestampToJson(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }
}
