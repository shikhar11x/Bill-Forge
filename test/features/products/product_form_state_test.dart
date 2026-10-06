import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/products/domain/product_unit.dart';
import 'package:billforge/features/products/presentation/product_form_state.dart';
import 'package:billforge/features/shop/domain/gst_registration.dart';

import '../../support/fakes.dart';

void main() {
  final registeredShop = sampleShop().copyWith(
    gstRegistration: GstRegistration.regular,
    defaultGstRate: 18,
    pricesIncludeTax: true,
  );

  ProductFormState form({bool registered = true}) {
    final f = ProductFormState(
      shop: registered ? registeredShop : sampleShop(),
    );
    addTearDown(f.dispose);
    return f;
  }

  test('converts text fields to storage units', () {
    final f = form()
      ..name.text = ' Rice '
      ..sku.text = 'rice-1'
      ..selling.text = '120.50'
      ..mrp.text = '130'
      ..stock.text = '2.5'
      ..lowStock.text = '1'
      ..setUnit(ProductUnit.kilogram);
    final product = f.toProduct(
      id: 'p',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    expect(product.name, 'Rice');
    expect(product.sku, 'RICE-1');
    expect(product.sellingPricePaise, 12050);
    expect(product.mrpPaise, 13000);
    expect(product.stockMilli, 2500);
    expect(product.lowStockThresholdMilli, 1000);
    expect(product.gstRatePercent, 18); // shop default
  });

  test('selling price cannot exceed MRP when prices include tax', () {
    final f = form()..mrp.text = '100';
    expect(f.validateSelling('120'), 'Selling price cannot exceed the MRP');
    expect(f.validateSelling('100'), isNull);
  });

  test('MRP cap is skipped when prices exclude tax', () {
    final f = ProductFormState(
      shop: registeredShop.copyWith(pricesIncludeTax: false),
    )..mrp.text = '100';
    addTearDown(f.dispose);
    expect(f.enforceMrpCap, isFalse);
    expect(f.validateSelling('120'), isNull);
  });

  test('unregistered shops store a 0% rate and hide GST', () {
    final f = form(registered: false)..selling.text = '10';
    expect(f.showGst, isFalse);
    final product = f.toProduct(
      id: 'p',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    expect(product.gstRatePercent, 0);
  });

  test('untracked products store zero stock', () {
    final f = form()
      ..selling.text = '10'
      ..stock.text = '5'
      ..setTrackStock(false);
    final product = f.toProduct(
      id: 'p',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    expect(product.stockMilli, 0);
  });
}
