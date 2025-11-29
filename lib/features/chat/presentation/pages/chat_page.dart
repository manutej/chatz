import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatz/core/themes/app_colors.dart';
import 'package:chatz/core/themes/app_text_styles.dart';
import 'package:chatz/features/chat/domain/entities/chat_entity.dart';
import 'package:chatz/features/chat/domain/entities/message_entity.dart';
import 'package:chatz/features/chat/domain/usecases/send_message.dart';
import 'package:chatz/features/chat/presentation/providers/chat_providers.dart';
import 'package:chatz/features/chat/presentation/widgets/message_bubble.dart';
import 'package:chatz/features/chat/presentation/widgets/message_input_widget.dart';
import 'package:chatz/features/chat/presentation/widgets/typing_indicator.dart';

/// Chat page displaying messages and input for a specific chat
class ChatPage extends ConsumerStatefulWidget {
  final String chatId;
  final String currentUserId;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.currentUserId,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  final List<String> _typingUsers = []; // TODO: Implement real-time typing status
  ReplyMetadata? _replyTo;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Mark messages as read when entering chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // TODO: Implement pagination - load more messages when scrolling to top
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      debugPrint('Reached top - load more messages');
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesStreamProvider(widget.chatId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: _buildAppBar(context),
      body: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.chatBackgroundDark
              : AppColors.chatBackgroundLight,
        ),
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: messagesAsync.when(
                data: (messages) => _buildMessagesList(messages),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
                error: (error, stack) => _buildErrorState(error),
              ),
            ),

            // Message input
            MessageInputWidget(
              onSendText: _sendTextMessage,
              onSendMedia: _sendMediaMessage,
              onSendVoice: _sendVoiceMessage,
              replyTo: _replyTo,
              onCancelReply: () {
                setState(() {
                  _replyTo = null;
                });
              },
              onTyping: _onTyping,
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    // Get chat details - in production, you'd have a separate provider for this
    // For now, we'll show placeholder data
    return AppBar(
      titleSpacing: 0,
      title: InkWell(
        onTap: _openChatInfo,
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.person, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),

            // Name and status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chat',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _typingUsers.isNotEmpty ? 'typing...' : 'online',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam),
          onPressed: _startVideoCall,
        ),
        IconButton(
          icon: const Icon(Icons.call),
          onPressed: _startVoiceCall,
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view_contact',
              child: Row(
                children: [
                  Icon(Icons.person),
                  SizedBox(width: 12),
                  Text('View Contact'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'media',
              child: Row(
                children: [
                  Icon(Icons.photo_library),
                  SizedBox(width: 12),
                  Text('Media, Links, Docs'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'search',
              child: Row(
                children: [
                  Icon(Icons.search),
                  SizedBox(width: 12),
                  Text('Search'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'mute',
              child: Row(
                children: [
                  Icon(Icons.volume_off),
                  SizedBox(width: 12),
                  Text('Mute Notifications'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'wallpaper',
              child: Row(
                children: [
                  Icon(Icons.wallpaper),
                  SizedBox(width: 12),
                  Text('Wallpaper'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessagesList(List<MessageEntity> messages) {
    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    // Filter out messages deleted for current user
    final visibleMessages = messages
        .where((m) => !m.isDeletedFor(widget.currentUserId))
        .toList();

    // Reverse for proper display (newest at bottom)
    final reversedMessages = visibleMessages.reversed.toList();

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: reversedMessages.length + (_typingUsers.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        // Show typing indicator at the bottom
        if (index == 0 && _typingUsers.isNotEmpty) {
          return TypingIndicator(
            userName: _typingUsers.first,
            showAvatar: true,
          );
        }

        // Adjust index if typing indicator is shown
        final messageIndex = _typingUsers.isNotEmpty ? index - 1 : index;
        final message = reversedMessages[messageIndex];

        // Determine if we should show sender name (for group chats)
        final showSenderName = _shouldShowSenderName(
          message,
          messageIndex > 0 ? reversedMessages[messageIndex - 1] : null,
        );

        return MessageBubble(
          message: message,
          currentUserId: widget.currentUserId,
          showSenderName: showSenderName,
          onReply: () => _setReplyTo(message),
          onReact: (emoji) => _reactToMessage(message, emoji),
          onDelete: () => _deleteMessage(message),
        );
      },
    );
  }

  bool _shouldShowSenderName(MessageEntity message, MessageEntity? previousMessage) {
    // TODO: Check if chat is a group chat
    // For now, always return false (one-to-one chats)
    return false;

    // In group chats, show sender name if:
    // 1. Message is from someone else
    // 2. Previous message is from a different sender or there's a time gap
    // if (message.senderId == widget.currentUserId) return false;
    // if (previousMessage == null) return true;
    // if (previousMessage.senderId != message.senderId) return true;
    // return false;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: AppColors.textSecondaryLight.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to start the conversation',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load messages',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(chatMessagesStreamProvider(widget.chatId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTextMessage(String text) async {
    final sendMessage = ref.read(sendMessageProvider);

    final params = SendMessageParams(
      chatId: widget.chatId,
      content: text,
      type: MessageType.text,
      replyTo: _replyTo,
    );

    final result = await sendMessage(params);

    result.fold(
      (failure) {
        _showErrorSnackBar('Failed to send message: ${failure.message}');
      },
      (message) {
        // Clear reply mode
        if (_replyTo != null) {
          setState(() {
            _replyTo = null;
          });
        }
        // Scroll to bottom
        _scrollToBottom();
      },
    );
  }

  Future<void> _sendMediaMessage(File file, MessageType type) async {
    // Show loading indicator
    _showLoadingSnackBar('Uploading ${type.name}...');

    final sendMessage = ref.read(sendMessageProvider);

    final params = SendMessageParams(
      chatId: widget.chatId,
      content: '', // Caption can be added later
      type: type,
      mediaFile: file,
      replyTo: _replyTo,
    );

    final result = await sendMessage(params);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    result.fold(
      (failure) {
        _showErrorSnackBar('Failed to send ${type.name}: ${failure.message}');
      },
      (message) {
        if (_replyTo != null) {
          setState(() {
            _replyTo = null;
          });
        }
        _scrollToBottom();
      },
    );
  }

  Future<void> _sendVoiceMessage(File audioFile, int duration) async {
    _showLoadingSnackBar('Sending voice message...');

    final sendMessage = ref.read(sendMessageProvider);

    final params = SendMessageParams(
      chatId: widget.chatId,
      content: '',
      type: MessageType.audio,
      mediaFile: audioFile,
      duration: duration,
      replyTo: _replyTo,
    );

    final result = await sendMessage(params);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    result.fold(
      (failure) {
        _showErrorSnackBar('Failed to send voice message: ${failure.message}');
      },
      (message) {
        if (_replyTo != null) {
          setState(() {
            _replyTo = null;
          });
        }
        _scrollToBottom();
      },
    );
  }

  void _setReplyTo(MessageEntity message) {
    setState(() {
      _replyTo = ReplyMetadata(
        messageId: message.id,
        content: message.content.isNotEmpty
            ? message.content
            : message.type.name.toUpperCase(),
        senderName: message.senderId == widget.currentUserId
            ? 'You'
            : message.senderName,
      );
    });
  }

  Future<void> _reactToMessage(MessageEntity message, String emoji) async {
    // TODO: Implement reaction functionality
    _showInfoSnackBar('Reaction feature coming soon');
  }

  Future<void> _deleteMessage(MessageEntity message) async {
    // TODO: Implement delete functionality
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Delete message for everyone or just for you?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'for_me'),
            child: const Text('Delete for Me'),
          ),
          if (message.senderId == widget.currentUserId)
            TextButton(
              onPressed: () => Navigator.pop(context, 'for_everyone'),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Delete for Everyone'),
            ),
        ],
      ),
    );

    if (result != null && result != 'cancel') {
      _showInfoSnackBar('Delete functionality coming soon');
    }
  }

  Future<void> _markMessagesAsRead() async {
    final markAsRead = ref.read(markMessagesAsReadProvider);
    // TODO: Get unread message IDs from the messages stream
    // For now, this is a placeholder
    await markAsRead(widget.chatId);
  }

  void _onTyping() {
    // TODO: Implement typing indicator broadcast
    debugPrint('User is typing');
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _openChatInfo() {
    // TODO: Navigate to chat info page
    _showInfoSnackBar('Chat info feature coming soon');
  }

  void _startVideoCall() {
    // TODO: Implement video call
    _showInfoSnackBar('Video call feature coming soon');
  }

  void _startVoiceCall() {
    // TODO: Implement voice call
    _showInfoSnackBar('Voice call feature coming soon');
  }

  void _handleMenuAction(String action) {
    // TODO: Implement menu actions
    _showInfoSnackBar('$action feature coming soon');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
        duration: const Duration(minutes: 5), // Long duration for upload
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
