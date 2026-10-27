import 'package:billforge/features/reports/domain/report_data.dart';
import 'package:billforge/features/reports/domain/report_models.dart';
import 'package:billforge/features/reports/domain/report_range.dart';

const _walkInKey = '__walk_in__';
const walkInLabel = 'Walk-in customers';

class CustomerSalesRow {
  const CustomerSalesRow({
    required this.key,
    required this.name,
    required this.orders,
    required this.grossPaise,
    required this.returnsPaise,
  });

  final String key;
  final String name;
  final int orders;
  final int grossPaise;
  final int returnsPaise;

  int get netPaise => grossPaise - returnsPaise;
  bool get isWalkIn => key == _walkInKey;
}

class _C {
  _C(this.name);

  final String name;
  int orders = 0;
  int gross = 0;
  int returns = 0;
}

/// Net sales per customer, biggest first. Bills without a customer are grouped
/// as walk-in customers.
List<CustomerSalesRow> buildCustomerRows(ReportData d) {
  final acc = <String, _C>{};
  _C entry(String? id, String? name) => acc.putIfAbsent(
    id ?? _walkInKey,
    () => _C(id == null ? walkInLabel : (name ?? 'Customer')),
  );

  for (final i in d.invoices) {
    final c = entry(i.customerId, i.customerName);
    c.gross += i.grandTotalPaise;
    if (!i.isCancelled) c.orders += 1;
  }
  for (final n in d.creditNotes) {
    entry(n.customerId, n.customerName).returns += n.totalPaise;
  }

  return [
    for (final e in acc.entries)
      CustomerSalesRow(
        key: e.key,
        name: e.value.name,
        orders: e.value.orders,
        grossPaise: e.value.gross,
        returnsPaise: e.value.returns,
      ),
  ]..sort((a, b) {
    final byNet = b.netPaise.compareTo(a.netPaise);
    return byNet != 0
        ? byNet
        : a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
}

ReportDocument buildCustomersDocument(ReportData data, ReportRange range) {
  final rows = buildCustomerRows(data);
  final named = rows.where((r) => !r.isWalkIn).length;

  return ReportDocument(
    title: 'Customer sales report',
    periodLabel: range.label,
    metrics: [
      ReportMetric('Customers billed', ReportCell.count(named)),
      ReportMetric('Orders', ReportCell.count(sumBy(rows, (r) => r.orders))),
      ReportMetric(
        'Net sales',
        ReportCell.money(sumBy(rows, (r) => r.netPaise)),
      ),
    ],
    sections: [
      ReportSection(
        title: 'Sales by customer',
        table: ReportTable(
          columns: const [
            ReportColumn('Customer'),
            ReportColumn('Orders', numeric: true),
            ReportColumn('Sales', numeric: true),
            ReportColumn('Returns', numeric: true),
            ReportColumn('Net sales', numeric: true),
          ],
          rows: [
            for (final r in rows)
              [
                ReportCell(r.name),
                ReportCell.count(r.orders),
                ReportCell.money(r.grossPaise),
                ReportCell.money(r.returnsPaise),
                ReportCell.money(r.netPaise),
              ],
          ],
          footer: [
            const ReportCell('Total'),
            ReportCell.count(sumBy(rows, (r) => r.orders)),
            ReportCell.money(sumBy(rows, (r) => r.grossPaise)),
            ReportCell.money(sumBy(rows, (r) => r.returnsPaise)),
            ReportCell.money(sumBy(rows, (r) => r.netPaise)),
          ],
        ),
      ),
    ],
  );
}
