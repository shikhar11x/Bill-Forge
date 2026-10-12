import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/billing/domain/invoice_message.dart';
import 'package:billforge/features/shop/domain/gst_registration.dart';

import '../../support/fakes.dart';
import '../../support/invoice_document_fakes.dart';

void main() {
  test('has the shop, invoice, items and totals', () {
    final message = buildInvoiceMessage(makeInvoiceDocument());

    expect(message, contains('*Sharma General Store*'));
    expect(message, contains('Invoice INV-0042 · 01 Jun 2026'));
    expect(message, contains('Hello Rahul Sharma,'));
    expect(message, contains('• Basmati Rice 5 kg × 2 pcs = ₹900.00'));
    expect(message, contains('• Toor Dal × 2.5 kg = ₹375.00'));
    expect(message, contains('Total: *₹1,275.00*'));
    expect(message, contains('Paid: ₹500.00'));
    expect(message, contains('Balance due: *₹775.00*'));
    expect(message, contains('Phone: 9876543210'));
    expect(message, contains('Thank you!'));
  });

  test('asks for payment only while something is owed', () {
    final owing = buildInvoiceMessage(makeInvoiceDocument());
    expect(owing, contains('Pay via:\nUPI: sharma@upi'));

    final paid = buildInvoiceMessage(makeInvoiceDocument(paidPaise: 127500));
    expect(paid, isNot(contains('Balance due')));
    expect(paid, isNot(contains('Pay via')));
    expect(paid, contains('Paid: ₹1,275.00'));
  });

  test('a fully credit sale shows no Paid line', () {
    final message = buildInvoiceMessage(makeInvoiceDocument(paidPaise: 0));
    expect(message, isNot(contains('Paid:')));
    expect(message, contains('Balance due: *₹1,275.00*'));
  });

  test('walk-in customers get a plain greeting', () {
    final message = buildInvoiceMessage(makeInvoiceDocument(walkIn: true));
    expect(message, contains('Hello,'));
    expect(message, isNot(contains('Hello Rahul')));
  });

  test('uses the document title for the shop type', () {
    final shop = sampleShop().copyWith(
      gstRegistration: GstRegistration.composition,
      gstin: '06AAPFU0939F1ZV',
    );
    final message = buildInvoiceMessage(makeInvoiceDocument(shop: shop));
    expect(message, contains('Bill of Supply INV-0042'));
  });

  test('long bills list the first items and summarise the rest', () {
    final message = buildInvoiceMessage(makeInvoiceDocument(extraItems: 6));
    expect(message, contains('(+2 more items)'));
    expect(message, isNot(contains('Extra item 5')));

    final one = buildInvoiceMessage(makeInvoiceDocument(extraItems: 5));
    expect(one, contains('(+1 more item)'));
  });

  test('very long item names are shortened', () {
    final message = buildInvoiceMessage(
      makeInvoiceDocument(firstItemName: 'A' * 80),
    );
    expect(message, isNot(contains('A' * 41)));
    expect(message, contains('…'));
  });

  test('stays well under URL limits for a 20-item bill', () {
    final message = buildInvoiceMessage(makeInvoiceDocument(extraItems: 18));
    expect(Uri.encodeComponent(message).length, lessThan(2000));
  });
}
