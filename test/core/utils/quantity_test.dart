import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/core/utils/quantity.dart';

void main() {
  test('parseMilli', () {
    expect(parseMilli('2.5'), 2500);
    expect(parseMilli('3'), 3000);
    expect(parseMilli('0.001'), 1);
    expect(parseMilli('1.2345'), isNull);
    expect(parseMilli(''), isNull);
    expect(parseMilli('-1'), isNull);
  });

  test('formatMilli trims trailing zeros', () {
    expect(formatMilli(2500), '2.5');
    expect(formatMilli(3000), '3');
    expect(formatMilli(1), '0.001');
    expect(formatMilli(1200), '1.2');
    expect(formatMilli(-500), '-0.5');
  });
}
