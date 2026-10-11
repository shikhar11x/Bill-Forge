import 'package:billforge/features/billing/domain/invoice.dart';

/// One line of the HSN/rate-wise tax summary printed on GST invoices.
class TaxSummaryRow {
  const TaxSummaryRow({
    required this.hsnCode,
    required this.ratePercent,
    required this.taxablePaise,
    required this.cgstPaise,
    required this.sgstPaise,
    required this.igstPaise,
  });

  /// Empty when the products have no HSN/SAC code.
  final String hsnCode;
  final int ratePercent;
  final int taxablePaise;
  final int cgstPaise;
  final int sgstPaise;
  final int igstPaise;

  int get taxPaise => cgstPaise + sgstPaise + igstPaise;
}

/// Groups items by HSN/SAC code and GST rate. The grouped taxable values add
/// up to the invoice's taxable value.
List<TaxSummaryRow> buildTaxSummary(List<InvoiceItem> items) {
  final groups = <String, List<InvoiceItem>>{};
  for (final item in items) {
    final key = '${item.hsnCode ?? ''}|${item.gstRatePercent}';
    groups.putIfAbsent(key, () => []).add(item);
  }

  int sum(List<InvoiceItem> list, int Function(InvoiceItem i) pick) =>
      list.fold<int>(0, (total, i) => total + pick(i));

  final rows =
      [
        for (final group in groups.values)
          TaxSummaryRow(
            hsnCode: group.first.hsnCode ?? '',
            ratePercent: group.first.gstRatePercent,
            taxablePaise: sum(group, (i) => i.taxablePaise),
            cgstPaise: sum(group, (i) => i.cgstPaise),
            sgstPaise: sum(group, (i) => i.sgstPaise),
            igstPaise: sum(group, (i) => i.igstPaise),
          ),
      ]..sort((a, b) {
        final byHsn = a.hsnCode.compareTo(b.hsnCode);
        return byHsn != 0 ? byHsn : a.ratePercent.compareTo(b.ratePercent);
      });
  return rows;
}
