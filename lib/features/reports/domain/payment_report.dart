import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/reports/domain/report_data.dart';
import 'package:billforge/features/reports/domain/report_models.dart';
import 'package:billforge/features/reports/domain/report_range.dart';

class MethodRow {
  const MethodRow({
    required this.method,
    required this.receivedPaise,
    required this.refundedPaise,
  });

  final PaymentMethod method;
  final int receivedPaise;
  final int refundedPaise;

  int get netPaise => receivedPaise - refundedPaise;
}

/// Money in and out per payment method. Methods with no activity are left out.
List<MethodRow> buildMethodRows(ReportData d) {
  final rows = <MethodRow>[];
  for (final m in PaymentMethod.values) {
    final received = sumBy(
      d.payments.where((p) => p.method == m),
      (p) => p.amountPaise,
    );
    final refunded = sumBy(
      d.creditNotes.where(
        (n) => n.refundPaise > 0 && (n.refundMethod ?? PaymentMethod.cash) == m,
      ),
      (n) => n.refundPaise,
    );
    if (received != 0 || refunded != 0) {
      rows.add(
        MethodRow(method: m, receivedPaise: received, refundedPaise: refunded),
      );
    }
  }
  return rows;
}

class AgingBucket {
  const AgingBucket({
    required this.label,
    required this.invoices,
    required this.duePaise,
  });

  final String label;
  final int invoices;
  final int duePaise;
}

/// Unpaid invoices grouped by how long ago they were issued.
List<AgingBucket> buildAging(List<Invoice> openInvoices, DateTime now) {
  const labels = [
    '0 to 30 days',
    '31 to 60 days',
    '61 to 90 days',
    'Over 90 days',
  ];
  final counts = List<int>.filled(4, 0);
  final dues = List<int>.filled(4, 0);
  final today = DateTime.utc(now.year, now.month, now.day);

  for (final i in openInvoices) {
    if (i.customerId == null || i.duePaise <= 0) continue;
    final m = invoiceMoment(i);
    final age = today.difference(DateTime.utc(m.year, m.month, m.day)).inDays;
    final index = age <= 30 ? 0 : (age <= 60 ? 1 : (age <= 90 ? 2 : 3));
    counts[index] += 1;
    dues[index] += i.duePaise;
  }

  return [
    for (var k = 0; k < 4; k++)
      AgingBucket(label: labels[k], invoices: counts[k], duePaise: dues[k]),
  ];
}

ReportDocument buildPaymentsDocument(
  ReportData data,
  ReportRange range,
  List<Invoice> openInvoices,
  DateTime now,
) {
  final methods = buildMethodRows(data);
  final received = sumBy(data.payments, (p) => p.amountPaise);
  final refunded = sumBy(data.creditNotes, (n) => n.refundPaise);
  final later = sumBy(
    data.payments.where((p) => p.receiptId != null),
    (p) => p.amountPaise,
  );
  final aging = buildAging(openInvoices, now);

  return ReportDocument(
    title: 'Payments and credit report',
    periodLabel: range.label,
    metrics: [
      ReportMetric('Money received', ReportCell.money(received)),
      ReportMetric('Refunded', ReportCell.money(refunded)),
      ReportMetric('Net collected', ReportCell.money(received - refunded)),
      ReportMetric('Taken at sale', ReportCell.money(received - later)),
      ReportMetric('Collected on credit bills', ReportCell.money(later)),
      ReportMetric(
        'Unpaid (all time)',
        ReportCell.money(sumBy(aging, (b) => b.duePaise)),
      ),
    ],
    sections: [
      ReportSection(
        title: 'By payment method',
        table: ReportTable(
          columns: const [
            ReportColumn('Method'),
            ReportColumn('Received', numeric: true),
            ReportColumn('Refunded', numeric: true),
            ReportColumn('Net', numeric: true),
          ],
          rows: [
            for (final r in methods)
              [
                ReportCell(r.method.label),
                ReportCell.money(r.receivedPaise),
                ReportCell.money(r.refundedPaise),
                ReportCell.money(r.netPaise),
              ],
          ],
          footer: [
            const ReportCell('Total'),
            ReportCell.money(received),
            ReportCell.money(refunded),
            ReportCell.money(received - refunded),
          ],
        ),
      ),
      ReportSection(
        title: 'Unpaid invoices by age (as of today)',
        table: ReportTable(
          columns: const [
            ReportColumn('Age'),
            ReportColumn('Invoices', numeric: true),
            ReportColumn('Amount due', numeric: true),
          ],
          rows: [
            for (final b in aging)
              [
                ReportCell(b.label),
                ReportCell.count(b.invoices),
                ReportCell.money(b.duePaise),
              ],
          ],
          footer: [
            const ReportCell('Total'),
            ReportCell.count(sumBy(aging, (b) => b.invoices)),
            ReportCell.money(sumBy(aging, (b) => b.duePaise)),
          ],
        ),
      ),
    ],
    notes: const [
      'Received and refunded amounts follow the date money changed hands. '
          'The age table ignores the period and shows today\'s unpaid credit.',
    ],
  );
}
