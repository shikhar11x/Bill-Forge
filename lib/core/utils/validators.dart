abstract final class Validators {
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? required(String? value, {String message = 'This field is required'}) =>
      (value == null || value.trim().isEmpty) ? message : null;

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
}