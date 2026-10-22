import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/payments/domain/customer_ledger.dart';
import 'package:billforge/features/payments/domain/statement.dart';

import '../../support/payment_fakes.dart';

/// Invoice A: ₹1,000 on 1 Jun, ₹400 paid at the counter.
/// Invoice B: ₹500 on 10 Jun.
/// Receipt R1: ₹700 on 12 Jun, allocated A ₹600 and B ₹100.
/// Left owing: B ₹400.
CustomerLedger makeLedger() {
  final invoiceA = sampleOpenInvoice(
    id: 'A',
    number: 'INV-0001',
    total: 100000,
    paid: 100000,
    issuedAt: DateTime(2026, 6, 1, 10),
  );
  final invoiceB = sampleOpenInvoice(
    id: 'B',
    number: 'INV-0002',
    total: 50000,
    paid: 10000,
    issuedAt: DateTime(2026, 6, 10, 11),
  );
  return CustomerLedger(
    invoices: [invoiceB, invoiceA], // order must not matter
    payments: [
      InvoicePayment(
        id: 'p1',
        invoiceId: 'A',
        method: PaymentMethod.cash,
        amountPaise: 40000,
        paidAt: DateTime(2026, 6, 1, 10), // same instant as the invoice
      ),
      InvoicePayment(
        id: 'p2',
        invoiceId: 'A',
        method: PaymentMethod.upi,
        amountPaise: 60000,
        paidAt: DateTime(2026, 6, 12, 9),
        receiptId: 'R1',
      ),
      InvoicePayment(
        id: 'p3',
        invoiceId: 'B',
        method: PaymentMethod.upi,
        amountPaise: 10000,
        paidAt: DateTime(2026, 6, 12, 9),
        receiptId: 'R1',
      ),
    ],
    receipts: [
      sampleReceipt(
        id: 'R1',
        amountPaise: 70000,
        receivedAt: DateTime(2026, 6, 12, 9),
      ),
    ],
  );
}

void main() {
  test('lists invoices, sale payments and receipts with a running balance', () {
    final statement = buildStatement(ledger: makeLedger());

    expect(statement.entries, hasLength(4)); // allocation rows are not listed
    expect(statement.entries.map((e) => e.balancePaise), [
      100000,
      60000,
      110000,
      40000,
    ]);
    expect(statement.entries[0].particulars, 'Invoice INV-0001');
    expect(statement.entries[1].particulars, contains('Paid at sale'));
    expect(statement.entries[3].particulars, contains('Payment received'));
    expect(statement.openingPaise, 0);
    expect(statement.billedPaise, 150000);
    expect(statement.receivedPaise, 110000);
    expect(statement.closingPaise, 40000);
  });

  test('on the same instant the invoice comes before its payment', () {
    final statement = buildStatement(ledger: makeLedger());
    expect(statement.entries[0].debitPaise, 100000);
    expect(statement.entries[1].creditPaise, 40000);
  });

  test('the closing balance equals what the open invoices still owe', () {
    final ledger = makeLedger();
    final owed = ledger.invoices.fold<int>(0, (s, i) => s + i.duePaise);
    expect(buildStatement(ledger: ledger).closingPaise, owed);
  });

  test('a period carries earlier activity into the opening balance', () {
    final statement = buildStatement(
      ledger: makeLedger(),
      from: DateTime(2026, 6, 5),
      to: DateTime(2026, 6, 30),
    );
    expect(statement.openingPaise, 60000);
    expect(statement.entries.map((e) => e.balancePaise), [110000, 40000]);
    expect(statement.closingPaise, 40000);
  });

  test('the end date is inclusive and later entries are left out', () {
    final statement = buildStatement(
      ledger: makeLedger(),
      from: DateTime(2026, 6, 1),
      to: DateTime(2026, 6, 10),
    );
    expect(statement.entries, hasLength(3));
    expect(statement.closingPaise, 110000);
  });

  test('an empty period shows just the opening balance', () {
    final statement = buildStatement(
      ledger: makeLedger(),
      from: DateTime(2026, 7, 1),
      to: DateTime(2026, 7, 31),
    );
    expect(statement.entries, isEmpty);
    expect(statement.openingPaise, 40000);
    expect(statement.closingPaise, 40000);
  });

  test('an empty ledger gives an empty statement', () {
    final statement = buildStatement(
      ledger: const CustomerLedger(invoices: [], payments: [], receipts: []),
    );
    expect(statement.entries, isEmpty);
    expect(statement.closingPaise, 0);
  });

  test('period presets and labels', () {
    final now = DateTime(2026, 6, 15, 10);
    expect(StatementPeriod.all.range(now), (null, null));
    expect(StatementPeriod.thisMonth.range(now), (
      DateTime(2026, 6, 1),
      DateTime(2026, 6, 15),
    ));
    expect(StatementPeriod.last30Days.range(now), (
      DateTime(2026, 5, 17),
      DateTime(2026, 6, 15),
    ));
    expect(
      statementPeriodLabel(buildStatement(ledger: makeLedger())),
      'All transactions',
    );
    expect(
      statementPeriodLabel(
        buildStatement(
          ledger: makeLedger(),
          from: DateTime(2026, 6, 1),
          to: DateTime(2026, 6, 15),
        ),
      ),
      '01 Jun 2026 to 15 Jun 2026',
    );
  });
}
