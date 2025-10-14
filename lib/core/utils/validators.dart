/// Validation utilities for form inputs
class Validators {
  Validators._();

  /// Validate phone number
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Phone number must start with + (country code)
    if (!value.startsWith('+')) {
      return 'Please enter a valid phone number';
    }

    // Remove + and check if rest are digits
    final numericValue = value.substring(1);
    if (!RegExp(r'^[0-9]+$').hasMatch(numericValue)) {
      return 'Please enter a valid phone number';
    }

    // Check length (minimum 10 digits after country code)
    if (numericValue.length < 10) {
      return 'Please enter a valid phone number';
    }

    if (numericValue.length > 15) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  /// Validate display name
  static String? validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Display name is required';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 2) {
      return 'Name must be at least 2 characters long';
    }

    if (trimmedValue.length > 50) {
      return 'Name is too long';
    }

    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    if (value.length > 50) {
      return 'Password is too long';
    }

    return null;
  }

  /// Validate message content
  static String? validateMessage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Message cannot be empty';
    }

    if (value.length > 4096) {
      return 'Message is too long';
    }

    return null;
  }

  /// Validate payment amount
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }

    final amount = double.tryParse(value);

    if (amount == null) {
      return 'Please enter a valid amount';
    }

    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }

    if (amount > 10000) {
      return 'Amount is too large';
    }

    return null;
  }

  /// Validate group name
  static String? validateGroupName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Group name is required';
    }

    if (value.length < 3) {
      return 'Group name must be at least 3 characters';
    }

    if (value.length > 50) {
      return 'Group name is too long';
    }

    return null;
  }

  /// Validate OTP
  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }

    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'OTP must contain only numbers';
    }

    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
