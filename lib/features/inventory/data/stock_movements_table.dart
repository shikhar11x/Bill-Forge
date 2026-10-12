import 'package:drift/drift.dart';

import 'package:billforge/features/products/data/products_table.dart';

@DataClassName('StockMovementRow')
@TableIndex(
  name: 'stock_movements_product_idx',
  columns: {#productId, #createdAt},
)
class StockMovements extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get type => text()();
  IntColumn get qtyMilli => integer()();
  IntColumn get balanceAfterMilli => integer()();
  TextColumn get reason => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get refType => text().nullable()();
  TextColumn get refId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}