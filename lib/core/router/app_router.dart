import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart' as auth;
import '../../features/home/presentation/pages/home_page.dart';

/// Application routing configuration
class AppRouter {
  AppRouter._();

  /// Route names
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String verifyPhone = '/verify-phone';
  static const String register = '/register';
  static const String home = '/home';
  static const String chat = '/chat';
  static const String chatDetail = '/chat/:chatId';
  static const String call = '/call';
  static const String callDetail = '/call/:callId';
  static const String status = '/status';
  static const String statusDetail = '/status/:statusId';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String wallet = '/wallet';
  static const String recharge = '/wallet/recharge';
  static const String transactionHistory = '/wallet/transactions';
  static const String contacts = '/contacts';
  static const String newChat = '/new-chat';
  static const String newGroup = '/new-group';
  static const String groupInfo = '/group/:groupId/info';
  static const String userProfile = '/user/:userId';

  /// Router configuration
  static final GoRouter router = GoRouter(
    initialLocation: home, // Bypassing login to explore app structure
    debugLogDiagnostics: true,
    routes: [
      // Splash Screen
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),

      // Onboarding
      GoRoute(
        path: onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),

      // Authentication Routes
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const auth.LoginPage(),
      ),
      GoRoute(
        path: verifyPhone,
        name: 'verifyPhone',
        builder: (context, state) {
          final phoneNumber = state.extra as String?;
          return VerifyPhonePage(phoneNumber: phoneNumber);
        },
      ),
      GoRoute(
        path: register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),

      // Main App Routes
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomePage(),
        routes: [
          // Chat Routes
          GoRoute(
            path: 'chat/:chatId',
            name: 'chatDetail',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              return ChatDetailPage(chatId: chatId);
            },
          ),

          // New Chat
          GoRoute(
            path: 'new-chat',
            name: 'newChat',
            builder: (context, state) => const NewChatPage(),
          ),

          // New Group
          GoRoute(
            path: 'new-group',
            name: 'newGroup',
            builder: (context, state) => const NewGroupPage(),
          ),

          // Group Info
          GoRoute(
            path: 'group/:groupId/info',
            name: 'groupInfo',
            builder: (context, state) {
              final groupId = state.pathParameters['groupId']!;
              return GroupInfoPage(groupId: groupId);
            },
          ),

          // Call Detail
          GoRoute(
            path: 'call/:callId',
            name: 'callDetail',
            builder: (context, state) {
              final callId = state.pathParameters['callId']!;
              final isVideoCall = state.uri.queryParameters['video'] == 'true';
              return CallPage(callId: callId, isVideoCall: isVideoCall);
            },
          ),

          // Status Detail
          GoRoute(
            path: 'status/:statusId',
            name: 'statusDetail',
            builder: (context, state) {
              final statusId = state.pathParameters['statusId']!;
              return StatusDetailPage(statusId: statusId);
            },
          ),

          // User Profile
          GoRoute(
            path: 'user/:userId',
            name: 'userProfile',
            builder: (context, state) {
              final userId = state.pathParameters['userId']!;
              return UserProfilePage(userId: userId);
            },
          ),

          // Profile
          GoRoute(
            path: 'profile',
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),

          // Settings
          GoRoute(
            path: 'settings',
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),

          // Wallet Routes
          GoRoute(
            path: 'wallet',
            name: 'wallet',
            builder: (context, state) => const WalletPage(),
            routes: [
              GoRoute(
                path: 'recharge',
                name: 'recharge',
                builder: (context, state) => const RechargePage(),
              ),
              GoRoute(
                path: 'transactions',
                name: 'transactionHistory',
                builder: (context, state) => const TransactionHistoryPage(),
              ),
            ],
          ),

          // Contacts
          GoRoute(
            path: 'contacts',
            name: 'contacts',
            builder: (context, state) => const ContactsPage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => ErrorPage(error: state.error),
  );
}

// Placeholder pages (to be implemented)
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Onboarding')));
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Login')));
}

class VerifyPhonePage extends StatelessWidget {
  final String? phoneNumber;
  const VerifyPhonePage({super.key, this.phoneNumber});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Verify Phone')));
}

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Register')));
}

// HomePage moved to lib/features/home/presentation/pages/home_page.dart

class ChatDetailPage extends StatelessWidget {
  final String chatId;
  const ChatDetailPage({super.key, required this.chatId});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Chat: $chatId')));
}

class NewChatPage extends StatelessWidget {
  const NewChatPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('New Chat')));
}

class NewGroupPage extends StatelessWidget {
  const NewGroupPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('New Group')));
}

class GroupInfoPage extends StatelessWidget {
  final String groupId;
  const GroupInfoPage({super.key, required this.groupId});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Group Info: $groupId')));
}

class CallPage extends StatelessWidget {
  final String callId;
  final bool isVideoCall;
  const CallPage({super.key, required this.callId, required this.isVideoCall});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Call: $callId')));
}

class StatusDetailPage extends StatelessWidget {
  final String statusId;
  const StatusDetailPage({super.key, required this.statusId});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Status: $statusId')));
}

class UserProfilePage extends StatelessWidget {
  final String userId;
  const UserProfilePage({super.key, required this.userId});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('User: $userId')));
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Profile')));
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Settings')));
}

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Wallet')));
}

class RechargePage extends StatelessWidget {
  const RechargePage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Recharge')));
}

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Transaction History')));
}

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Contacts')));
}

class ErrorPage extends StatelessWidget {
  final Exception? error;
  const ErrorPage({super.key, this.error});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Error: ${error ?? "Unknown"}')));
}
