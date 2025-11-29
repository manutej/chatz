import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:chatz/core/themes/app_colors.dart';
import 'package:chatz/core/themes/app_text_styles.dart';
import 'package:chatz/features/chat/domain/entities/message_entity.dart';
import 'package:chatz/features/chat/presentation/widgets/media_viewer.dart';

/// Message bubble widget for displaying chat messages
class MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final String currentUserId;
  final VoidCallback? onReply;
  final Function(String emoji)? onReact;
  final VoidCallback? onDelete;
  final bool showSenderName; // For group chats

  const MessageBubble({
    super.key,
    required this.message,
    required this.currentUserId,
    this.onReply,
    this.onReact,
    this.onDelete,
    this.showSenderName = false,
  });

  bool get isSentByMe => message.senderId == currentUserId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Check if message is deleted for current user
    if (message.isDeletedFor(currentUserId)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment:
            isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSentByMe) _buildAvatar(),
          if (!isSentByMe) const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageActions(context),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: isSentByMe
                      ? (isDark
                          ? AppColors.senderBubbleDark
                          : AppColors.senderBubbleLight)
                      : (isDark
                          ? AppColors.receiverBubbleDark
                          : AppColors.receiverBubbleLight),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(isSentByMe ? 12 : 0),
                    bottomRight: Radius.circular(isSentByMe ? 0 : 12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sender name (for group chats)
                          if (showSenderName && !isSentByMe) ...[
                            Text(
                              message.senderName,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: _getSenderColor(),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],

                          // Reply preview
                          if (message.isReply) _buildReplyPreview(theme),

                          // Message content
                          if (message.isDeleted)
                            _buildDeletedMessage(theme)
                          else if (message.hasMedia)
                            _buildMediaMessage(context, theme)
                          else
                            _buildTextMessage(theme),

                          // Time and status row
                          const SizedBox(height: 4),
                          _buildTimeAndStatus(theme),
                        ],
                      ),
                    ),

                    // Reactions overlay
                    if (message.hasReactions) _buildReactions(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (message.senderPhotoUrl != null && message.senderPhotoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: CachedNetworkImageProvider(message.senderPhotoUrl!),
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: _getSenderColor(),
      child: Text(
        message.senderName[0].toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getSenderColor() {
    // Generate consistent color based on sender ID
    final colorIndex = message.senderId.hashCode % AppColors.groupColors.length;
    return AppColors.groupColors[colorIndex];
  }

  Widget _buildReplyPreview(ThemeData theme) {
    final replyMetadata = message.replyTo!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: _getSenderColor(),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyMetadata.senderName,
            style: AppTextStyles.labelSmall.copyWith(
              color: _getSenderColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            replyMetadata.content,
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDeletedMessage(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.block,
          size: 14,
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
        ),
        const SizedBox(width: 6),
        Text(
          'This message was deleted',
          style: AppTextStyles.chatMessage.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildTextMessage(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.content,
          style: AppTextStyles.chatMessage.copyWith(
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        if (message.isEdited) ...[
          const SizedBox(height: 2),
          Text(
            'edited',
            style: AppTextStyles.labelSmall.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMediaMessage(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _openMediaViewer(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildMediaContent(context),
          ),
        ),
        if (message.content.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            message.content,
            style: AppTextStyles.chatMessage.copyWith(
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMediaContent(BuildContext context) {
    switch (message.type) {
      case MessageType.image:
        return _buildImageContent();
      case MessageType.video:
        return _buildVideoContent();
      case MessageType.audio:
        return _buildAudioContent();
      case MessageType.file:
        return _buildFileContent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildImageContent() {
    return Stack(
      children: [
        CachedNetworkImage(
          imageUrl: message.mediaUrl!,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 200,
            height: 200,
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            width: 200,
            height: 200,
            color: Colors.grey[300],
            child: const Icon(Icons.error),
          ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image, size: 12, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Photo',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoContent() {
    return Stack(
      children: [
        CachedNetworkImage(
          imageUrl: message.mediaMetadata?.thumbnailUrl ?? '',
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 200,
            height: 200,
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            width: 200,
            height: 200,
            color: Colors.grey[300],
            child: const Icon(Icons.videocam, size: 48),
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black26,
            child: const Icon(
              Icons.play_circle_outline,
              size: 64,
              color: Colors.white,
            ),
          ),
        ),
        if (message.mediaMetadata?.duration != null)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatDuration(message.mediaMetadata!.duration!),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAudioContent() {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.play_arrow,
            color: AppColors.primary,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice message',
                  style: AppTextStyles.labelSmall,
                ),
                const SizedBox(height: 4),
                if (message.mediaMetadata?.duration != null)
                  Text(
                    _formatDuration(message.mediaMetadata!.duration!),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileContent() {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.insert_drive_file,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.mediaMetadata?.fileName ?? 'File',
                  style: AppTextStyles.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (message.readableFileSize != null)
                  Text(
                    message.readableFileSize!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.download,
            color: AppColors.primary,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeAndStatus(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeago.format(message.createdAt, locale: 'en_short'),
          style: AppTextStyles.chatTime.copyWith(
            fontSize: 10,
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
          ),
        ),
        if (isSentByMe) ...[
          const SizedBox(width: 4),
          _buildMessageStatus(),
        ],
      ],
    );
  }

  Widget _buildMessageStatus() {
    if (message.readBy.length > 1) {
      // Read by others (excluding sender)
      return const Icon(
        Icons.done_all,
        size: 14,
        color: AppColors.messageRead,
      );
    } else if (message.deliveredTo.isNotEmpty) {
      // Delivered
      return Icon(
        Icons.done_all,
        size: 14,
        color: AppColors.messageDelivered,
      );
    } else {
      // Sent
      return Icon(
        Icons.done,
        size: 14,
        color: AppColors.messageSent,
      );
    }
  }

  Widget _buildReactions() {
    return Positioned(
      bottom: -8,
      right: isSentByMe ? null : 8,
      left: isSentByMe ? 8 : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...message.reactions.values.take(3).map(
                  (emoji) => Text(emoji, style: const TextStyle(fontSize: 12)),
                ),
            if (message.reactions.length > 3)
              Text(
                ' +${message.reactions.length - 3}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _openMediaViewer(BuildContext context) {
    if (message.mediaUrl != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MediaViewer(
            mediaUrl: message.mediaUrl!,
            mediaType: message.type,
            heroTag: message.id,
          ),
        ),
      );
    }
  }

  void _showMessageActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reaction bar
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    '❤️',
                    '😂',
                    '😮',
                    '😢',
                    '🙏',
                    '👍'
                  ].map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onReact?.call(emoji);
                      },
                      child: Text(emoji, style: const TextStyle(fontSize: 32)),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),
              // Actions
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  onReply?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: message.content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message copied')),
                  );
                },
              ),
              if (isSentByMe || message.senderId == currentUserId)
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.error),
                  title: const Text('Delete', style: TextStyle(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete?.call();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
