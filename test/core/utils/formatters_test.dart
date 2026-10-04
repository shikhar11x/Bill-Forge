import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/core/utils/formatters.dart';

void main() {
  group('formatInr', () {
    test('formats small amounts', () {
      expect(formatInr(0), '₹0.00');
      expect(formatInr(999), '₹999.00');
    });

    test('uses Indian digit grouping', () {
      expect(formatInr(1000), '₹1,000.00');
      expect(formatInr(100000), '₹1,00,000.00');
      expect(formatInr(1234567.5), '₹12,34,567.50');
      expect(formatInr(123456789), '₹12,34,56,789.00');
    });

    test('handles negatives and zero decimals', () {
      expect(formatInr(-3450), '-₹3,450.00');
      expect(formatInr(3450, decimals: 0), '₹3,450');
    });
  });
}