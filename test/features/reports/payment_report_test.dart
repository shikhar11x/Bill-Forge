import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/reports/domain/payment_report.dart';
import 'package:billforge/features/reports/domain/report_data.dart';
import 'package:billforge/features/reports/domain/report_range.dart';

import '../../support/credit_note_fakes.dart';
import '../../support/payment_fakes.dart';
import '../../support/report_fakes.dart';

void main() {
  final now = DateTime(2026, 6, 15, 10);
  final range = ReportRange.between(
    DateTime(2026, 6, 1),
    DateTime(2026, 6, 30),
  );

  final data = ReportData(
    payments: [
      rPayment(id: 'p1', method: PaymentMethod.cash, amount: 100000),
      rPayment(id: 'p2', method: PaymentMethod.upi, amount: 50000),
      rPayment(
        id: 'p3',
        method: PaymentMethod.cash,
        amount: 30000,
        receiptId: 'r1',
      ),
    ],
    creditNotes: [
      sampleCreditNote(id: 'a', total: 20000, refund: 20000),
      sampleCreditNote(
        id: 'b',
        number: 'CN-0002',
        total: 10000,
        refund: 10000,
      ).copyWith(refundMethod: PaymentMethod.upi),
      // Applied to a balance: no money left the till.
      sampleCreditNote(
        id: 'c',
        number: 'CN-0003',
        total: 5000,
        applied: 5000,
        refund: 0,
      ),
    ],
  );

  test('money in and out per method, idle methods left out', () {
    final rows = buildMethodRows(data);
    expect(rows.map((r) => r.method), [PaymentMethod.cash, PaymentMethod.upi]);

    final cash = rows.first;
    expect(cash.receivedPaise, 130000);
    expect(cash.refundedPaise, 20000);
    expect(cash.netPaise, 110000);

    final upi = rows.last;
    expect(upi.receivedPaise, 50000);
    expect(upi.refundedPaise, 10000);
  });

  group('buildAging', () {
    final open = [
      sampleOpenInvoice(
        id: 'i1',
        total: 100000,
        issuedAt: DateTime(2026, 6, 1),
      ),
      sampleOpenInvoice(
        id: 'i2',
        total: 30000,
        issuedAt: DateTime(2026, 4, 20),
      ),
      sampleOpenInvoice(id: 'i3', total: 20000, issuedAt: DateTime(2026, 3, 1)),
      sampleOpenInvoice(
        id: 'i4',
        total: 1000,
        paid: 1000,
        issuedAt: DateTime(2026, 6, 1),
      ),
      sampleOpenInvoice(
        id: 'i5',
        total: 9000,
        issuedAt: DateTime(2026, 6, 1),
      ).copyWith(customerId: null),
    ];

    test('groups unpaid invoices by age', () {
      final buckets = buildAging(open, now);
      expect(buckets.map((b) => b.label), [
        '0 to 30 days',
        '31 to 60 days',
        '61 to 90 days',
        'Over 90 days',
      ]);
      expect(buckets.map((b) => b.duePaise), [100000, 30000, 0, 20000]);
      expect(buckets.map((b) => b.invoices), [1, 1, 0, 1]);
    });

    test('the edges fall in the lower bucket', () {
      DateTime issuedDaysAgo(int days) =>
          DateTime(now.year, now.month, now.day - days);
      final buckets = buildAging([
        sampleOpenInvoice(id: 'a', total: 100, issuedAt: issuedDaysAgo(30)),
        sampleOpenInvoice(id: 'b', total: 100, issuedAt: issuedDaysAgo(31)),
        sampleOpenInvoice(id: 'c', total: 100, issuedAt: issuedDaysAgo(60)),
        sampleOpenInvoice(id: 'd', total: 100, issuedAt: issuedDaysAgo(61)),
        sampleOpenInvoice(id: 'e', total: 100, issuedAt: issuedDaysAgo(90)),
        sampleOpenInvoice(id: 'f', total: 100, issuedAt: issuedDaysAgo(91)),
      ], now);
      expect(buckets.map((b) => b.invoices), [1, 2, 2, 1]);
    });
  });

  group('buildPaymentsDocument', () {
    final doc = buildPaymentsDocument(data, range, [
      sampleOpenInvoice(total: 60000, issuedAt: DateTime(2026, 6, 1)),
    ], now);

    String metric(String label) =>
        doc.metrics.firstWhere((m) => m.label == label).value.text;

    test('summary', () {
      expect(metric('Money received'), '₹1,800.00');
      expect(metric('Refunded'), '₹300.00');
      expect(metric('Net collected'), '₹1,500.00');
      expect(metric('Taken at sale'), '₹1,500.00');
      expect(metric('Collected on credit bills'), '₹300.00');
      expect(metric('Unpaid (all time)'), '₹600.00');
    });

    test('tables and totals', () {
      final methods = doc.sections[0].table;
      expect(methods.rows, hasLength(2));
      expect(methods.footer!.map((c) => c.text), [
        'Total',
        '₹1,800.00',
        '₹300.00',
        '₹1,500.00',
      ]);
      expect(doc.sections[1].table.footer!.last.text, '₹600.00');
    });
  });
}
