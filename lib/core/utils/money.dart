final _amountPattern = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$');

/// "12.5" -> 1250 paise. Null when the text is not a valid non-negative
/// amount with at most two decimals. Commas are ignored.
int? parsePaise(String input) {
  final match = _amountPattern.firstMatch(input.trim().replaceAll(',', ''));
  if (match == null) return null;
  final rupees = int.parse(match.group(1)!);
  final paise = int.parse((match.group(2) ?? '').padRight(2, '0'));
  return rupees * 100 + paise;
}

/// 1250 -> "12.50" (for prefilling text fields).
String paiseToInput(int paise) =>
    '${paise ~/ 100}.${(paise % 100).toString().padLeft(2, '0')}';
