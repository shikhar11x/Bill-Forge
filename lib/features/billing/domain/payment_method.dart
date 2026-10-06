enum PaymentMethod {
  cash('Cash'),
  upi('UPI'),
  card('Card'),
  other('Other');

  const PaymentMethod(this.label);

  final String label;

  static PaymentMethod fromName(String name) =>
      values.firstWhere((e) => e.name == name, orElse: () => other);
}

class PaymentEntry {
  const PaymentEntry({required this.method, required this.amountPaise});

  final PaymentMethod method;
  final int amountPaise;
}

/// Returns a user-facing problem with [entries], or null when they are valid.
/// Any shortfall is a credit sale, which needs a customer to owe it.
String? validatePayments({
  required int totalPaise,
  required List<PaymentEntry> entries,
  required bool hasCustomer,
}) {
  if (entries.any((e) => e.amountPaise <= 0)) {
    return 'Enter an amount for every payment.';
  }
  final paid = entries.fold<int>(0, (sum, e) => sum + e.amountPaise);
  if (paid > totalPaise) return 'Payments cannot exceed the bill total.';
  if (paid < totalPaise && !hasCustomer) {
    return 'Select a customer to put the remaining amount on credit.';
  }
  return null;
}
