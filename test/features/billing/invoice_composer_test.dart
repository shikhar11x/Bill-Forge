import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/billing/domain/cart_line.dart';
import 'package:billforge/features/billing/domain/discount.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/invoice_composer.dart';
import 'package:billforge/features/billing/domain/shop_tax_context.dart';
import 'package:billforge/features/products/domain/product_unit.dart';

import '../../support/customer_fakes.dart';

void main() {
  const registeredShop = ShopTaxContext(
    shopState: 'Haryana',
    pricesIncludeTax: false,
    chargesTax: true,
  );
  const unregisteredShop = ShopTaxContext(
    shopState: 'Haryana',
    pricesIncludeTax: false,
    chargesTax: false,
  );

  final lines = [
    const CartLine(
      productId: 'p1',
      name: 'Rice 5 kg',
      hsnCode: '1006',
      unit: ProductUnit.piece,
      unitPricePaise: 10000,
      qtyMilli: 2000,
      gstRatePercent: 5,
      trackStock: true,
      stockMilli: 50000,
    ),
  ];

  InvoiceDetail compose(ShopTaxContext shop, {customer}) => composeInvoice(
    id: 'inv_1',
    lines: lines,
    billDiscount: const Discount.none(),
    customer: customer,
    shop: shop,
    createdAt: DateTime(2026, 1, 1),
    now: DateTime(2026, 1, 2),
  );

  test('a walk-in sale in the shop state uses CGST+SGST', () {
    final d = compose(registeredShop);
    expect(d.invoice.isInterState, isFalse);
    expect(d.invoice.placeOfSupply, 'Haryana');
    expect(d.invoice.cgstPaise, 500);
    expect(d.invoice.sgstPaise, 500);
    expect(d.invoice.status, InvoiceStatus.draft);
    expect(d.invoice.invoiceNumber, isNull);
  });

  test('a customer in another state gets IGST', () {
    final d = compose(
      registeredShop,
      customer: sampleCustomer().copyWith(
        state: 'Delhi',
        gstin: '07AAPFU0939F1ZV',
      ),
    );
    expect(d.invoice.isInterState, isTrue);
    expect(d.invoice.placeOfSupply, 'Delhi');
    expect(d.invoice.igstPaise, 1000);
    expect(d.invoice.cgstPaise, 0);
    expect(d.invoice.customerGstin, '07AAPFU0939F1ZV');
  });

  test('a customer without a state defaults to the shop state', () {
    final d = compose(
      registeredShop,
      customer: sampleCustomer().copyWith(state: null),
    );
    expect(d.invoice.isInterState, isFalse);
    expect(d.invoice.placeOfSupply, 'Haryana');
  });

  test('unregistered shops never charge tax, even inter-state', () {
    final d = compose(
      unregisteredShop,
      customer: sampleCustomer().copyWith(state: 'Delhi'),
    );
    expect(d.invoice.isInterState, isFalse);
    expect(d.invoice.taxPaise, 0);
    expect(d.items.single.gstRatePercent, 0);
    expect(d.invoice.grandTotalPaise, 20000);
  });

  test('items are snapshots with stable ids and positions', () {
    final d = compose(registeredShop, customer: sampleCustomer());
    final item = d.items.single;
    expect(item.id, 'inv_1-1');
    expect(item.invoiceId, 'inv_1');
    expect(item.position, 0);
    expect(item.name, 'Rice 5 kg');
    expect(item.hsnCode, '1006');
    expect(item.qtyMilli, 2000);
    expect(
      item.totalPaise,
      d.invoice.grandTotalPaise - d.invoice.roundOffPaise,
    );
    expect(d.invoice.customerName, 'Rahul Sharma');
  });
}
