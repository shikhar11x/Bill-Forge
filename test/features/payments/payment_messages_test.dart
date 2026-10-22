import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/payments/domain/payment_messages.dart';
import 'package:billforge/features/payments/domain/statement.dart';
import '../../support/fakes.dart';
import '../../support/payment_fakes.dart';
import 'statement_test.dart' as fixture;

void main() {
  final now = DateTime(2026, 6, 15, 10);
  final shop = sampleShop().copyWith(paymentInstructions: 'UPI: sharma@upi');

  final invoices = [
    sampleOpenInvoice(
      id: 'i1',
      number: 'INV-0001',
      total: 100000,
      issuedAt: DateTime(2026, 6, 1),
      dueDate: DateTime(2026, 6, 10),
    ),
    sampleOpenInvoice(
      id: 'i2',
      number: 'INV-0002',
      total: 50000,
      paid: 20000,
      issuedAt: DateTime(2026, 6, 5),
      dueDate: DateTime(2026, 6, 20),
    ),
    sampleOpenInvoice(
      id: 'i3',
      number: 'INV-0003',
      total: 20000,
      issuedAt: DateTime(2026, 6, 8),
    ),
  ];

  group('buildReminderMessage', () {
    test('lists what is pending, oldest first, with the total', () {
      final message = buildReminderMessage(
        shop: shop,
        customerName: 'Rahul Sharma',
        openInvoices: invoices.reversed.toList(),
        now: now,
      );

      expect(message, contains('*Sharma General Store*'));
      expect(message, contains('Payment reminder'));
      expect(message, contains('Hello Rahul Sharma,'));
      expect(message, contains('₹1,500.00 is pending'));
      expect(
        message,
        contains('• INV-0001 · 01 Jun 2026 · ₹1,000.00 (overdue by 5 days)'),
      );
      expect(
        message,
        contains('• INV-0002 · 05 Jun 2026 · ₹300.00 (due 20 Jun 2026)'),
      );
      expect(message, contains('• INV-0003 · 08 Jun 2026 · ₹200.00\n'));
      expect(message, contains('Total due: *₹1,500.00*'));
      expect(message.indexOf('INV-0001'), lessThan(message.indexOf('INV-0002')));
      expect(message.indexOf('INV-0002'), lessThan(message.indexOf('INV-0003')));
    });

    test('includes payment instructions only when the shop has them', () {
      final withPay = buildReminderMessage(
        shop: shop,
        customerName: 'Rahul',
        openInvoices: invoices,
        now: now,
      );
      expect(withPay, contains('Pay via:\nUPI: sharma@upi'));

      final without = buildReminderMessage(
        shop: sampleShop(),
        customerName: 'Rahul',
        openInvoices: invoices,
        now: now,
      );
      expect(without, isNot(contains('Pay via')));
      expect(without, contains('Phone: 9876543210'));
    });

    test('says "1 day" for a single day overdue', () {
      final message = buildReminderMessage(
        shop: shop,
        customerName: 'Rahul',
        openInvoices: [
          sampleOpenInvoice(
            total: 1000,
            issuedAt: DateTime(2026, 6, 1),
            dueDate: DateTime(2026, 6, 14),
          ),
        ],
        now: now,
      );
      expect(message, contains('(overdue by 1 day)'));
    });

    test('long lists show the first six and summarise the rest', () {
      final many = [
        for (var i = 1; i <= 8; i++)
          sampleOpenInvoice(
            id: 'x$i',
            number: 'INV-000$i',
            total: 1000,
            issuedAt: DateTime(2026, 6, i),
          ),
      ];
      final message = buildReminderMessage(
        shop: shop,
        customerName: 'Rahul',
        openInvoices: many,
        now: now,
      );
      expect(message, contains('INV-0006'));
      expect(message, isNot(contains('INV-0007')));
      expect(message, contains('(+2 more invoices)'));
      expect(message, contains('Total due: *₹80.00*'));
    });
  });

  group('buildStatementMessage', () {
    test('summarises opening, billed, received and balance due', () {
      final statement = buildStatement(ledger: fixture.makeLedger());
      final message = buildStatementMessage(
        shop: shop,
        customerName: 'Rahul Sharma',
        statement: statement,
      );

      expect(message, contains('Statement of account'));
      expect(message, contains('Hello Rahul Sharma,'));
      expect(message, contains('(All transactions)'));
      expect(message, contains('Opening balance: ₹0.00'));
      expect(message, contains('Billed: ₹1,500.00'));
      expect(message, contains('Received: ₹1,100.00'));
      expect(message, contains('Balance due: *₹400.00*'));
    });
  });
}