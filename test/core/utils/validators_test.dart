import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/core/utils/validators.dart';

void main() {
  test('phone', () {
    expect(Validators.phone(''), 'Phone number is required');
    expect(Validators.phone('12345'), 'Enter a valid 10-digit mobile number');
    expect(Validators.phone('98765 43210'), isNull);
    expect(Validators.phone('+91-9876543210'), isNull);
  });

  test('pincode', () {
    expect(Validators.pincode('012345'), 'Enter a valid 6-digit PIN code');
    expect(Validators.pincode('122001'), isNull);
  });

  test('gstin (format only)', () {
    expect(Validators.gstin(''), 'GSTIN is required');
    expect(Validators.gstin('12345'), 'Enter a valid 15-character GSTIN');
    expect(Validators.gstin('27aapfu0939f1zv'), isNull);
  });

  test('invoicePrefix', () {
    expect(Validators.invoicePrefix('TOOLONGPREFIX'), isNotNull);
    expect(Validators.invoicePrefix('a b'), isNotNull);
    expect(Validators.invoicePrefix('INV-A'), isNull);
  });

  test('integerInRange and optional', () {
    final check = Validators.integerInRange(0, 40, label: 'Rate');
    expect(check('abc'), 'Rate must be a whole number');
    expect(check('41'), 'Rate must be between 0 and 40');
    expect(check('18'), isNull);
    expect(Validators.optional(Validators.email)(''), isNull);
    expect(Validators.optional(Validators.email)('x'), isNotNull);
  });
}
