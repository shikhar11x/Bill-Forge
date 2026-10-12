import 'package:drift/drift.dart';

import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/core/database/stock_writer.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/features/inventory/domain/movement_type.dart';
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
    return select
        .watch()
        .map((rows) => rows.map(productFromRow).toList(growable: false));
  }

  Expression<bool> _filter($ProductsTable t, ProductQuery q) {
    Expression<bool> e =
        q.showArchived ? t.archivedAt.isNotNull() : t.archivedAt.isNull();

    if (q.categoryId != null) e = e & t.categoryId.equals(q.categoryId!);

    final text = q.search.trim().toLowerCase();
    if (text.isNotEmpty) {
      e = e &
          (t.name.lower().contains(text) |
              t.sku.lower().contains(text) |
              t.barcode.lower().contains(text));
    }

    switch (q.stockFilter) {
      case StockFilter.all:
        break;
      case StockFilter.out:
        e = e &
            t.trackStock.equals(true) &
            t.stockMilli.isSmallerOrEqualValue(0);
      case StockFilter.low:
        e = e &
            t.trackStock.equals(true) &
            t.stockMilli.isBiggerThanValue(0) &
            t.stockMilli.isSmallerOrEqual(t.lowStockThresholdMilli);
      case StockFilter.attention:
        // The alert level is never negative, so this covers out of stock too.
        e = e &
            t.trackStock.equals(true) &
            t.stockMilli.isSmallerOrEqual(t.lowStockThresholdMilli);
    }
    return e;
  }

  @override
  Stream<int> watchLowStockCount() {
    final count = _db.products.id.count();
    final query = _db.selectOnly(_db.products)
      ..addColumns([count])
      ..where(
        _db.products.archivedAt.isNull() &
            _db.products.trackStock.equals(true) &
            _db.products.stockMilli
                .isSmallerOrEqual(_db.products.lowStockThresholdMilli),
      );
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  @override
  Future<Product?> getById(String id) async {
    final row = await (_db.select(_db.products)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
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

    await _db.transaction(() async {
      final existing = await (_db.select(_db.products)
            ..where((t) => t.id.equals(product.id)))
          .getSingleOrNull();
      final oldTracked = existing?.trackStock ?? false;
      final oldStock = existing?.stockMilli ?? 0;
      final newTracked = product.trackStock;

      // Tracking switched off: bring the ledger to zero while the row is
      // still tracked, so history and the stock figure stay consistent.
      if (existing != null && oldTracked && !newTracked && oldStock != 0) {
        await applyStockMovement(
          _db,
          productId: product.id,
          type: MovementType.adjustment,
          deltaMilli: -oldStock,
          note: 'Stock tracking turned off',
        );
      }

      // The row never takes a stock figure directly: whatever it holds is
      // already backed by the ledger, and any change is written as a movement.
      final carried = (oldTracked && newTracked) ? oldStock : 0;
      await _db.into(_db.products).insertOnConflictUpdate(
            productToCompanion(product).copyWith(stockMilli: Value(carried)),
          );

      if (newTracked) {
        final delta = product.stockMilli - carried;
        if (delta != 0) {
          await applyStockMovement(
            _db,
            productId: product.id,
            type: existing == null
                ? MovementType.opening
                : MovementType.adjustment,
            deltaMilli: delta,
            note: existing == null
                ? 'Opening balance'
                : (oldTracked
                    ? 'Edited in product form'
                    : 'Stock tracking turned on'),
          );
        }
      }
    });
  }

  Future<void> _ensureFree(
    Expression<bool> Function($ProductsTable t) match, {
    required String excludeId,
    required String message,
  }) async {
    final clash = await (_db.select(_db.products)
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