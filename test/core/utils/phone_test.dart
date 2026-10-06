import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/core/utils/phone.dart';

void main() {
  test('normalizeIndianPhone keeps the 10 digits', () {
    expect(normalizeIndianPhone('9876543210'), '9876543210');
    expect(normalizeIndianPhone('98765 43210'), '9876543210');
    expect(normalizeIndianPhone('+91 98765-43210'), '9876543210');
    expect(normalizeIndianPhone('+919876543210'), '9876543210');
  });
}
