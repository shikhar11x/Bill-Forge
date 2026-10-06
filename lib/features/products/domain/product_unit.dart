enum ProductUnit {
  piece('Piece', 'pcs'),
  kilogram('Kilogram', 'kg', fractional: true),
  gram('Gram', 'g', fractional: true),
  litre('Litre', 'L', fractional: true),
  millilitre('Millilitre', 'mL', fractional: true),
  metre('Metre', 'm', fractional: true),
  dozen('Dozen', 'doz'),
  pair('Pair', 'pair'),
  packet('Packet', 'pkt'),
  box('Box', 'box');

  const ProductUnit(this.label, this.symbol, {this.fractional = false});

  final String label;
  final String symbol;

  /// Whether quantities like 2.5 make sense for this unit.
  final bool fractional;

  static ProductUnit fromName(String name) =>
      values.firstWhere((u) => u.name == name, orElse: () => piece);
}
