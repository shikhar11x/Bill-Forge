import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'package:billforge/features/billing/data/invoices_table.dart';
import 'package:billforge/features/customers/data/customers_table.dart';
import 'package:billforge/features/products/data/categories_table.dart';
import 'package:billforge/features/products/data/products_table.dart';
import 'package:billforge/features/shop/data/shop_profiles_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    ShopProfiles,
    Categories,
    Products,
    Customers,
    Invoices,
    InvoiceItems,
    InvoicePayments,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(categories);
        await m.createTable(products);
        await _createIndexes(m, 'products_');
      }
      if (from < 3) {
        await m.createTable(customers);
        await _createIndexes(m, 'customers_');
      }
      if (from < 4) {
        await m.createTable(invoices);
        await m.createTable(invoiceItems);
        await m.createTable(invoicePayments);
        await _createIndexes(m, 'invoices_');
        await _createIndexes(m, 'invoice_items_');
        await _createIndexes(m, 'invoice_payments_');
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Creates only the indexes of one table, so each migration step stays
  /// independent of tables added in later versions.
  Future<void> _createIndexes(Migrator m, String prefix) async {
    final indexes = allSchemaEntities.whereType<Index>().where(
      (i) => i.entityName.startsWith(prefix),
    );
    for (final index in indexes) {
      await m.create(index);
    }
  }

  static QueryExecutor _openConnection() => driftDatabase(
    name: 'billforge',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
