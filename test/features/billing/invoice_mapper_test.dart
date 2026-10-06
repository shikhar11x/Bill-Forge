import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/features/billing/data/invoice_mapper.dart';
import 'package:billforge/features/billing/domain/discount.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/products/domain/product_unit.dart';

void main() {
  final when = DateTime(2026, 6, 1, 14, 5);

  final invoiceRow = InvoiceRow(
    id: 'inv_1',
    invoiceNumber: 'INV-0007',
    status: 'issued',
    customerId: 'c1',
    customerName: 'Rahul Sharma',
    customerPhone: '9876543210',
    customerGstin: null,
    placeOfSupply: 'Delhi',
    isInterState: true,
    pricesIncludeTax: false,
    billDiscountType: 'percent',
    billDiscountValue: 500,
    discountPaise: 1000,
    taxablePaise: 19000,
    cgstPaise: 0,
    sgstPaise: 0,
    igstPaise: 1900,
    roundOffPaise: 0,
    grandTotalPaise: 20900,
    paidPaise: 10000,
    issuedAt: when,
    createdAt: when,
    updatedAt: when,
  );

  test('maps an invoice row to the domain model', () {
    final invoice = invoiceFromRow(invoiceRow);
    expect(invoice.invoiceNumber, 'INV-0007');
    expect(invoice.status, InvoiceStatus.issued);
    expect(invoice.billDiscount, const Discount(DiscountType.percent, 500));
    expect(invoice.isInterState, isTrue);
    expect(invoice.duePaise, 10900);
    expect(invoice.paymentStatus, PaymentStatus.partial);
  });

  test('round-trips through a companion', () {
    final invoice = invoiceFromRow(invoiceRow);
    final companion = invoiceToCompanion(invoice);
    expect(companion.invoiceNumber.value, 'INV-0007');
    expect(companion.status.value, 'issued');
    expect(companion.billDiscountType.value, 'percent');
    expect(companion.billDiscountValue.value, 500);
    expect(companion.igstPaise.value, 1900);
  });

  test('maps items', () {
    final item = itemFromRow(
      const InvoiceItemRow(
        id: 'inv_1-1',
        invoiceId: 'inv_1',
        position: 0,
        productId: 'p1',
        name: 'Rice',
        hsnCode: '1006',
        unit: 'kilogram',
        qtyMilli: 2500,
        unitPricePaise: 8000,
        discountType: 'amount',
        discountValue: 500,
        gstRatePercent: 5,
        discountPaise: 500,
        taxablePaise: 19500,
        cgstPaise: 487,
        sgstPaise: 488,
        igstPaise: 0,
        totalPaise: 20475,
      ),
    );
    expect(item.unit, ProductUnit.kilogram);
    expect(item.qtyMilli, 2500);
    expect(item.discount, const Discount(DiscountType.amount, 500));
    expect(itemToCompanion(item).unit.value, 'kilogram');
  });

  test('maps payments and falls back on unknown methods', () {
    final payment = paymentFromRow(
      InvoicePaymentRow(
        id: 'pay_1',
        invoiceId: 'inv_1',
        method: 'upi',
        amountPaise: 5000,
        paidAt: when,
      ),
    );
    expect(payment.method, PaymentMethod.upi);

    final unknown = paymentFromRow(
      InvoicePaymentRow(
        id: 'pay_2',
        invoiceId: 'inv_1',
        method: 'removed',
        amountPaise: 1,
        paidAt: when,
      ),
    );
    expect(unknown.method, PaymentMethod.other);
  });
}
