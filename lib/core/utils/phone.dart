/// Normalises an Indian mobile number to its 10 digits:
/// "+91 98765-43210" -> "9876543210". Validate with `Validators.phone` first.
String normalizeIndianPhone(String input) {
  final cleaned = input.replaceAll(RegExp(r'[\s-]'), '');
  return cleaned.startsWith('+91') ? cleaned.substring(3) : cleaned;
}
