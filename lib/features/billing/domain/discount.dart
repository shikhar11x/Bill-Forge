import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/utils/money.dart';

enum DiscountType {
  amount,
  percent;

  static DiscountType fromName(String name) =>
      values.firstWhere((e) => e.name == name, orElse: () => amount);
}

class Discount {
  const Discount(this.type, this.value);
  const Discount.none() : type = DiscountType.amount, value = 0;

  final DiscountType type;

  /// Paise for [DiscountType.amount]; basis points (1% = 100) for percent.
  final int value;

  bool get isNone => value == 0;

  /// The discount in paise for [basePaise], never more than the base.
  int applyTo(int basePaise) {
    if (basePaise <= 0 || value <= 0) return 0;
    final raw = type == DiscountType.amount
        ? value
        : (basePaise * value + 5000) ~/ 10000;
    return raw > basePaise ? basePaise : raw;
  }

  @override
  bool operator ==(Object other) =>
      other is Discount && other.type == type && other.value == value;

  @override
  int get hashCode => Object.hash(type, value);
}

final _percentPattern = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$');

/// "10.5" -> 1050 basis points.
int? parseBasisPoints(String input) {
  final match = _percentPattern.firstMatch(input.trim());
  if (match == null) return null;
  return int.parse(match.group(1)!) * 100 +
      int.parse((match.group(2) ?? '').padRight(2, '0'));
}

/// Empty text means "no discount". Null when the text is not a valid number.
Discount? parseDiscount(DiscountType type, String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const Discount.none();
  final value = type == DiscountType.amount
      ? parsePaise(trimmed)
      : parseBasisPoints(trimmed);
  return value == null ? null : Discount(type, value);
}

/// For prefilling a text field.
String discountToInput(Discount d) {
  if (d.isNone) return '';
  if (d.type == DiscountType.amount) return paiseToInput(d.value);
  return '${d.value ~/ 100}.${(d.value % 100).toString().padLeft(2, '0')}';
}

/// "10%" or "₹50.00".
String describeDiscount(Discount d) {
  if (d.isNone) return '';
  if (d.type == DiscountType.amount) return formatPaise(d.value);
  final whole = d.value ~/ 100;
  final fraction = d.value % 100;
  if (fraction == 0) return '$whole%';
  final digits = fraction
      .toString()
      .padLeft(2, '0')
      .replaceFirst(RegExp(r'0$'), '');
  return '$whole.$digits%';
}
