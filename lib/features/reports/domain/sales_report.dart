import 'package:billforge/core/utils/date_format.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/features/reports/domain/profit.dart';
import 'package:billforge/features/reports/domain/report_data.dart';
import 'package:billforge/features/reports/domain/report_models.dart';
import 'package:billforge/features/reports/domain/report_range.dart';

class SalesSummary {
  const SalesSummary({
    required this.grossPaise,
    required this.returnsPaise,
    required this.taxPaise,
    required this.orders,
    required this.profit,
  });

  /// Invoice totals (GST included) dated in the period.
  final int grossPaise;

  /// Credit notes dated in the period.
  final int returnsPaise;

  /// GST on invoices minus GST on credit notes.
  final int taxPaise;

  /// Invoices that were not cancelled.
  final int orders;
  final ProfitEstimate profit;

  int get netPaise => grossPaise - returnsPaise;
  int get averageBillPaise => orders == 0 ? 0 : netPaise ~/ orders;
}

SalesSummary buildSalesSummary(ReportData d) => SalesSummary(
  grossPaise: sumBy(d.invoices, (i) => i.grandTotalPaise),
  returnsPaise: sumBy(d.creditNotes, (n) => n.totalPaise),
  taxPaise:
      sumBy(d.invoices, (i) => i.taxPaise) -
      sumBy(d.creditNotes, (n) => n.taxPaise),
  orders: d.invoices.where((i) => !i.isCancelled).length,
  profit: estimateProfit(
    items: d.invoiceItems,
    creditItems: d.creditNoteItems,
    costByProductId: d.costByProductId,
  ),
);

enum SalesGranularity { day, month }

class SalesBucket {
  const SalesBucket({
    required this.start,
    required this.grossPaise,
    required this.returnsPaise,
    required this.orders,
  });

  final DateTime start;
  final int grossPaise;
  final int returnsPaise;
  final int orders;

  int get netPaise => grossPaise - returnsPaise;
}

SalesGranularity defaultGranularity(ReportRange range) =>
    range.dayCount <= 62 ? SalesGranularity.day : SalesGranularity.month;

class _Acc {
  int gross = 0;
  int returns = 0;
  int orders = 0;
}

/// Sales per day (or per month for long periods). Every day or month in the
/// range appears, even with no sales, so charts have no gaps.
List<SalesBucket> buildSalesBuckets(
  ReportData d,
  ReportRange range, {
  SalesGranularity? granularity,
}) {
  final g = granularity ?? defaultGranularity(range);
  DateTime keyOf(DateTime t) => g == SalesGranularity.day
      ? DateTime(t.year, t.month, t.day)
      : DateTime(t.year, t.month);

  final accs = <DateTime, _Acc>{};
  _Acc acc(DateTime key) => accs.putIfAbsent(key, _Acc.new);

  var cursor = keyOf(range.from);
  while (!cursor.isAfter(range.to)) {
    acc(cursor);
    cursor = g == SalesGranularity.day
        ? DateTime(cursor.year, cursor.month, cursor.day + 1)
        : DateTime(cursor.year, cursor.month + 1);
  }

  for (final i in d.invoices) {
    final a = acc(keyOf(invoiceMoment(i)));
    a.gross += i.grandTotalPaise;
    if (!i.isCancelled) a.orders += 1;
  }
  for (final n in d.creditNotes) {
    acc(keyOf(n.issuedAt)).returns += n.totalPaise;
  }

  final keys = accs.keys.toList()..sort();
  return [
    for (final k in keys)
      SalesBucket(
        start: k,
        grossPaise: accs[k]!.gross,
        returnsPaise: accs[k]!.returns,
        orders: accs[k]!.orders,
      ),
  ];
}

/// "10 Jun" for days, "Jun 2026" for months.
String bucketLabel(SalesBucket bucket, SalesGranularity g) {
  final text = formatDate(bucket.start);
  return g == SalesGranularity.day ? text.substring(0, 6) : text.substring(3);
}

ReportDocument buildSalesDocument(ReportData data, ReportRange range) {
  final summary = buildSalesSummary(data);
  final g = defaultGranularity(range);
  final buckets = buildSalesBuckets(data, range, granularity: g);
  final profit = summary.profit;

  final notes = <String>[];
  if (profit.totalRevenuePaise > 0 && profit.coveragePercent < 100) {
    notes.add(
      'Estimated profit uses each product\'s current purchase price and '
      'covers ${profit.coveragePercent}% of sales. Add purchase prices in '
      'Products for a fuller picture.',
    );
  }

  return ReportDocument(
    title: 'Sales report',
    periodLabel: range.label,
    metrics: [
      ReportMetric('Gross sales', ReportCell.money(summary.grossPaise)),
      ReportMetric('Returns', ReportCell.money(summary.returnsPaise)),
      ReportMetric('Net sales', ReportCell.money(summary.netPaise)),
      ReportMetric('of which GST', ReportCell.money(summary.taxPaise)),
      ReportMetric('Orders', ReportCell.count(summary.orders)),
      ReportMetric('Average bill', ReportCell.money(summary.averageBillPaise)),
      ReportMetric(
        'Est. profit',
        profit.hasEstimate
            ? ReportCell.money(profit.profitPaise)
            : ReportCell.empty,
      ),
    ],
    chartTitle: g == SalesGranularity.day
        ? 'Net sales by day'
        : 'Net sales by month',
    chart: [
      for (final b in buckets)
        ChartPoint(
          label: bucketLabel(b, g),
          valuePaise: b.netPaise < 0 ? 0 : b.netPaise,
          tooltip: '${bucketLabel(b, g)}: ${formatPaise(b.netPaise)}',
        ),
    ],
    sections: [
      ReportSection(
        title: g == SalesGranularity.day ? 'Sales by day' : 'Sales by month',
        table: ReportTable(
          columns: [
            ReportColumn(g == SalesGranularity.day ? 'Date' : 'Month'),
            const ReportColumn('Orders', numeric: true),
            const ReportColumn('Sales', numeric: true),
            const ReportColumn('Returns', numeric: true),
            const ReportColumn('Net', numeric: true),
          ],
          rows: [
            for (final b in buckets)
              [
                ReportCell(
                  g == SalesGranularity.day
                      ? formatDate(b.start)
                      : bucketLabel(b, g),
                ),
                ReportCell.count(b.orders),
                ReportCell.money(b.grossPaise),
                ReportCell.money(b.returnsPaise),
                ReportCell.money(b.netPaise),
              ],
          ],
          footer: [
            const ReportCell('Total'),
            ReportCell.count(sumBy(buckets, (b) => b.orders)),
            ReportCell.money(sumBy(buckets, (b) => b.grossPaise)),
            ReportCell.money(sumBy(buckets, (b) => b.returnsPaise)),
            ReportCell.money(sumBy(buckets, (b) => b.netPaise)),
          ],
        ),
      ),
    ],
    notes: notes,
  );
}
