import 'package:flutter/material.dart';

/// Application color palette
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF00A884); // WhatsApp green
  static const Color primaryDark = Color(0xFF008069);
  static const Color primaryLight = Color(0xFF25D366);

  // Secondary Colors
  static const Color secondary = Color(0xFF34B7F1);
  static const Color secondaryDark = Color(0xFF0097E6);

  // Background Colors
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF0B141A);
  static const Color surfaceLight = Color(0xFFF7F8FA);
  static const Color surfaceDark = Color(0xFF1F2C34);

  // Chat Colors
  static const Color chatBackgroundLight = Color(0xFFECE5DD);
  static const Color chatBackgroundDark = Color(0xFF0B141A);
  static const Color senderBubbleLight = Color(0xFFDCF8C6);
  static const Color senderBubbleDark = Color(0xFF005C4B);
  static const Color receiverBubbleLight = Color(0xFFFFFFFF);
  static const Color receiverBubbleDark = Color(0xFF1F2C34);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textPrimaryDark = Color(0xFFE9EDEF);
  static const Color textSecondaryLight = Color(0xFF667781);
  static const Color textSecondaryDark = Color(0xFF8696A0);
  static const Color textTertiaryLight = Color(0xFFAAAAAA);
  static const Color textTertiaryDark = Color(0xFF667781);

  // Status Colors
  static const Color online = Color(0xFF00FF00);
  static const Color offline = Color(0xFF8696A0);
  static const Color typing = Color(0xFF00A884);

  // Message Status Colors
  static const Color messageSent = Color(0xFF8696A0);
  static const Color messageDelivered = Color(0xFF8696A0);
  static const Color messageRead = Color(0xFF53BDEB);

  // Call Colors
  static const Color voiceCall = Color(0xFF00A884);
  static const Color videoCall = Color(0xFF34B7F1);
  static const Color incomingCall = Color(0xFF00BF4D);
  static const Color outgoingCall = Color(0xFF00A884);
  static const Color missedCall = Color(0xFFFF3B30);

  // Payment Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Wallet Colors
  static const Color walletGreen = Color(0xFF00C853);
  static const Color walletRed = Color(0xFFD32F2F);
  static const Color walletYellow = Color(0xFFFFC107);

  // UI Element Colors
  static const Color dividerLight = Color(0xFFE4E7EB);
  static const Color dividerDark = Color(0xFF2A3942);
  static const Color iconLight = Color(0xFF54656F);
  static const Color iconDark = Color(0xFF8696A0);
  static const Color buttonLight = Color(0xFF00A884);
  static const Color buttonDark = Color(0xFF00A884);

  // Semantic Colors
  static const Color link = Color(0xFF039BE5);
  static const Color unread = Color(0xFF00A884);

  // Transparent & Overlay
  static const Color transparent = Colors.transparent;
  static const Color overlayLight = Color(0x33000000);
  static const Color overlayDark = Color(0x66000000);
  static const Color scrim = Color(0x99000000);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Status Colors for Stories
  static const Color statusSeen = Color(0xFF8696A0);
  static const Color statusUnseen = Color(0xFF00A884);

  // Group Colors (for group avatars with no image)
  static const List<Color> groupColors = [
    Color(0xFFE57373),
    Color(0xFFF06292),
    Color(0xFFBA68C8),
    Color(0xFF9575CD),
    Color(0xFF7986CB),
    Color(0xFF64B5F6),
    Color(0xFF4FC3F7),
    Color(0xFF4DD0E1),
    Color(0xFF4DB6AC),
    Color(0xFF81C784),
    Color(0xFFAED581),
    Color(0xFFFFD54F),
    Color(0xFFFFB74D),
    Color(0xFFFF8A65),
    Color(0xFFA1887F),
  ];
}
