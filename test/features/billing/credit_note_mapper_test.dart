import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/features/billing/data/credit_note_mapper.dart';
import 'package:billforge/features/billing/domain/credit_note.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/products/domain/product_unit.dart';

void main() {
  final when = DateTime(2026, 6, 12, 10);

  CreditNoteRow row({String reason = 'damaged', String? method = 'upi'}) =>
      CreditNoteRow(
        id: 'cn1',
        creditNoteNumber: 'CN-0001',
        invoiceId: 'inv_1',
        invoiceNumber: 'INV-0042',
        customerId: 'c1',
        customerName: 'Rahul Sharma',
        customerPhone: null,
        customerGstin: null,
        placeOfSupply: 'Haryana',
        isInterState: false,
        reason: reason,
        note: 'Torn packet',
        isCancellation: false,
        restocked: true,
        taxablePaise: 10000,
        cgstPaise: 250,
        sgstPaise: 250,
        igstPaise: 0,
        roundOffPaise: 0,
        totalPaise: 10500,
        appliedPaise: 500,
        refundPaise: 10000,
        refundMethod: method,
        issuedAt: when,
      );

  test('maps a credit note both ways', () {
    final note = creditNoteFromRow(row());
    expect(note.reason, ReturnReason.damaged);
    expect(note.refundMethod, PaymentMethod.upi);
    expect(note.taxPaise, 500);
    expect(note.appliedPaise + note.refundPaise, note.totalPaise);

    final companion = creditNoteToCompanion(note);
    expect(companion.creditNoteNumber.value, 'CN-0001');
    expect(companion.reason.value, 'damaged');
    expect(companion.refundMethod.value, 'upi');
  });

  test('unknown reasons fall back and a missing method stays null', () {
    final note = creditNoteFromRow(row(reason: 'removed', method: null));
    expect(note.reason, ReturnReason.other);
    expect(note.refundMethod, isNull);
  });

  test('maps a credit note item both ways', () {
    final item = creditNoteItemFromRow(
      const CreditNoteItemRow(
        id: 'cn1-1',
        creditNoteId: 'cn1',
        invoiceItemId: 'inv_1-1',
        position: 0,
        productId: 'p1',
        name: 'Toor Dal',
        hsnCode: '0713',
        unit: 'kilogram',
        qtyMilli: 2500,
        unitPricePaise: 15000,
        gstRatePercent: 5,
        taxablePaise: 37500,
        cgstPaise: 938,
        sgstPaise: 937,
        igstPaise: 0,
        totalPaise: 39375,
      ),
    );
    expect(item.unit, ProductUnit.kilogram);
    expect(item.invoiceItemId, 'inv_1-1');
    expect(creditNoteItemToCompanion(item).qtyMilli.value, 2500);
  });
}
