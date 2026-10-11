/// Normalises an Indian mobile number to its 10 digits:
/// "+91 98765-43210" -> "9876543210". Validate with `Validators.phone` first.
String normalizeIndianPhone(String input) {
  final cleaned = input.replaceAll(RegExp(r'[\s-]'), '');
  return cleaned.startsWith('+91') ? cleaned.substring(3) : cleaned;
}

final _indianMobile = RegExp(r'^[6-9]\d{9}$');

/// WhatsApp wants the country code plus the number, digits only:
/// "9876543210" -> "919876543210". Null when [phone] is not a valid Indian
/// mobile number.
String? whatsAppNumber(String? phone) {
  if (phone == null) return null;
  final digits = normalizeIndianPhone(phone);
  return _indianMobile.hasMatch(digits) ? '91$digits' : null;
}