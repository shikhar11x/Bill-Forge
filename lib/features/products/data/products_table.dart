import 'package:drift/drift.dart';

import 'package:billforge/features/products/data/categories_table.dart';

@DataClassName('ProductRow')
@TableIndex(name: 'products_name_idx', columns: {#name})
@TableIndex(name: 'products_category_idx', columns: {#categoryId})
@TableIndex(name: 'products_archived_idx', columns: {#archivedAt})
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get sku => text().nullable()();
  TextColumn get barcode => text().nullable()();
  TextColumn get hsnCode => text().nullable()();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get unit => text()();
  IntColumn get purchasePricePaise => integer().nullable()();
  IntColumn get sellingPricePaise => integer()();
  IntColumn get mrpPaise => integer().nullable()();
  IntColumn get gstRatePercent => integer().withDefault(const Constant(0))();
  BoolColumn get trackStock => boolean().withDefault(const Constant(true))();
  IntColumn get stockMilli => integer().withDefault(const Constant(0))();
  IntColumn get lowStockThresholdMilli =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  /// SQLite allows many NULLs in a UNIQUE column, so SKU/barcode stay optional.
  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {sku},
    {barcode},
  ];
}
