import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/shop/domain/invoice_number.dart';

void main() {
  test('pads the sequence number', () {
    expect(formatInvoiceNumber('INV', 7), 'INV-0007');
    expect(formatInvoiceNumber('INV', 1024), 'INV-1024');
    expect(formatInvoiceNumber('INV', 1234567), 'INV-1234567');
  });
}
