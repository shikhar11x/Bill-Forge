import 'package:billforge/core/utils/money.dart';

/// Validates a rupee amount typed into a text field (max 2 decimals).
String? Function(String?) amountValidator({
  required bool required,
  String label = 'Amount',
}) => (value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return required ? '$label is required' : null;
  return parsePaise(text) == null
      ? 'Enter a valid amount (up to 2 decimals)'
      : null;
};
