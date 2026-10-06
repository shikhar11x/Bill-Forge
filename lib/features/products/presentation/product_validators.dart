import 'package:billforge/core/utils/money.dart';
import 'package:billforge/core/utils/quantity.dart';

abstract final class ProductValidators {
  static String? Function(String?) amount({
    required bool required,
    String label = 'Amount',
  }) => (value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return required ? '$label is required' : null;
    return parsePaise(text) == null
        ? 'Enter a valid amount (up to 2 decimals)'
        : null;
  };

  static String? Function(String?) quantity({
    required bool Function() fractional,
    String label = 'Quantity',
  }) => (value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label is required';
    final milli = parseMilli(text);
    if (milli == null) return 'Enter a valid number (up to 3 decimals)';
    if (!fractional() && milli % 1000 != 0) {
      return 'This unit cannot have decimals';
    }
    return null;
  };

  /// Optional. HSN codes are 4, 6 or 8 digits; SAC codes are 6 digits.
  static String? hsn(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return RegExp(r'^(\d{4}|\d{6}|\d{8})$').hasMatch(text)
        ? null
        : 'HSN/SAC must be 4, 6 or 8 digits';
  }
}
