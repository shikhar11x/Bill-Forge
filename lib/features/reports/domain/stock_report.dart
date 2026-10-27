import 'package:billforge/features/billing/domain/return_calculator.dart'
    show mulDivRound;
import 'package:billforge/features/products/domain/product.dart';
import 'package:billforge/features/reports/domain/report_data.dart';
import 'package:billforge/features/reports/domain/report_models.dart';
import 'package:billforge/features/reports/domain/report_range.dart';

class StockValuation {
  const StockValuation({
    required this.trackedProducts,
    required this.untrackedProducts,
    required this.costValuePaise,
    required this.retailValuePaise,
    required this.retailOfCostedPaise,
    required this.lowStock,
    required this.outOfStock,
    required this.missingCost,
  });

  final int trackedProducts;
  final int untrackedProducts;

  /// Stock x purchase price, for products that have a purchase price.
  final int costValuePaise;

  /// Stock x selling price, for every tracked product.
  final int retailValuePaise;

  /// Selling-price value of just the products counted in [costValuePaise].
  final int retailOfCostedPaise;
  final int lowStock;
  final int outOfStock;

  /// Tracked products in stock with no purchase price.
  final int missingCost;

  int get potentialMarginPaise => retailOfCostedPaise - costValuePaise;
}

/// Value of the stock on hand. Negative stock counts as zero.
StockValuation buildValuation(List<Product> products) {
  var tracked = 0;
  var untracked = 0;
  var cost = 0;
  var retail = 0;
  var retailCosted = 0;
  var low = 0;
  var out = 0;
  var missing = 0;

  for (final p in products) {
    if (!p.trackStock) {
      untracked++;
      continue;
    }
    tracked++;
    if (p.isOutOfStock) out++;
    if (p.isLowStock) low++;

    final stock = p.stockMilli < 0 ? 0 : p.stockMilli;
    final retailValue = mulDivRound(stock, p.sellingPricePaise, 1000);
    retail += retailValue;

    final purchase = p.purchasePricePaise;
    if (purchase != null) {
      cost += mulDivRound(stock, purchase, 1000);
      retailCosted += retailValue;
    } else if (stock > 0) {
      missing++;
    }
  }

  return StockValuation(
    trackedProducts: tracked,
    untrackedProducts: untracked,
    costValuePaise: cost,
    retailValuePaise: retail,
    retailOfCostedPaise: retailCosted,
    lowStock: low,
    outOfStock: out,
    missingCost: missing,
  );
}

ReportDocument buildStockDocument({
  required List<Product> products,
  required ReportData data,
  required ReportRange range,
}) {
  final v = buildValuation(products);

  final held =
      [
        for (final p in products)
          if (p.trackStock && p.stockMilli > 0 && p.purchasePricePaise != null)
            p,
      ]..sort(
        (a, b) => mulDivRound(
          b.stockMilli,
          b.purchasePricePaise!,
          1000,
        ).compareTo(mulDivRound(a.stockMilli, a.purchasePricePaise!, 1000)),
      );

  final bySupplier = <String, ({int bills, int total})>{};
  for (final p in data.purchases) {
    final key = p.supplierName ?? 'No supplier';
    final old = bySupplier[key] ?? (bills: 0, total: 0);
    bySupplier[key] = (bills: old.bills + 1, total: old.total + p.totalPaise);
  }
  final suppliers = bySupplier.entries.toList()
    ..sort((a, b) => b.value.total.compareTo(a.value.total));
  final purchased = sumBy(data.purchases, (p) => p.totalPaise);

  return ReportDocument(
    title: 'Stock and purchases report',
    periodLabel: range.label,
    metrics: [
      ReportMetric('Stock value (at cost)', ReportCell.money(v.costValuePaise)),
      ReportMetric(
        'Stock value (at selling price)',
        ReportCell.money(v.retailValuePaise),
      ),
      ReportMetric(
        'Potential margin',
        ReportCell.money(v.potentialMarginPaise),
      ),
      ReportMetric('Low-stock items', ReportCell.count(v.lowStock)),
      ReportMetric('Out of stock', ReportCell.count(v.outOfStock)),
      ReportMetric('Purchases in period', ReportCell.money(purchased)),
    ],
    sections: [
      ReportSection(
        title: 'Highest stock value (top 15)',
        table: ReportTable(
          columns: const [
            ReportColumn('Product'),
            ReportColumn('In stock', numeric: true),
            ReportColumn('Value at cost', numeric: true),
            ReportColumn('Value at selling price', numeric: true),
          ],
          rows: [
            for (final p in held.take(15))
              [
                ReportCell(p.name),
                ReportCell.qty(p.stockMilli, p.unit.symbol),
                ReportCell.money(
                  mulDivRound(p.stockMilli, p.purchasePricePaise!, 1000),
                ),
                ReportCell.money(
                  mulDivRound(p.stockMilli, p.sellingPricePaise, 1000),
                ),
              ],
          ],
        ),
      ),
      ReportSection(
        title: 'Purchases by supplier',
        table: ReportTable(
          columns: const [
            ReportColumn('Supplier'),
            ReportColumn('Bills', numeric: true),
            ReportColumn('Total', numeric: true),
          ],
          rows: [
            for (final e in suppliers)
              [
                ReportCell(e.key),
                ReportCell.count(e.value.bills),
                ReportCell.money(e.value.total),
              ],
          ],
          footer: [
            const ReportCell('Total'),
            ReportCell.count(sumBy(suppliers, (e) => e.value.bills)),
            ReportCell.money(purchased),
          ],
        ),
      ),
    ],
    notes: [
      if (v.missingCost > 0)
        '${v.missingCost} product${v.missingCost == 1 ? '' : 's'} in stock '
            '${v.missingCost == 1 ? 'has' : 'have'} no purchase price and '
            '${v.missingCost == 1 ? 'is' : 'are'} left out of the cost value.',
      'Stock figures are as of now. Only the purchases table follows the '
          'selected period.',
    ],
  );
}
