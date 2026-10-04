/// Formats [amount] in Indian grouping (12,34,567.50) with the ₹ symbol.
///
/// Display-only. Money in the billing engine (Phase 5) will be stored as
/// integer paise to avoid floating-point errors.
String formatInr(num amount, {int decimals = 2}) {
  final negative = amount < 0;
  final fixed = amount.abs().toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final fraction = decimals > 0 ? '.${parts[1]}' : '';
  return '${negative ? '-' : ''}₹${_groupIndian(parts[0])}$fraction';
}

String _groupIndian(String digits) {
  if (digits.length <= 3) return digits;
  final lastThree = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  return '${groups.join(',')},$lastThree';
}