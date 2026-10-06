final _quantityPattern = RegExp(r'^(\d+)(?:\.(\d{1,3}))?$');

/// Quantities are stored as integer thousandths ("milli-units") so that
/// 2.5 kg is exactly 2500 and sums never drift.
int? parseMilli(String input) {
  final match = _quantityPattern.firstMatch(input.trim());
  if (match == null) return null;
  final whole = int.parse(match.group(1)!);
  final fraction = int.parse((match.group(2) ?? '').padRight(3, '0'));
  return whole * 1000 + fraction;
}

/// 2500 -> "2.5", 3000 -> "3", 1 -> "0.001".
String formatMilli(int milli) {
  final negative = milli < 0;
  final abs = milli.abs();
  final whole = abs ~/ 1000;
  final fraction = (abs % 1000)
      .toString()
      .padLeft(3, '0')
      .replaceFirst(RegExp(r'0+$'), '');
  final sign = negative ? '-' : '';
  return fraction.isEmpty ? '$sign$whole' : '$sign$whole.$fraction';
}
