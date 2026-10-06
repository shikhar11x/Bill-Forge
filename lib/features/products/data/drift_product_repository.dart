import 'package:drift/drift.dart';

import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/features/products/data/product_mapper.dart';
import 'package:billforge/features/products/domain/product.dart';
import 'package:billforge/features/products/domain/product_query.dart';
import 'package:billforge/features/products/domain/product_repository.dart';

class DriftProductRepository implements ProductRepository {
  DriftProductRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Product>> watchProducts(ProductQuery query) {
    final select = _db.select(_db.products)
      ..where((t) => _filter(t, query))
      ..orderBy([(t) => OrderingTerm.asc(t.name.collate(Collate.noCase))])
      ..limit(query.limit);
    return select.watch().map(
      (rows) => rows.map(productFromRow).toList(growable: false),
    );
  }

  Expression<bool> _filter($ProductsTable t, ProductQuery q) {
    Expression<bool> e = q.showArchived
        ? t.archivedAt.isNotNull()
        : t.archivedAt.isNull();

    if (q.categoryId != null) e = e & t.categoryId.equals(q.categoryId!);

    final text = q.search.trim().toLowerCase();
    if (text.isNotEmpty) {
      e =
          e &
          (t.name.lower().contains(text) |
              t.sku.lower().contains(text) |
              t.barcode.lower().contains(text));
    }

    switch (q.stockFilter) {
      case StockFilter.all:
        break;
      case StockFilter.out:
        e =
            e &
            t.trackStock.equals(true) &
            t.stockMilli.isSmallerOrEqualValue(0);
      case StockFilter.low:
        e =
            e &
            t.trackStock.equals(true) &
            t.stockMilli.isBiggerThanValue(0) &
            t.stockMilli.isSmallerOrEqual(t.lowStockThresholdMilli);
    }
    return e;
  }

  @override
  Future<Product?> getById(String id) async {
    final row = await (_db.select(
      _db.products,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : productFromRow(row);
  }

  @override
  Future<void> save(Product product) async {
    final sku = product.sku;
    if (sku != null) {
      await _ensureFree(
        (t) => t.sku.equals(sku),
        excludeId: product.id,
        message: 'Another product (possibly archived) already uses this SKU.',
      );
    }
    final barcode = product.barcode;
    if (barcode != null) {
      await _ensureFree(
        (t) => t.barcode.equals(barcode),
        excludeId: product.id,
        message:
            'Another product (possibly archived) already uses this barcode.',
      );
    }
    await _db
        .into(_db.products)
        .insertOnConflictUpdate(productToCompanion(product));
  }

  Future<void> _ensureFree(
    Expression<bool> Function($ProductsTable t) match, {
    required String excludeId,
    required String message,
  }) async {
    final clash =
        await (_db.select(_db.products)
              ..where((t) => match(t) & t.id.equals(excludeId).not())
              ..limit(1))
            .getSingleOrNull();
    if (clash != null) throw ConflictFailure(message);
  }

  @override
  Future<void> setArchived(String id, {required bool archived}) async {
    final now = DateTime.now();
    await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(
      ProductsCompanion(
        archivedAt: Value(archived ? now : null),
        updatedAt: Value(now),
      ),
    );
  }
}
