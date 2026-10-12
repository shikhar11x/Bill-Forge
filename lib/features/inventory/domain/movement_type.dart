enum MovementType {
  opening('Opening balance'),
  sale('Sale'),
  purchase('Purchase'),
  adjustment('Adjustment'),
  supplierReturn('Returned to supplier');

  const MovementType(this.label);

  final String label;

  static MovementType fromName(String name) =>
      values.firstWhere((e) => e.name == name, orElse: () => adjustment);
}

enum AdjustmentReason {
  recount('Stock count / recount'),
  damaged('Damaged'),
  expired('Expired'),
  lost('Lost or stolen'),
  found('Found extra stock'),
  returnedToSupplier('Returned to supplier'),
  other('Other');

  const AdjustmentReason(this.label);

  final String label;

  MovementType get movementType => this == returnedToSupplier
      ? MovementType.supplierReturn
      : MovementType.adjustment;

  static AdjustmentReason fromName(String name) =>
      values.firstWhere((e) => e.name == name, orElse: () => other);
}

/// What a movement points back to (`refType` + `refId`).
abstract final class StockRef {
  static const invoice = 'invoice';
  static const purchase = 'purchase';
}
