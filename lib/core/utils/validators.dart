abstract final class Validators {
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _phonePattern = RegExp(r'^(\+91)?[6-9]\d{9}$');
  static final _pincodePattern = RegExp(r'^[1-9]\d{5}$');
  static final _gstinPattern = RegExp(
    r'^\d{2}[A-Z]{5}\d{4}[A-Z][1-9A-Z]Z[0-9A-Z]$',
  );
  static final _prefixPattern = RegExp(r'^[A-Za-z0-9-]{1,8}$');

  static String? required(
    String? value, {
    String message = 'This field is required',
  }) => (value == null || value.trim().isEmpty) ? message : null;

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    return _emailPattern.hasMatch(value.trim())
        ? null
        : 'Enter a valid email address';
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return value.length >= 8 ? null : 'Use at least 8 characters';
  }

  static String? Function(String?) matches(
    String Function() other, {
    String message = 'Passwords do not match',
  }) =>
      (value) => value == other() ? null : message;

  /// Indian mobile number, optional +91, spaces/hyphens ignored.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '');
    return _phonePattern.hasMatch(cleaned)
        ? null
        : 'Enter a valid 10-digit mobile number';
  }

  static String? pincode(String? value) {
    if (value == null || value.trim().isEmpty) return 'PIN code is required';
    return _pincodePattern.hasMatch(value.trim())
        ? null
        : 'Enter a valid 6-digit PIN code';
  }

  /// Format check only (no checksum yet).
  static String? gstin(String? value) {
    if (value == null || value.trim().isEmpty) return 'GSTIN is required';
    return _gstinPattern.hasMatch(value.trim().toUpperCase())
        ? null
        : 'Enter a valid 15-character GSTIN';
  }

  /// GST invoice numbers are limited to 16 characters in total, so the prefix
  /// is capped at 8 (prefix + "-" + up to 7 digits).
  static String? invoicePrefix(String? value) {
    if (value == null || value.trim().isEmpty) return 'Prefix is required';
    return _prefixPattern.hasMatch(value.trim())
        ? null
        : 'Use 1-8 letters, numbers or hyphens';
  }

  static String? Function(String?) integerInRange(
    int min,
    int max, {
    String label = 'Value',
  }) => (value) {
    final n = int.tryParse(value?.trim() ?? '');
    if (n == null) return '$label must be a whole number';
    if (n < min || n > max) return '$label must be between $min and $max';
    return null;
  };

  static String? Function(String?) maxLength(int max) =>
      (value) => (value != null && value.trim().length > max)
      ? 'Keep this under $max characters'
      : null;

  /// Skips [validator] when the field is empty.
  static String? Function(String?) optional(
    String? Function(String?) validator,
  ) =>
      (value) =>
          (value == null || value.trim().isEmpty) ? null : validator(value);
}
