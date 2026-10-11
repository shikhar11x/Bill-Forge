class TotalsRow {
  const TotalsRow(this.label, this.paise);

  final String label;
  final int paise;
}

/// Only rows that carry information are returned: no zero discount, no tax
/// lines for tax-free bills, no zero round-off.
List<TotalsRow> buildTotalsRows({
  required int discountPaise,
  required int taxablePaise,
  required int cgstPaise,
  required int sgstPaise,
  required int igstPaise,
  required int roundOffPaise,
}) {
  return [
    if (discountPaise > 0) TotalsRow('Discount', -discountPaise),
    if (cgstPaise + sgstPaise + igstPaise > 0) ...[
      TotalsRow('Taxable value', taxablePaise),
      if (igstPaise > 0)
        TotalsRow('IGST', igstPaise)
      else ...[
        TotalsRow('CGST', cgstPaise),
        TotalsRow('SGST', sgstPaise),
      ],
    ],
    if (roundOffPaise != 0) TotalsRow('Round off', roundOffPaise),
  ];
}
