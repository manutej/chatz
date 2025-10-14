import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Extension methods for DateTime
extension DateTimeExtension on DateTime {
  /// Format date and time for chat list
  String toChatListFormat() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(year, month, day);

    if (dateToCheck == today) {
      return DateFormat('HH:mm').format(this);
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else if (now.difference(this).inDays < 7) {
      return DateFormat('EEEE').format(this);
    } else if (year == now.year) {
      return DateFormat('MMM dd').format(this);
    } else {
      return DateFormat('MMM dd, yyyy').format(this);
    }
  }

  /// Format date and time for messages
  String toMessageFormat() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(year, month, day);

    if (dateToCheck == today) {
      return 'Today at ${DateFormat('HH:mm').format(this)}';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday at ${DateFormat('HH:mm').format(this)}';
    } else {
      return DateFormat('MMM dd, yyyy at HH:mm').format(this);
    }
  }

  /// Format time only
  String toTimeFormat() {
    return DateFormat('HH:mm').format(this);
  }

  /// Format date only
  String toDateFormat() {
    return DateFormat('MMM dd, yyyy').format(this);
  }

  /// Format relative time (e.g., "2 hours ago")
  String toRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(this);
    }
  }

  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }
}

/// Extension methods for String
extension StringExtension on String {
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Get initials from name
  String get initials {
    final words = trim().split(' ');
    if (words.isEmpty) return '';
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  /// Check if string is a valid phone number
  bool get isValidPhone {
    final numericValue = replaceAll(RegExp(r'[^0-9]'), '');
    return numericValue.length >= 10 && numericValue.length <= 15;
  }

  /// Check if string is a valid email
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Format phone number
  String get formatPhone {
    final numericValue = replaceAll(RegExp(r'[^0-9]'), '');
    if (numericValue.length == 10) {
      return '(${numericValue.substring(0, 3)}) ${numericValue.substring(3, 6)}-${numericValue.substring(6)}';
    }
    return this;
  }
}

/// Extension methods for Duration
extension DurationExtension on Duration {
  /// Format duration to "MM:SS" format
  String toMinutesSeconds() {
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Format duration to "HH:MM:SS" format
  String toHoursMinutesSeconds() {
    final hours = inHours.toString().padLeft(2, '0');
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Format duration in a human-readable way
  String toReadableFormat() {
    if (inHours > 0) {
      return '${inHours}h ${inMinutes.remainder(60)}m';
    } else if (inMinutes > 0) {
      return '${inMinutes}m ${inSeconds.remainder(60)}s';
    } else {
      return '${inSeconds}s';
    }
  }
}

/// Extension methods for BuildContext
extension BuildContextExtension on BuildContext {
  /// Get screen size
  Size get screenSize => MediaQuery.of(this).size;

  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Check if device is in portrait mode
  bool get isPortrait =>
      MediaQuery.of(this).orientation == Orientation.portrait;

  /// Check if device is in landscape mode
  bool get isLandscape =>
      MediaQuery.of(this).orientation == Orientation.landscape;

  /// Get theme
  ThemeData get theme => Theme.of(this);

  /// Get text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Show snackbar
  void showSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  /// Show error snackbar
  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show success snackbar
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Hide keyboard
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }
}

/// Extension methods for double (for currency formatting)
extension DoubleExtension on double {
  /// Format as currency
  String toCurrency({String symbol = '\$'}) {
    return '$symbol${toStringAsFixed(2)}';
  }

  /// Format with commas
  String toFormattedString() {
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(this);
  }
}

/// Extension methods for int (for file size formatting)
extension IntExtension on int {
  /// Format bytes to human-readable format
  String toFileSize() {
    if (this < 1024) {
      return '$this B';
    } else if (this < 1024 * 1024) {
      return '${(this / 1024).toStringAsFixed(1)} KB';
    } else if (this < 1024 * 1024 * 1024) {
      return '${(this / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
