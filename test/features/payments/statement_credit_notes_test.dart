import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/payments/domain/customer_ledger.dart';
import 'package:billforge/features/payments/domain/statement.dart';

import '../../support/credit_note_fakes.dart';
import '../../support/payment_fakes.dart';

void main() {
  test('a paid sale that is returned and refunded nets to zero', () {
    // ₹1,000.00 invoice, paid at the counter, ₹400.00 returned and refunded.
    final invoice = sampleOpenInvoice(
      id: 'A',
      number: 'INV-0001',
      total: 100000,
      paid: 60000, // 100000 paid minus the 40000 refund
      issuedAt: DateTime(2026, 6, 1, 10),
    ).copyWith(creditedPaise: 40000);

    final statement = buildStatement(
      ledger: CustomerLedger(
        invoices: [invoice],
        payments: [
          InvoicePayment(
            id: 'p1',
            invoiceId: 'A',
            method: PaymentMethod.cash,
            amountPaise: 100000,
            paidAt: DateTime(2026, 6, 1, 10),
          ),
        ],
        receipts: const [],
        creditNotes: [sampleCreditNote(total: 40000, refund: 40000)],
      ),
    );

    expect(statement.entries.map((e) => e.balancePaise), [
      100000, // invoice
      0, // paid at sale
      -40000, // credit note
      0, // refund
    ]);
    expect(statement.entries[2].particulars, contains('Credit note CN-0001'));
    expect(statement.entries[3].particulars, contains('Refund'));
    expect(statement.closingPaise, 0);
    expect(statement.closingPaise, invoice.duePaise);
  });

  test('a credit sale that is partly returned shows the reduced balance', () {
    final invoice = sampleOpenInvoice(
      id: 'A',
      number: 'INV-0001',
      total: 100000,
      issuedAt: DateTime(2026, 6, 1, 10),
    ).copyWith(creditedPaise: 40000);

    final statement = buildStatement(
      ledger: CustomerLedger(
        invoices: [invoice],
        payments: const [],
        receipts: const [],
        creditNotes: [
          sampleCreditNote(total: 40000, applied: 40000, refund: 0),
        ],
      ),
    );

    expect(statement.entries, hasLength(2)); // no refund line
    expect(statement.closingPaise, 60000);
    expect(statement.closingPaise, invoice.duePaise);
  });

  test('a cancelled invoice still balances in the statement', () {
    final invoice = sampleOpenInvoice(
      id: 'A',
      total: 100000,
      paid: 0,
      issuedAt: DateTime(2026, 6, 1, 10),
    ).copyWith(creditedPaise: 100000, status: InvoiceStatus.cancelled);

    final statement = buildStatement(
      ledger: CustomerLedger(
        invoices: [invoice],
        payments: [
          InvoicePayment(
            id: 'p1',
            invoiceId: 'A',
            method: PaymentMethod.cash,
            amountPaise: 100000,
            paidAt: DateTime(2026, 6, 1, 10),
          ),
        ],
        receipts: const [],
        creditNotes: [sampleCreditNote(total: 100000, refund: 100000)],
      ),
    );

    expect(statement.closingPaise, 0);
    expect(invoice.duePaise, 0);
  });
}
