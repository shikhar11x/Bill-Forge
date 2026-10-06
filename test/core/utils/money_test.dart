import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/utils/money.dart';

void main() {
  test('parsePaise', () {
    expect(parsePaise('12'), 1200);
    expect(parsePaise('12.5'), 1250);
    expect(parsePaise('12.05'), 1205);
    expect(parsePaise('1,250.00'), 125000);
    expect(parsePaise('12.345'), isNull);
    expect(parsePaise(''), isNull);
    expect(parsePaise('abc'), isNull);
    expect(parsePaise('-5'), isNull);
  });

  test('paiseToInput', () {
    expect(paiseToInput(1250), '12.50');
    expect(paiseToInput(5), '0.05');
  });

  test('formatPaise uses Indian grouping', () {
    expect(formatPaise(0), '₹0.00');
    expect(formatPaise(123456789), '₹12,34,567.89');
    expect(formatPaise(-3450), '-₹34.50');
    expect(formatPaise(150000, showDecimals: false), '₹1,500');
  });
}
