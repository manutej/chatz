import 'package:equatable/equatable.dart';
import 'package:chatz/features/chat/domain/entities/participant_entity.dart';

/// Chat type enumeration
enum ChatType {
  oneToOne,
  group;

  String get value => name;

  static ChatType fromString(String value) {
    if (value == 'one-to-one') return ChatType.oneToOne;
    if (value == 'group') return ChatType.group;
    return ChatType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ChatType.oneToOne,
    );
  }

  /// Convert to Firestore value
  String toFirestoreValue() {
    switch (this) {
      case ChatType.oneToOne:
        return 'one-to-one';
      case ChatType.group:
        return 'group';
    }
  }
}

/// Last message metadata
class LastMessage extends Equatable {
  final String content;
  final String senderId;
  final String senderName;
  final DateTime timestamp;
  final String type; // text, image, video, etc.

  const LastMessage({
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    required this.type,
  });

  @override
  List<Object?> get props => [content, senderId, senderName, timestamp, type];

  /// Get display text for last message preview
  String get displayText {
    switch (type) {
      case 'image':
        return 'Photo';
      case 'video':
        return 'Video';
      case 'audio':
        return 'Audio';
      case 'file':
        return 'File';
      case 'location':
        return 'Location';
      default:
        return content;
    }
  }
}

/// Chat entity representing a chat conversation in the domain layer
class ChatEntity extends Equatable {
  final String id;
  final ChatType type;
  final String? name; // null for one-to-one, group name for groups
  final String? description;
  final String? photoUrl;
  final List<String> participantIds;
  final Map<String, ParticipantEntity> participantDetails;
  final String createdBy;
  final List<String> admins; // For group chats
  final LastMessage? lastMessage;
  final Map<String, int> unreadCount; // userId -> count
  final Map<String, bool> isArchived; // userId -> isArchived
  final Map<String, bool> isPinned; // userId -> isPinned
  final Map<String, bool> isMuted; // userId -> isMuted
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatEntity({
    required this.id,
    required this.type,
    this.name,
    this.description,
    this.photoUrl,
    required this.participantIds,
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

  /// Get unread count for specific user
  int getUnreadCount(String userId) => unreadCount[userId] ?? 0;

  /// Check if chat is archived for specific user
  bool isArchivedFor(String userId) => isArchived[userId] ?? false;

  /// Check if chat is pinned for specific user
  bool isPinnedFor(String userId) => isPinned[userId] ?? false;

  /// Check if chat is muted for specific user
  bool isMutedFor(String userId) => isMuted[userId] ?? false;

  /// Check if user is admin (for group chats)
  bool isUserAdmin(String userId) => admins.contains(userId);

  /// Get other participant in one-to-one chat
  ParticipantEntity? getOtherParticipant(String currentUserId) {
    if (type != ChatType.oneToOne) return null;
    final otherUserId = participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    return otherUserId.isNotEmpty ? participantDetails[otherUserId] : null;
  }

  /// Get chat display name for current user
  String getDisplayName(String currentUserId) {
    if (type == ChatType.group) {
      return name ?? 'Group Chat';
    }
    // For one-to-one, return other participant's name
    final otherParticipant = getOtherParticipant(currentUserId);
    return otherParticipant?.displayName ?? 'Unknown';
  }

  /// Get chat photo URL for current user
  String? getChatPhotoUrl(String currentUserId) {
    if (type == ChatType.group) {
      return photoUrl;
    }
    // For one-to-one, return other participant's photo
    final otherParticipant = getOtherParticipant(currentUserId);
    return otherParticipant?.photoUrl;
  }

  /// Check if chat has unread messages for user
  bool hasUnreadMessages(String userId) => getUnreadCount(userId) > 0;

  @override
  List<Object?> get props => [
        id,
        type,
        name,
        description,
        photoUrl,
        participantIds,
        participantDetails,
        createdBy,
        admins,
        lastMessage,
        unreadCount,
        isArchived,
        isPinned,
        isMuted,
        createdAt,
        updatedAt,
      ];

  ChatEntity copyWith({
    String? id,
    ChatType? type,
    String? name,
    String? description,
    String? photoUrl,
    List<String>? participantIds,
    Map<String, ParticipantEntity>? participantDetails,
    String? createdBy,
    List<String>? admins,
    LastMessage? lastMessage,
    Map<String, int>? unreadCount,
    Map<String, bool>? isArchived,
    Map<String, bool>? isPinned,
    Map<String, bool>? isMuted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      participantIds: participantIds ?? this.participantIds,
      participantDetails: participantDetails ?? this.participantDetails,
      createdBy: createdBy ?? this.createdBy,
      admins: admins ?? this.admins,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isArchived: isArchived ?? this.isArchived,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
