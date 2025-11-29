import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatz/core/themes/app_colors.dart';
import 'package:chatz/core/themes/app_text_styles.dart';
import 'package:chatz/features/chat/domain/entities/chat_entity.dart';
import 'package:chatz/features/chat/presentation/providers/chat_providers.dart';
import 'package:chatz/features/chat/presentation/widgets/chat_list_tile.dart';
import 'package:chatz/features/chat/presentation/pages/chat_page.dart';

/// Chat list page displaying all user's chats
class ChatListPage extends ConsumerStatefulWidget {
  final String userId;

  const ChatListPage({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatsAsync = ref.watch(userChatsStreamProvider(widget.userId));

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Search bar
          if (_showSearch) _buildSearchBar(),

          // Chat list
          Expanded(
            child: chatsAsync.when(
              data: (chats) => _buildChatList(chats),
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
              error: (error, stack) => _buildErrorState(error),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewChat,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Chats'),
      actions: [
        IconButton(
          icon: Icon(_showSearch ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchController.clear();
                _searchQuery = '';
              }
            });
          },
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'new_group',
              child: Row(
                children: [
                  Icon(Icons.group_add),
                  SizedBox(width: 12),
                  Text('New Group'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'archived',
              child: Row(
                children: [
                  Icon(Icons.archive),
                  SizedBox(width: 12),
                  Text('Archived Chats'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 12),
                  Text('Settings'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search chats...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondaryLight,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.iconLight),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildChatList(List<ChatEntity> chats) {
    // Filter chats based on search query
    final filteredChats = _searchQuery.isEmpty
        ? chats
        : chats.where((chat) {
            final displayName = chat.getDisplayName(widget.userId).toLowerCase();
            final lastMessage = chat.lastMessage?.content.toLowerCase() ?? '';
            return displayName.contains(_searchQuery) ||
                   lastMessage.contains(_searchQuery);
          }).toList();

    // Separate archived and active chats
    final activeChats = filteredChats
        .where((chat) => !chat.isArchivedFor(widget.userId))
        .toList();

    // Sort: pinned first, then by last message time
    activeChats.sort((a, b) {
      final aPinned = a.isPinnedFor(widget.userId);
      final bPinned = b.isPinnedFor(widget.userId);

      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;

      final aTime = a.lastMessage?.timestamp ?? a.updatedAt;
      final bTime = b.lastMessage?.timestamp ?? b.updatedAt;
      return bTime.compareTo(aTime);
    });

    if (activeChats.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshChats,
      color: AppColors.primary,
      child: ListView.builder(
        itemCount: activeChats.length,
        itemBuilder: (context, index) {
          final chat = activeChats[index];
          return ChatListTile(
            chat: chat,
            currentUserId: widget.userId,
            onTap: () => _openChat(chat),
            onArchive: () => _archiveChat(chat),
            onDelete: () => _deleteChat(chat),
            onPin: () => _togglePin(chat),
            onMute: () => _toggleMute(chat),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _searchQuery.isEmpty ? Icons.chat_bubble_outline : Icons.search_off,
            size: 80,
            color: AppColors.textSecondaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No chats yet'
                : 'No chats found',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Start a conversation by tapping the + button'
                : 'Try searching for something else',
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
            'Failed to load chats',
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
              ref.invalidate(userChatsStreamProvider(widget.userId));
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

  void _openChat(ChatEntity chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          chatId: chat.id,
          currentUserId: widget.userId,
        ),
      ),
    );
  }

  Future<void> _refreshChats() async {
    ref.invalidate(userChatsStreamProvider(widget.userId));
    // Wait a bit for the new data to load
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _startNewChat() {
    // TODO: Navigate to contacts page or new chat page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('New chat feature coming soon'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _archiveChat(ChatEntity chat) {
    // TODO: Implement archive functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${chat.getDisplayName(widget.userId)} archived'),
        backgroundColor: AppColors.primary,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Undo archive
          },
        ),
      ),
    );
  }

  void _deleteChat(ChatEntity chat) {
    // TODO: Implement delete functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${chat.getDisplayName(widget.userId)} deleted'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _togglePin(ChatEntity chat) {
    // TODO: Implement pin/unpin functionality
    final isPinned = chat.isPinnedFor(widget.userId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPinned
              ? '${chat.getDisplayName(widget.userId)} unpinned'
              : '${chat.getDisplayName(widget.userId)} pinned',
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _toggleMute(ChatEntity chat) {
    // TODO: Implement mute/unmute functionality
    final isMuted = chat.isMutedFor(widget.userId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isMuted
              ? '${chat.getDisplayName(widget.userId)} unmuted'
              : '${chat.getDisplayName(widget.userId)} muted',
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'new_group':
        // TODO: Navigate to create group page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Create group feature coming soon'),
            backgroundColor: AppColors.primary,
          ),
        );
        break;
      case 'archived':
        // TODO: Navigate to archived chats page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Archived chats feature coming soon'),
            backgroundColor: AppColors.primary,
          ),
        );
        break;
      case 'settings':
        // TODO: Navigate to settings page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings feature coming soon'),
            backgroundColor: AppColors.primary,
          ),
        );
        break;
    }
  }
}
