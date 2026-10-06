import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/billing/domain/bill_calculator.dart';
import 'package:billforge/features/billing/domain/discount.dart';

void main() {
  group('Discount.applyTo', () {
    test('flat amount is capped at the base', () {
      expect(const Discount(DiscountType.amount, 500).applyTo(2000), 500);
      expect(const Discount(DiscountType.amount, 5000).applyTo(2000), 2000);
    });

    test('percent uses basis points and rounds half up', () {
      expect(const Discount(DiscountType.percent, 1000).applyTo(20000), 2000);
      expect(const Discount(DiscountType.percent, 1050).applyTo(1000), 105);
      // 12.5% of 1 paisa rounds to 0; 50% of 1 paisa rounds up to 1.
      expect(const Discount(DiscountType.percent, 5000).applyTo(1), 1);
      expect(const Discount(DiscountType.percent, 10000).applyTo(777), 777);
    });

    test('no discount or empty base gives zero', () {
      expect(const Discount.none().applyTo(1000), 0);
      expect(const Discount(DiscountType.amount, 100).applyTo(0), 0);
    });
  });

  group('parsing', () {
    test('parseBasisPoints', () {
      expect(parseBasisPoints('10'), 1000);
      expect(parseBasisPoints('10.5'), 1050);
      expect(parseBasisPoints('0.25'), 25);
      expect(parseBasisPoints('10.555'), isNull);
      expect(parseBasisPoints('abc'), isNull);
    });

    test('parseDiscount', () {
      expect(parseDiscount(DiscountType.amount, ''), const Discount.none());
      expect(
        parseDiscount(DiscountType.amount, '50'),
        const Discount(DiscountType.amount, 5000),
      );
      expect(
        parseDiscount(DiscountType.percent, '7.5'),
        const Discount(DiscountType.percent, 750),
      );
      expect(parseDiscount(DiscountType.amount, 'x'), isNull);
    });

    test('discountToInput and describeDiscount', () {
      expect(
        discountToInput(const Discount(DiscountType.amount, 5050)),
        '50.50',
      );
      expect(
        discountToInput(const Discount(DiscountType.percent, 1050)),
        '10.50',
      );
      expect(
        describeDiscount(const Discount(DiscountType.percent, 1000)),
        '10%',
      );
      expect(
        describeDiscount(const Discount(DiscountType.percent, 1050)),
        '10.5%',
      );
      expect(
        describeDiscount(const Discount(DiscountType.amount, 5000)),
        '₹50.00',
      );
    });
  });

  group('allocateProportionally', () {
    test('splits exactly in proportion', () {
      expect(allocateProportionally(1000, [10000, 30000]), [250, 750]);
    });

    test('gives the leftover paisa to the largest remainder', () {
      expect(allocateProportionally(1001, [10000, 30000]), [250, 751]);
    });

    test('always sums to the total', () {
      for (final total in [1, 7, 99, 1234]) {
        final shares = allocateProportionally(total, [333, 333, 334, 0]);
        expect(shares.fold<int>(0, (a, b) => a + b), total);
        expect(shares.last, 0);
      }
    });

    test('handles empty or zero weights', () {
      expect(allocateProportionally(100, []), isEmpty);
      expect(allocateProportionally(100, [0, 0]), [0, 0]);
      expect(allocateProportionally(0, [5, 5]), [0, 0]);
    });
  });
}
