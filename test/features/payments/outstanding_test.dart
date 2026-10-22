import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/payments/domain/outstanding.dart';

import '../../support/payment_fakes.dart';

void main() {
  final now = DateTime(2026, 6, 15, 10);

  group('overdue', () {
    test('a past due date with a balance is overdue', () {
      final invoice = sampleOpenInvoice(dueDate: DateTime(2026, 6, 10));
      expect(isOverdue(invoice, now), isTrue);
      expect(daysOverdue(invoice, now), 5);
    });

    test('due today is not overdue yet', () {
      final invoice = sampleOpenInvoice(dueDate: DateTime(2026, 6, 15));
      expect(isOverdue(invoice, now), isFalse);
      expect(daysOverdue(invoice, now), 0);
    });

    test('due tomorrow is not overdue', () {
      expect(
        isOverdue(sampleOpenInvoice(dueDate: DateTime(2026, 6, 16)), now),
        isFalse,
      );
    });

    test('no due date is never overdue', () {
      expect(isOverdue(sampleOpenInvoice(), now), isFalse);
    });

    test('a fully paid invoice is never overdue', () {
      final invoice = sampleOpenInvoice(
        total: 1000,
        paid: 1000,
        dueDate: DateTime(2026, 6, 1),
      );
      expect(isOverdue(invoice, now), isFalse);
    });
  });

  group('buildOutstandingReport', () {
    final report = buildOutstandingReport([
      sampleOpenInvoice(
        id: 'i1',
        number: 'INV-0001',
        customerName: 'Rahul S',
        total: 100000,
        issuedAt: DateTime(2026, 5, 1),
        dueDate: DateTime(2026, 6, 10), // overdue
      ),
      sampleOpenInvoice(
        id: 'i2',
        number: 'INV-0002',
        customerName: 'Rahul Sharma', // newer snapshot wins
        customerPhone: '9876543210',
        total: 50000,
        paid: 20000, // due 30000
        issuedAt: DateTime(2026, 6, 1),
        dueDate: DateTime(2026, 6, 15), // due today, not overdue
      ),
      sampleOpenInvoice(
        id: 'i3',
        number: 'INV-0003',
        customerId: 'c2',
        customerName: 'Amit Verma',
        total: 20000,
        issuedAt: DateTime(2026, 6, 5),
      ),
    ], now: now);

    test('groups by customer, largest balance first', () {
      expect(report.entries.map((e) => e.customerId), ['c1', 'c2']);
      expect(report.entries.first.outstandingPaise, 130000);
      expect(report.entries.first.openInvoices, 2);
      expect(report.entries.last.outstandingPaise, 20000);
    });

    test('totals and overdue add up', () {
      expect(report.totalPaise, 150000);
      expect(report.overduePaise, 100000);
      expect(report.entries.first.overduePaise, 100000);
      expect(report.entries.last.overduePaise, 0);
    });

    test('name and phone come from the newest invoice', () {
      expect(report.entries.first.customerName, 'Rahul Sharma');
      expect(report.entries.first.customerPhone, '9876543210');
    });

    test('tracks the oldest unpaid date', () {
      expect(report.entries.first.oldestIssuedAt, DateTime(2026, 5, 1));
    });
  });

  test('walk-in, draft and paid-up invoices are ignored', () {
    final report = buildOutstandingReport([
      sampleOpenInvoice(total: 1000, paid: 1000),
      sampleOpenInvoice(id: 'x').copyWith(customerId: null),
    ], now: now);
    expect(report.entries, isEmpty);
    expect(report.totalPaise, 0);
  });

  test('equal balances are ordered by name', () {
    final report = buildOutstandingReport([
      sampleOpenInvoice(
        id: 'a',
        customerId: 'c2',
        customerName: 'Zoya',
        total: 1000,
      ),
      sampleOpenInvoice(
        id: 'b',
        customerId: 'c1',
        customerName: 'Anil',
        total: 1000,
      ),
    ], now: now);
    expect(report.entries.map((e) => e.customerName), ['Anil', 'Zoya']);
  });
}
