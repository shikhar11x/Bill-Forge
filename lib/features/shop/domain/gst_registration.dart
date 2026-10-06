enum GstRegistration {
  unregistered('Not registered for GST'),
  regular('Regular taxpayer'),
  composition('Composition scheme');

  const GstRegistration(this.label);

  final String label;

  /// Registered businesses have a GSTIN.
  bool get hasGstin => this != unregistered;

  /// Only regular taxpayers charge GST on their invoices.
  bool get chargesTax => this == regular;

  static GstRegistration fromName(String name) =>
      values.firstWhere((e) => e.name == name, orElse: () => unregistered);
}
