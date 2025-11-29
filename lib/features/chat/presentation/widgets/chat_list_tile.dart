import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:chatz/core/themes/app_colors.dart';
import 'package:chatz/core/themes/app_text_styles.dart';
import 'package:chatz/features/chat/domain/entities/chat_entity.dart';

/// Chat list tile widget for displaying individual chats in the list
class ChatListTile extends StatelessWidget {
  final ChatEntity chat;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;
  final VoidCallback? onMute;

  const ChatListTile({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.onTap,
    this.onArchive,
    this.onDelete,
    this.onPin,
    this.onMute,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unreadCount = chat.getUnreadCount(currentUserId);
    final hasUnread = unreadCount > 0;
    final isPinned = chat.isPinnedFor(currentUserId);
    final isMuted = chat.isMutedFor(currentUserId);

    return Dismissible(
      key: ValueKey(chat.id),
      background: _buildSwipeBackground(
        alignment: Alignment.centerLeft,
        color: AppColors.primary,
        icon: Icons.archive,
        label: 'Archive',
      ),
      secondaryBackground: _buildSwipeBackground(
        alignment: Alignment.centerRight,
        color: AppColors.error,
        icon: Icons.delete,
        label: 'Delete',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onArchive?.call();
          return false;
        } else if (direction == DismissDirection.endToStart) {
          return await _confirmDelete(context);
        }
        return false;
      },
      child: Container(
        color: isPinned
            ? (isDark
                ? AppColors.surfaceDark.withOpacity(0.5)
                : AppColors.surfaceLight)
            : null,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Avatar
                _buildAvatar(context),
                const SizedBox(width: 12),

                // Chat info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Pin indicator
                          if (isPinned) ...[
                            Icon(
                              Icons.push_pin,
                              size: 14,
                              color: AppColors.textSecondaryLight,
                            ),
                            const SizedBox(width: 4),
                          ],

                          // Chat name
                          Expanded(
                            child: Text(
                              chat.getDisplayName(currentUserId),
                              style: AppTextStyles.chatName.copyWith(
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: hasUnread
                                    ? theme.textTheme.bodyLarge?.color
                                    : theme.textTheme.bodyMedium?.color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Timestamp
                          Text(
                            _formatTimestamp(chat.lastMessage?.timestamp),
                            style: AppTextStyles.chatTime.copyWith(
                              color: hasUnread
                                  ? AppColors.primary
                                  : AppColors.textSecondaryLight,
                              fontWeight:
                                  hasUnread ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Last message and badges
                      Row(
                        children: [
                          // Message status (for sent messages)
                          if (chat.lastMessage?.senderId == currentUserId) ...[
                            _buildMessageStatusIcon(),
                            const SizedBox(width: 4),
                          ],

                          // Last message preview
                          Expanded(
                            child: Text(
                              _getLastMessagePreview(),
                              style: AppTextStyles.chatLastMessage.copyWith(
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: hasUnread
                                    ? theme.textTheme.bodyMedium?.color
                                    : AppColors.textSecondaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Badges (mute, unread count)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Mute indicator
                              if (isMuted)
                                Icon(
                                  Icons.volume_off,
                                  size: 16,
                                  color: AppColors.textSecondaryLight,
                                ),

                              // Unread count badge
                              if (hasUnread) ...[
                                if (isMuted) const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMuted
                                        ? AppColors.textSecondaryLight
                                        : AppColors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    unreadCount > 99 ? '99+' : '$unreadCount',
                                    style: AppTextStyles.unreadCount.copyWith(
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final photoUrl = chat.getChatPhotoUrl(currentUserId);
    final displayName = chat.getDisplayName(currentUserId);

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: CachedNetworkImageProvider(photoUrl),
          ),
          if (chat.type == ChatType.oneToOne) _buildOnlineIndicator(),
        ],
      );
    }

    // Default avatar for chats without photos
    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: _getAvatarColor(displayName),
          child: Text(
            _getAvatarInitials(displayName),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (chat.type == ChatType.oneToOne) _buildOnlineIndicator(),
      ],
    );
  }

  Widget _buildOnlineIndicator() {
    // TODO: Implement online status check from presence system
    // For now, we'll show offline
    return Positioned(
      bottom: 0,
      right: 0,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: AppColors.offline,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colorIndex = name.hashCode % AppColors.groupColors.length;
    return AppColors.groupColors[colorIndex];
  }

  String _getAvatarInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  Widget _buildMessageStatusIcon() {
    final lastMessage = chat.lastMessage;
    if (lastMessage == null) return const SizedBox.shrink();

    // Check if message is read by others
    if (lastMessage.senderId == currentUserId) {
      // Simplified status - you may want to check actual read status
      return Icon(
        Icons.done_all,
        size: 16,
        color: AppColors.messageDelivered,
      );
    }

    return const SizedBox.shrink();
  }

  String _getLastMessagePreview() {
    final lastMessage = chat.lastMessage;
    if (lastMessage == null) {
      return 'No messages yet';
    }

    // Show sender name for group chats
    final prefix = chat.type == ChatType.group &&
                   lastMessage.senderId != currentUserId
        ? '${lastMessage.senderName}: '
        : lastMessage.senderId == currentUserId
            ? 'You: '
            : '';

    return '$prefix${lastMessage.displayText}';
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today - show time
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[timestamp.weekday - 1];
    } else {
      // Older - show date
      return '${timestamp.day}/${timestamp.month}/${timestamp.year.toString().substring(2)}';
    }
  }

  Widget _buildSwipeBackground({
    required AlignmentGeometry alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text(
          'Are you sure you want to delete this chat? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
