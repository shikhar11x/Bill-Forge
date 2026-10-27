import 'package:billforge/features/billing/domain/return_calculator.dart'
    show mulDivRound;
import 'package:billforge/features/reports/domain/report_data.dart';
import 'package:billforge/features/reports/domain/report_models.dart';
import 'package:billforge/features/reports/domain/report_range.dart';

class ProductSalesRow {
  const ProductSalesRow({
    required this.key,
    required this.name,
    required this.unitSymbol,
    required this.soldMilli,
    required this.returnedMilli,
    required this.revenuePaise,
    this.profitPaise,
  });

  final String key;
  final String name;
  final String unitSymbol;
  final int soldMilli;
  final int returnedMilli;

  /// Net taxable sales (GST excluded, returns taken off).
  final int revenuePaise;

  /// Null when the product has no purchase price.
  final int? profitPaise;

  int get netMilli => soldMilli - returnedMilli;
}

class _P {
  _P(this.productId, this.name, this.unit);

  final String? productId;
  final String name;
  final String unit;
  int sold = 0;
  int returned = 0;
  int revenue = 0;
}

/// Net sales per product, biggest first.
List<ProductSalesRow> buildProductRows(ReportData d) {
  final acc = <String, _P>{};
  String keyOf(String? id, String name) => id ?? 'name:$name';

  for (final i in d.invoiceItems) {
    final p = acc.putIfAbsent(
      keyOf(i.productId, i.name),
      () => _P(i.productId, i.name, i.unit.symbol),
    );
    p.sold += i.qtyMilli;
    p.revenue += i.taxablePaise;
  }
  for (final i in d.creditNoteItems) {
    final p = acc.putIfAbsent(
      keyOf(i.productId, i.name),
      () => _P(i.productId, i.name, i.unit.symbol),
    );
    p.returned += i.qtyMilli;
    p.revenue -= i.taxablePaise;
  }

  final rows =
      [
        for (final e in acc.entries)
          () {
            final p = e.value;
            final unitCost = p.productId == null
                ? null
                : d.costByProductId[p.productId];
            return ProductSalesRow(
              key: e.key,
              name: p.name,
              unitSymbol: p.unit,
              soldMilli: p.sold,
              returnedMilli: p.returned,
              revenuePaise: p.revenue,
              profitPaise: unitCost == null
                  ? null
                  : p.revenue -
                        (mulDivRound(p.sold, unitCost, 1000) -
                            mulDivRound(p.returned, unitCost, 1000)),
            );
          }(),
      ]..sort((a, b) {
        final byRevenue = b.revenuePaise.compareTo(a.revenuePaise);
        return byRevenue != 0
            ? byRevenue
            : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
  return rows;
}

ReportDocument buildProductsDocument(ReportData data, ReportRange range) {
  final rows = buildProductRows(data);
  final revenue = sumBy(rows, (r) => r.revenuePaise);
  final costed = rows.where((r) => r.profitPaise != null).toList();
  final profit = sumBy(costed, (r) => r.profitPaise!);

  return ReportDocument(
    title: 'Product sales report',
    periodLabel: range.label,
    metrics: [
      ReportMetric('Products sold', ReportCell.count(rows.length)),
      ReportMetric('Net sales (excl. GST)', ReportCell.money(revenue)),
      ReportMetric(
        'Est. profit',
        costed.isEmpty ? ReportCell.empty : ReportCell.money(profit),
      ),
    ],
    sections: [
      ReportSection(
        title: 'Sales by product',
        table: ReportTable(
          columns: const [
            ReportColumn('Product'),
            ReportColumn('Net quantity', numeric: true),
            ReportColumn('Net sales (excl. GST)', numeric: true),
            ReportColumn('Est. profit', numeric: true),
          ],
          rows: [
            for (final r in rows)
              [
                ReportCell(r.name),
                ReportCell.qty(r.netMilli, r.unitSymbol),
                ReportCell.money(r.revenuePaise),
                r.profitPaise == null
                    ? ReportCell.empty
                    : ReportCell.money(r.profitPaise!),
              ],
          ],
          footer: [
            const ReportCell('Total'),
            const ReportCell(''),
            ReportCell.money(revenue),
            costed.isEmpty ? ReportCell.empty : ReportCell.money(profit),
          ],
        ),
      ),
    ],
    notes: const [
      'Sales exclude GST and are net of returns. Profit is estimated from '
          'each product\'s current purchase price and is shown only for '
          'products that have one.',
    ],
  );
}
