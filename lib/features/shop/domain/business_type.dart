enum BusinessType {
  grocery('Grocery & kirana'),
  pharmacy('Pharmacy'),
  clothing('Clothing & apparel'),
  electronics('Electronics & mobiles'),
  restaurant('Restaurant & food'),
  hardware('Hardware & building'),
  stationery('Stationery & books'),
  wholesale('Wholesale & distribution'),
  services('Services'),
  other('Other');

  const BusinessType(this.label);

  final String label;

  static BusinessType fromName(String name) =>
      values.firstWhere((e) => e.name == name, orElse: () => other);
}
