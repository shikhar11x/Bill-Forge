import 'package:drift/drift.dart';

import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/core/database/stock_writer.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/features/inventory/data/inventory_mapper.dart';
import 'package:billforge/features/inventory/domain/inventory_queries.dart';
import 'package:billforge/features/inventory/domain/movement_type.dart';
import 'package:billforge/features/inventory/domain/purchase.dart';
import 'package:billforge/features/inventory/domain/purchase_repository.dart';

class DriftPurchaseRepository implements PurchaseRepository {
  DriftPurchaseRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Purchase>> watchPurchases(PurchaseQuery query) {
    final select = _db.select(_db.purchases)
      ..where((t) => _filter(t, query))
      ..orderBy([
        (t) => OrderingTerm.desc(t.purchasedAt),
        (t) => OrderingTerm(
              expression: const CustomExpression<int>('rowid'),
              mode: OrderingMode.desc,
            ),
      ])
      ..limit(query.limit);
    return select
        .watch()
        .map((rows) => rows.map(purchaseFromRow).toList(growable: false));
  }

  Expression<bool> _filter($PurchasesTable t, PurchaseQuery q) {
    final text = q.search.trim().toLowerCase();
    if (text.isEmpty) return const Constant(true);
    return t.billNumber.lower().contains(text) |
        t.supplierName.lower().contains(text);
  }

  @override
  Future<PurchaseDetail?> getDetail(String id) async {
    final row = await (_db.select(_db.purchases)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    final items = await (_db.select(_db.purchaseItems)
          ..where((t) => t.purchaseId.equals(id))
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
    return PurchaseDetail(
      purchase: purchaseFromRow(row),
      items: items.map(purchaseItemFromRow).toList(growable: false),
    );
  }

  @override
  Future<void> receive(
    PurchaseDetail detail, {
    required bool updateCostPrices,
  }) {
    return _db.transaction(() async {
      final purchase = detail.purchase;
      if (detail.items.isEmpty) {
        throw const ConflictFailure('Add at least one product.');
      }

      for (final item in detail.items) {
        if (item.qtyMilli <= 0) {
          throw ConflictFailure('Enter a quantity for "${item.productName}".');
        }
        final product = await (_db.select(_db.products)
              ..where((t) => t.id.equals(item.productId)))
            .getSingleOrNull();
        if (product == null) {
          throw ConflictFailure('"${item.productName}" no longer exists.');
        }
        if (!product.trackStock) {
          throw ConflictFailure(
            '"${item.productName}" has stock tracking turned off.',
          );
        }
      }

      await _db.into(_db.purchases).insert(purchaseToCompanion(purchase));
      for (final item in detail.items) {
        await _db
            .into(_db.purchaseItems)
            .insert(purchaseItemToCompanion(item));
      }

      final note = [
        purchase.supplierName,
        if (purchase.billNumber != null) 'Bill ${purchase.billNumber}',
      ].whereType<String>().join(' · ');

      for (final item in detail.items) {
        await applyStockMovement(
          _db,
          productId: item.productId,
          type: MovementType.purchase,
          deltaMilli: item.qtyMilli,
          refType: StockRef.purchase,
          refId: purchase.id,
          note: note.isEmpty ? null : note,
          at: purchase.createdAt,
        );
        if (updateCostPrices) {
          await (_db.update(_db.products)
                ..where((t) => t.id.equals(item.productId)))
              .write(
            ProductsCompanion(
              purchasePricePaise: Value(item.unitCostPaise),
              updatedAt: Value(purchase.createdAt),
            ),
          );
        }
      }
    });
  }
}