import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';

/// Main home page with bottom navigation
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const ChatsTabView(),
    const StatusTabView(),
    const CallsTabView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  // TODO: Navigate to profile
                  break;
                case 'wallet':
                  // TODO: Navigate to wallet
                  break;
                case 'settings':
                  // TODO: Navigate to settings
                  break;
                case 'logout':
                  // TODO: Implement logout
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Text('Profile'),
              ),
              const PopupMenuItem(
                value: 'wallet',
                child: Text('Wallet'),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Text('Settings'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.circle_outlined),
            label: 'Status',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.call),
            label: 'Calls',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                // TODO: Navigate to new chat
              },
              child: const Icon(Icons.chat_bubble),
            )
          : null,
    );
  }
}

/// Chats tab view
class ChatsTabView extends StatelessWidget {
  const ChatsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement actual chat list from Firestore
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Text('U${index + 1}'),
          ),
          title: Text('User ${index + 1}'),
          subtitle: Text('Last message preview...'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '12:30 PM',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
              ),
              const SizedBox(height: 4),
              if (index.isEven)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          onTap: () {
            // TODO: Navigate to chat detail
          },
        );
      },
    );
  }
}

/// Status tab view
class StatusTabView extends StatelessWidget {
  const StatusTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // My Status
        ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          title: const Text('My Status'),
          subtitle: const Text('Tap to add status update'),
          onTap: () {
            // TODO: Add status
          },
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Recent updates',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
        ),
        // Status list
        ...List.generate(
          5,
          (index) => ListTile(
            leading: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text('U${index + 1}'),
              ),
            ),
            title: Text('User ${index + 1}'),
            subtitle: Text('${index + 1} hours ago'),
            onTap: () {
              // TODO: View status
            },
          ),
        ),
      ],
    );
  }
}

/// Calls tab view
class CallsTabView extends StatelessWidget {
  const CallsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        final isVideoCall = index.isEven;
        final isIncoming = index % 3 == 0;
        final isMissed = index % 4 == 0;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Text('U${index + 1}'),
          ),
          title: Text('User ${index + 1}'),
          subtitle: Row(
            children: [
              Icon(
                isIncoming ? Icons.call_received : Icons.call_made,
                size: 16,
                color: isMissed ? AppColors.error : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 4),
              Text(
                'Yesterday, 12:30 PM',
                style: TextStyle(
                  color: isMissed ? AppColors.error : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(
              isVideoCall ? Icons.videocam : Icons.call,
              color: AppColors.primary,
            ),
            onPressed: () {
              // TODO: Initiate call (check wallet balance first)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Starting ${isVideoCall ? "video" : "voice"} call...',
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
