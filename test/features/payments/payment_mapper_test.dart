import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/features/billing/data/invoice_mapper.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/payments/data/payment_mapper.dart';

void main() {
  final when = DateTime(2026, 6, 12, 9);

  test('maps a receipt both ways', () {
    final receipt = receiptFromRow(
      CustomerPaymentRow(
        id: 'r1',
        customerId: 'c1',
        method: 'upi',
        amountPaise: 70000,
        note: 'Part payment',
        receivedAt: when,
        createdAt: when,
      ),
    );
    expect(receipt.method, PaymentMethod.upi);
    expect(receipt.amountPaise, 70000);
    expect(receipt.note, 'Part payment');

    final companion = receiptToCompanion(receipt);
    expect(companion.method.value, 'upi');
    expect(companion.amountPaise.value, 70000);
    expect(companion.customerId.value, 'c1');
  });

  test('an unknown stored method falls back to other', () {
    final receipt = receiptFromRow(
      CustomerPaymentRow(
        id: 'r2',
        customerId: 'c1',
        method: 'removed',
        amountPaise: 100,
        note: null,
        receivedAt: when,
        createdAt: when,
      ),
    );
    expect(receipt.method, PaymentMethod.other);
    expect(receipt.note, isNull);
  });

  test('an invoice keeps its due date through the mapper', () {
    final row = InvoiceRow(
      id: 'inv_1',
      invoiceNumber: 'INV-0007',
      status: 'issued',
      customerId: 'c1',
      customerName: 'Rahul Sharma',
      customerPhone: null,
      customerGstin: null,
      placeOfSupply: 'Haryana',
      isInterState: false,
      pricesIncludeTax: true,
      billDiscountType: 'amount',
      billDiscountValue: 0,
      discountPaise: 0,
      taxablePaise: 10000,
      cgstPaise: 0,
      sgstPaise: 0,
      igstPaise: 0,
      roundOffPaise: 0,
      grandTotalPaise: 10000,
      paidPaise: 4000,
      creditedPaise: 0,
      dueDate: DateTime(2026, 7, 1),
      issuedAt: when,
      createdAt: when,
      updatedAt: when,
    );

    final invoice = invoiceFromRow(row);
    expect(invoice.dueDate, DateTime(2026, 7, 1));
    expect(invoice.duePaise, 6000);
    expect(invoiceToCompanion(invoice).dueDate.value, DateTime(2026, 7, 1));
  });

  test('an invoice payment keeps its receipt link', () {
    final collected = paymentFromRow(
      InvoicePaymentRow(
        id: 'pay_1',
        invoiceId: 'inv_1',
        method: 'cash',
        amountPaise: 5000,
        paidAt: when,
        receiptId: 'r1',
      ),
    );
    expect(collected.receiptId, 'r1');

    final atSale = paymentFromRow(
      InvoicePaymentRow(
        id: 'pay_2',
        invoiceId: 'inv_1',
        method: 'cash',
        amountPaise: 5000,
        paidAt: when,
        receiptId: null,
      ),
    );
    expect(atSale.receiptId, isNull);
  });
}
