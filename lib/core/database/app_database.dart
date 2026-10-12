import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'package:billforge/features/billing/data/invoices_table.dart';
import 'package:billforge/features/customers/data/customers_table.dart';
import 'package:billforge/features/inventory/data/purchases_table.dart';
import 'package:billforge/features/inventory/data/stock_movements_table.dart';
import 'package:billforge/features/inventory/data/suppliers_table.dart';
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
    Suppliers,
    Purchases,
    PurchaseItems,
    StockMovements,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

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
      if (from < 5) {
        await m.createTable(suppliers);
        await m.createTable(purchases);
        await m.createTable(purchaseItems);
        await m.createTable(stockMovements);
        await _createIndexes(m, 'suppliers_');
        await _createIndexes(m, 'purchases_');
        await _createIndexes(m, 'purchase_items_');
        await _createIndexes(m, 'stock_movements_');

        // Stock that exists today becomes each product's opening balance,
        // so the ledger adds up to the stock figure from day one.
        await customStatement('''
              INSERT INTO stock_movements
                (id, product_id, type, qty_milli, balance_after_milli, reason,
                 note, ref_type, ref_id, created_at)
              SELECT 'open_' || id, id, 'opening', stock_milli, stock_milli,
                     NULL, 'Opening balance', NULL, NULL,
                     CAST(strftime('%s', 'now') AS INTEGER)
              FROM products
              WHERE track_stock = 1 AND stock_milli != 0
            ''');
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
