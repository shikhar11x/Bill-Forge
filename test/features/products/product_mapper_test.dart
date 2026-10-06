import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/features/products/data/product_mapper.dart';
import 'package:billforge/features/products/domain/product.dart';
import 'package:billforge/features/products/domain/product_unit.dart';

void main() {
  final created = DateTime(2026, 1, 1);

  ProductRow row({String unit = 'kilogram'}) => ProductRow(
    id: 'p1',
    name: 'Basmati Rice',
    sku: 'RICE-1',
    barcode: null,
    hsnCode: '1006',
    categoryId: 'cat_1',
    unit: unit,
    purchasePricePaise: 8000,
    sellingPricePaise: 10000,
    mrpPaise: 12000,
    gstRatePercent: 5,
    trackStock: true,
    stockMilli: 2500,
    lowStockThresholdMilli: 1000,
    archivedAt: null,
    createdAt: created,
    updatedAt: created,
  );

  test('maps a row to the domain model', () {
    expect(
      productFromRow(row()),
      Product(
        id: 'p1',
        name: 'Basmati Rice',
        sku: 'RICE-1',
        hsnCode: '1006',
        categoryId: 'cat_1',
        unit: ProductUnit.kilogram,
        purchasePricePaise: 8000,
        sellingPricePaise: 10000,
        mrpPaise: 12000,
        gstRatePercent: 5,
        stockMilli: 2500,
        lowStockThresholdMilli: 1000,
        createdAt: created,
        updatedAt: created,
      ),
    );
  });

  test('unknown unit names fall back to piece', () {
    expect(productFromRow(row(unit: 'removed')).unit, ProductUnit.piece);
  });

  test('maps the domain model to a companion', () {
    final companion = productToCompanion(productFromRow(row()));
    expect(companion.name.value, 'Basmati Rice');
    expect(companion.unit.value, 'kilogram');
    expect(companion.sellingPricePaise.value, 10000);
    expect(companion.barcode.value, isNull);
  });
}
