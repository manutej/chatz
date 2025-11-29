import 'package:equatable/equatable.dart';

/// Message type enumeration
enum MessageType {
  text,
  image,
  video,
  audio,
  file,
  location;

  String get value => name;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => MessageType.text,
    );
  }
}

/// Media metadata for messages with attachments
class MediaMetadata extends Equatable {
  final String? fileName;
  final int? fileSize;
  final int? duration; // seconds for audio/video
  final String? mimeType;
  final String? thumbnailUrl;

  const MediaMetadata({
    this.fileName,
    this.fileSize,
    this.duration,
    this.mimeType,
    this.thumbnailUrl,
  });

  @override
  List<Object?> get props => [
        fileName,
        fileSize,
        duration,
        mimeType,
        thumbnailUrl,
      ];

  MediaMetadata copyWith({
    String? fileName,
    int? fileSize,
    int? duration,
    String? mimeType,
    String? thumbnailUrl,
  }) {
    return MediaMetadata(
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      mimeType: mimeType ?? this.mimeType,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }
}

/// Reply metadata for messages that reply to another message
class ReplyMetadata extends Equatable {
  final String messageId;
  final String content;
  final String senderName;

  const ReplyMetadata({
    required this.messageId,
    required this.content,
    required this.senderName,
  });

  @override
  List<Object?> get props => [messageId, content, senderName];
}

/// Message entity representing a chat message in the domain layer
class MessageEntity extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String content;
  final MessageType type;
  final String? mediaUrl;
  final MediaMetadata? mediaMetadata;
  final ReplyMetadata? replyTo;
  final List<String> readBy;
  final List<String> deliveredTo;
  final Map<String, String> reactions; // userId -> emoji
  final bool isDeleted;
  final List<String> deletedFor; // userId[] - for "delete for me"
  final bool isEdited;
  final DateTime? editedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MessageEntity({
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

  /// Check if message is read by specific user
  bool isReadBy(String userId) => readBy.contains(userId);

  /// Check if message is delivered to specific user
  bool isDeliveredTo(String userId) => deliveredTo.contains(userId);

  /// Check if message is deleted for specific user
  bool isDeletedFor(String userId) => deletedFor.contains(userId);

  /// Check if message has media attachment
  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;

  /// Check if message is a reply
  bool get isReply => replyTo != null;

  /// Check if message has reactions
  bool get hasReactions => reactions.isNotEmpty;

  /// Get readable file size
  String? get readableFileSize {
    if (mediaMetadata?.fileSize == null) return null;
    final bytes = mediaMetadata!.fileSize!;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  List<Object?> get props => [
        id,
        chatId,
        senderId,
        senderName,
        senderPhotoUrl,
        content,
        type,
        mediaUrl,
        mediaMetadata,
        replyTo,
        readBy,
        deliveredTo,
        reactions,
        isDeleted,
        deletedFor,
        isEdited,
        editedAt,
        createdAt,
        updatedAt,
      ];

  MessageEntity copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? content,
    MessageType? type,
    String? mediaUrl,
    MediaMetadata? mediaMetadata,
    ReplyMetadata? replyTo,
    List<String>? readBy,
    List<String>? deliveredTo,
    Map<String, String>? reactions,
    bool? isDeleted,
    List<String>? deletedFor,
    bool? isEdited,
    DateTime? editedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      content: content ?? this.content,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaMetadata: mediaMetadata ?? this.mediaMetadata,
      replyTo: replyTo ?? this.replyTo,
      readBy: readBy ?? this.readBy,
      deliveredTo: deliveredTo ?? this.deliveredTo,
      reactions: reactions ?? this.reactions,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedFor: deletedFor ?? this.deletedFor,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
