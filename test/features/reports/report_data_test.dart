import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/reports/domain/report_data.dart';
import 'package:billforge/features/reports/domain/report_range.dart';

import '../../support/credit_note_fakes.dart';
import '../../support/payment_fakes.dart';
import '../../support/report_fakes.dart';

void main() {
  final data = ReportData(
    invoices: [
      sampleOpenInvoice(id: 'a', issuedAt: DateTime(2026, 6, 5, 10)),
      sampleOpenInvoice(id: 'b', issuedAt: DateTime(2026, 6, 10, 23, 30)),
      sampleOpenInvoice(id: 'c', issuedAt: DateTime(2026, 6, 20, 9)),
    ],
    invoiceItems: [
      rItem(id: 'ia', invoiceId: 'a'),
      rItem(id: 'ib', invoiceId: 'b'),
      rItem(id: 'ic', invoiceId: 'c'),
    ],
    creditNotes: [
      sampleCreditNote(id: 'n1', issuedAt: DateTime(2026, 6, 10, 9)),
      sampleCreditNote(id: 'n2', issuedAt: DateTime(2026, 6, 25, 9)),
    ],
    creditNoteItems: [
      rCnItem(id: 'x1', creditNoteId: 'n1'),
      rCnItem(id: 'x2', creditNoteId: 'n2'),
    ],
    payments: [
      rPayment(id: 'p1', paidAt: DateTime(2026, 6, 6)),
      rPayment(id: 'p2', paidAt: DateTime(2026, 7, 1)),
    ],
    purchases: [
      rPurchase(id: 'u1', at: DateTime(2026, 6, 10)),
      rPurchase(id: 'u2', at: DateTime(2026, 6, 11)),
    ],
    costByProductId: const {'p1': 5000},
  );

  test('slice keeps only what falls inside the range', () {
    final part = data.slice(
      ReportRange.between(DateTime(2026, 6, 1), DateTime(2026, 6, 10)),
    );

    expect(part.invoices.map((i) => i.id), ['a', 'b']);
    expect(part.invoiceItems.map((i) => i.id), ['ia', 'ib']);
    expect(part.creditNotes.map((n) => n.id), ['n1']);
    expect(part.creditNoteItems.map((i) => i.id), ['x1']);
    expect(part.payments.map((p) => p.id), ['p1']);
    expect(part.purchases.map((p) => p.id), ['u1']);
    expect(part.costByProductId, {'p1': 5000});
  });

  test('a one-day range includes the whole day', () {
    final part = data.slice(
      ReportRange.between(DateTime(2026, 6, 10), DateTime(2026, 6, 10)),
    );
    expect(part.invoices.map((i) => i.id), ['b']);
  });

  test('slicing an empty range gives nothing', () {
    final part = data.slice(
      ReportRange.between(DateTime(2025, 1, 1), DateTime(2025, 1, 31)),
    );
    expect(part.invoices, isEmpty);
    expect(part.invoiceItems, isEmpty);
    expect(part.creditNotes, isEmpty);
  });
}
