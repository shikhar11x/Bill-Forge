import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/payments/domain/payment_allocation.dart';
import '../../support/payment_fakes.dart';

void main() {
  final a = sampleOpenInvoice(
    id: 'a',
    number: 'INV-0001',
    total: 30000,
    issuedAt: DateTime(2026, 5, 1),
  );
  final b = sampleOpenInvoice(
    id: 'b',
    number: 'INV-0002',
    total: 50000,
    paid: 10000, // due 40000
    issuedAt: DateTime(2026, 5, 10),
  );
  final c = sampleOpenInvoice(
    id: 'c',
    number: 'INV-0003',
    total: 20000,
    issuedAt: DateTime(2026, 5, 20),
  );

  Map<String, int> asMap(List<Allocation> list) => {
        for (final x in list) x.invoiceId: x.amountPaise,
      };

  group('allocatePayment', () {
    test('pays the oldest invoice in full before moving to the next', () {
      // Input order is shuffled on purpose.
      final result = allocatePayment(60000, [c, a, b]);
      expect(result.map((x) => x.invoiceId), ['a', 'b']);
      expect(asMap(result), {'a': 30000, 'b': 30000});
    });

    test('an exact total clears everything', () {
      final result = allocatePayment(90000, [a, b, c]);
      expect(asMap(result), {'a': 30000, 'b': 40000, 'c': 20000});
    });

    test('a small payment goes to the oldest invoice only', () {
      final result = allocatePayment(5000, [a, b, c]);
      expect(asMap(result), {'a': 5000});
    });

    test('never allocates more than the amount', () {
      final result = allocatePayment(45000, [a, b, c]);
      expect(result.fold<int>(0, (s, x) => s + x.amountPaise), 45000);
    });

    test('ignores paid-up invoices', () {
      final paidUp = sampleOpenInvoice(
        id: 'p',
        total: 10000,
        paid: 10000,
        issuedAt: DateTime(2026, 4, 1),
      );
      expect(asMap(allocatePayment(5000, [paidUp, a])), {'a': 5000});
    });

    test('zero and negative amounts allocate nothing', () {
      expect(allocatePayment(0, [a]), isEmpty);
      expect(allocatePayment(-5, [a]), isEmpty);
    });

    test('same-day invoices are ordered by invoice number', () {
      final first = sampleOpenInvoice(
        id: 'x',
        number: 'INV-0009',
        total: 10000,
        issuedAt: DateTime(2026, 6, 1),
      );
      final second = sampleOpenInvoice(
        id: 'y',
        number: 'INV-0010',
        total: 10000,
        issuedAt: DateTime(2026, 6, 1),
      );
      expect(asMap(allocatePayment(10000, [second, first])), {'x': 10000});
    });
  });

  group('validateCollection', () {
    test('rejects zero and over-payment', () {
      expect(
        validateCollection(amountPaise: 0, duePaise: 1000),
        'Amount must be more than zero',
      );
      expect(
        validateCollection(amountPaise: 1500, duePaise: 1000),
        'Cannot be more than the ₹10.00 due',
      );
    });

    test('accepts up to the full balance', () {
      expect(validateCollection(amountPaise: 1000, duePaise: 1000), isNull);
      expect(validateCollection(amountPaise: 1, duePaise: 1000), isNull);
    });
  });
}