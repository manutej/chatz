# Chatz Design System

This document defines the design system for Chatz based on the WhatsApp clone wireframes provided.

## Color Palette

### Primary Colors

```dart
class AppColors {
  // Primary teal (WhatsApp-inspired)
  static const Color primary = Color(0xFF075E54);
  static const Color primaryLight = Color(0xFF128C7E);
  static const Color primaryDark = Color(0xFF054740);

  // Accent colors
  static const Color accent = Color(0xFF25D366);
  static const Color accentLight = Color(0xFF34E77F);

  // Payment/Wallet colors
  static const Color walletGreen = Color(0xFF10B981);
  static const Color costOrange = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);

  // Background colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFECE5DD);

  // Message bubble colors
  static const Color sentMessage = Color(0xFFDCF8C6); // Light green
  static const Color receivedMessage = Color(0xFFFFFFFF);

  // Text colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status colors
  static const Color online = Color(0xFF10B981);
  static const Color offline = Color(0xFF9CA3AF);
  static const Color typing = Color(0xFF3B82F6);

  // Badge colors
  static const Color unreadBadge = Color(0xFF25D366);
  static const Color notificationBadge = Color(0xFFEF4444);
}
```

## Typography

```dart
class AppTextStyles {
  // Headers
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Body text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.3,
  );

  // Captions and labels
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  // Chat specific
  static const TextStyle chatName = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle chatPreview = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle chatTime = TextStyle(
    fontSize: 12,
    color: AppColors.textTertiary,
  );

  // Message bubbles
  static const TextStyle messageText = TextStyle(
    fontSize: 16,
    height: 1.4,
  );

  static const TextStyle messageTime = TextStyle(
    fontSize: 11,
    color: AppColors.textSecondary,
  );

  // Call screen
  static const TextStyle callName = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle callStatus = TextStyle(
    fontSize: 16,
    color: Color(0xFFD1D5DB),
  );

  static const TextStyle callDuration = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    fontFamily: 'monospace',
    color: Colors.white,
  );

  // Wallet/Payment
  static const TextStyle walletBalance = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle price = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );
}
```

## Component Specifications

### Chat List Item

```dart
class ChatListTile extends StatelessWidget {
  final Chat chat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Avatar - 48x48
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary,
            child: Text(
              chat.initials,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(chat.name, style: AppTextStyles.chatName),
                    Text(chat.time, style: AppTextStyles.chatTime),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  chat.lastMessage,
                  style: AppTextStyles.chatPreview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Unread badge
          if (chat.unreadCount > 0) ...[
            SizedBox(width: 8),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.unreadBadge,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${chat.unreadCount}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

### Message Bubble

```dart
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isSent;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isSent ? AppColors.sentMessage : AppColors.receivedMessage,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(message.content, style: AppTextStyles.messageText),
            SizedBox(height: 4),
            Text(message.time, style: AppTextStyles.messageTime),
          ],
        ),
      ),
    );
  }
}
```

### Call Cost Indicator

```dart
class CallCostIndicator extends StatelessWidget {
  final double costPerMinute;
  final Duration duration;
  final double totalCost;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDuration(duration),
            style: AppTextStyles.callDuration,
          ),
          SizedBox(height: 4),
          Text(
            '\$${totalCost.toStringAsFixed(2)} spent',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFD1D5DB),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}';
  }
}
```

### Wallet Balance Card

```dart
class WalletBalanceCard extends StatelessWidget {
  final double balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Balance',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: AppTextStyles.walletBalance,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Add Funds'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Auto-Reload'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

## Spacing System

```dart
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}
```

## Border Radius

```dart
class AppBorderRadius {
  static const double small = 4;
  static const double medium = 8;
  static const double large = 12;
  static const double xl = 16;
  static const double round = 100; // For circular elements
}
```

## Shadows

```dart
class AppShadows {
  static const BoxShadow small = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 4,
    offset: Offset(0, 1),
  );

  static const BoxShadow medium = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  static const BoxShadow large = BoxShadow(
    color: Color(0x26000000),
    blurRadius: 16,
    offset: Offset(0, 4),
  );
}
```

## Icons

Key icons used in the app (from lucide_icons or similar):

- **Phone** - Voice call
- **Video** - Video call
- **MessageCircle** - Chat/Messages
- **Wallet** - Wallet/Balance
- **DollarSign** - Payments/Cost
- **Settings** - Settings
- **Search** - Search
- **MoreVertical** - More options
- **Send** - Send message
- **Mic** - Voice message/Mute
- **Camera** - Camera/Video toggle
- **CheckCircle** - Success indicator

## Animations

```dart
class AppAnimations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
}
```

## Responsive Breakpoints

```dart
class AppBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}
```

## Usage Guidelines

1. **Consistency**: Always use defined colors, text styles, and spacing
2. **Accessibility**: Ensure text has sufficient contrast (WCAG AA standard)
3. **Touch Targets**: Minimum 48x48 dp for interactive elements
4. **Feedback**: Provide visual feedback for all interactions
5. **Loading States**: Show loading indicators for async operations
6. **Error States**: Clear error messages with recovery actions

## Resources

- Wireframes: `/Users/manu/Downloads/whatsapp-clone-wireframes.tsx`
- Figma designs: (To be added)
- Icon library: lucide_icons or similar
