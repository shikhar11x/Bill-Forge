import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/billing/domain/credit_note.dart';
import 'package:billforge/features/billing/domain/credit_note_message.dart';

import '../../support/credit_note_fakes.dart';
import '../../support/fakes.dart';

void main() {
  final shop = sampleShop();

  test('names the credit note, the invoice and the items', () {
    final message = buildCreditNoteMessage(
      shop: shop,
      detail: sampleCreditNoteDetail(),
    );

    expect(message, contains('*Sharma General Store*'));
    expect(message, contains('Credit note CN-0001 · 12 Jun 2026'));
    expect(message, contains('Against invoice INV-0042'));
    expect(message, contains('Hello Rahul Sharma,'));
    expect(message, contains('• Basmati Rice 5 kg × 1 pcs = ₹450.00'));
    expect(message, contains('Credit note total: *₹450.00*'));
    expect(message, contains('Phone: 9876543210'));
  });

  test('shows the refund when money was paid back', () {
    final message = buildCreditNoteMessage(
      shop: shop,
      detail: sampleCreditNoteDetail(),
    );
    expect(message, contains('Refunded: ₹450.00 (Cash)'));
    expect(message, isNot(contains('Adjusted against your balance')));
  });

  test('shows the balance adjustment for a credit sale', () {
    final message = buildCreditNoteMessage(
      shop: shop,
      detail: sampleCreditNoteDetail(applied: 45000, refund: 0),
    );
    expect(message, contains('Adjusted against your balance: ₹450.00'));
    expect(message, isNot(contains('Refunded')));
  });

  test('long returns are summarised', () {
    final base = sampleCreditNoteDetail();
    final detail = CreditNoteDetail(
      creditNote: base.creditNote,
      items: [
        for (var i = 0; i < 8; i++)
          sampleCreditNoteItem(id: 'cn1-$i', name: 'Item $i'),
      ],
    );
    final message = buildCreditNoteMessage(shop: shop, detail: detail);
    expect(message, contains('(+2 more items)'));
    expect(message, isNot(contains('Item 7')));
  });
}
