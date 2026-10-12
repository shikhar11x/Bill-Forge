import 'package:drift/drift.dart';

import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/core/database/stock_writer.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/features/inventory/data/inventory_mapper.dart';
import 'package:billforge/features/inventory/domain/movement_type.dart';
import 'package:billforge/features/inventory/domain/stock_movement.dart';
import 'package:billforge/features/inventory/domain/stock_repository.dart';

class DriftStockRepository implements StockRepository {
  DriftStockRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<StockMovement>> watchMovements(
    String productId, {
    required int limit,
  }) {
    final select = _db.select(_db.stockMovements)
      ..where((t) => t.productId.equals(productId))
      ..orderBy([
        (t) => OrderingTerm.desc(t.createdAt),
        // Dates have one-second resolution, so break ties by insert order.
        (t) => OrderingTerm(
          expression: const CustomExpression<int>('rowid'),
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(limit);
    return select.watch().map(
      (rows) => rows.map(movementFromRow).toList(growable: false),
    );
  }

  @override
  Future<void> adjust({
    required String productId,
    required int deltaMilli,
    required AdjustmentReason reason,
    String? note,
  }) {
    return _db.transaction(() async {
      final product = await (_db.select(
        _db.products,
      )..where((t) => t.id.equals(productId))).getSingleOrNull();
      if (product == null) {
        throw const ConflictFailure('That product no longer exists.');
      }
      if (!product.trackStock) {
        throw const ConflictFailure(
          'Stock tracking is off for this product. Turn it on in Products first.',
        );
      }
      if (deltaMilli == 0) {
        throw const ConflictFailure('There is no change to record.');
      }
      if (product.stockMilli + deltaMilli < 0) {
        throw const ConflictFailure('Stock cannot go below zero.');
      }
      await applyStockMovement(
        _db,
        productId: productId,
        type: reason.movementType,
        deltaMilli: deltaMilli,
        reason: reason,
        note: note,
      );
    });
  }
}
