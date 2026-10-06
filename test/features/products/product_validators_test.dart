import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/products/presentation/product_validators.dart';

void main() {
  test('hsn is optional but must be 4, 6 or 8 digits', () {
    expect(ProductValidators.hsn(''), isNull);
    expect(ProductValidators.hsn('1905'), isNull);
    expect(ProductValidators.hsn('190590'), isNull);
    expect(ProductValidators.hsn('12345'), 'HSN/SAC must be 4, 6 or 8 digits');
  });

  test('amount', () {
    final required = ProductValidators.amount(required: true, label: 'Price');
    expect(required(''), 'Price is required');
    expect(required('12.345'), isNotNull);
    expect(required('12.50'), isNull);

    final optional = ProductValidators.amount(required: false);
    expect(optional(''), isNull);
    expect(optional('x'), isNotNull);
  });

  test('quantity respects whether the unit allows decimals', () {
    final whole = ProductValidators.quantity(fractional: () => false);
    expect(whole('2'), isNull);
    expect(whole('2.5'), 'This unit cannot have decimals');

    final fractional = ProductValidators.quantity(fractional: () => true);
    expect(fractional('2.5'), isNull);
    expect(fractional('2.5555'), isNotNull);
    expect(fractional(''), 'Quantity is required');
  });
}
