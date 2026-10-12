import 'package:drift/drift.dart';

import 'package:billforge/features/inventory/data/suppliers_table.dart';
import 'package:billforge/features/products/data/products_table.dart';

@DataClassName('PurchaseRow')
@TableIndex(name: 'purchases_date_idx', columns: {#purchasedAt})
@TableIndex(name: 'purchases_supplier_idx', columns: {#supplierId})
class Purchases extends Table {
  TextColumn get id => text()();
  TextColumn get supplierId =>
      text().nullable().references(Suppliers, #id)();
  TextColumn get supplierName => text().nullable()();
  TextColumn get billNumber => text().nullable()();
  DateTimeColumn get purchasedAt => dateTime()();
  TextColumn get note => text().nullable()();
  IntColumn get totalPaise => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('PurchaseItemRow')
@TableIndex(name: 'purchase_items_purchase_idx', columns: {#purchaseId})
class PurchaseItems extends Table {
  TextColumn get id => text()();
  TextColumn get purchaseId =>
      text().references(Purchases, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get productName => text()();
  TextColumn get unit => text()();
  IntColumn get qtyMilli => integer()();
  IntColumn get unitCostPaise => integer()();
  IntColumn get totalPaise => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}