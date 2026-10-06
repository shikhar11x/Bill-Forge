import 'package:drift/drift.dart' show Value;

import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/features/products/domain/category.dart';
import 'package:billforge/features/products/domain/product.dart';
import 'package:billforge/features/products/domain/product_unit.dart';

Product productFromRow(ProductRow r) => Product(
  id: r.id,
  name: r.name,
  sku: r.sku,
  barcode: r.barcode,
  hsnCode: r.hsnCode,
  categoryId: r.categoryId,
  unit: ProductUnit.fromName(r.unit),
  purchasePricePaise: r.purchasePricePaise,
  sellingPricePaise: r.sellingPricePaise,
  mrpPaise: r.mrpPaise,
  gstRatePercent: r.gstRatePercent,
  trackStock: r.trackStock,
  stockMilli: r.stockMilli,
  lowStockThresholdMilli: r.lowStockThresholdMilli,
  archivedAt: r.archivedAt,
  createdAt: r.createdAt,
  updatedAt: r.updatedAt,
);

ProductsCompanion productToCompanion(Product p) => ProductsCompanion(
  id: Value(p.id),
  name: Value(p.name),
  sku: Value(p.sku),
  barcode: Value(p.barcode),
  hsnCode: Value(p.hsnCode),
  categoryId: Value(p.categoryId),
  unit: Value(p.unit.name),
  purchasePricePaise: Value(p.purchasePricePaise),
  sellingPricePaise: Value(p.sellingPricePaise),
  mrpPaise: Value(p.mrpPaise),
  gstRatePercent: Value(p.gstRatePercent),
  trackStock: Value(p.trackStock),
  stockMilli: Value(p.stockMilli),
  lowStockThresholdMilli: Value(p.lowStockThresholdMilli),
  archivedAt: Value(p.archivedAt),
  createdAt: Value(p.createdAt),
  updatedAt: Value(p.updatedAt),
);

Category categoryFromRow(CategoryRow r) =>
    Category(id: r.id, name: r.name, createdAt: r.createdAt);
