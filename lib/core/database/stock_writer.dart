import 'package:drift/drift.dart';

import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/core/utils/ids.dart';
import 'package:billforge/features/inventory/domain/movement_type.dart';

/// The only place stock changes. Writes one ledger entry and keeps
/// `products.stockMilli` equal to the newest `balanceAfterMilli`.
///
/// Call it inside a database transaction. Returns the new balance, or null
/// when nothing was written (unknown product, tracking off, or zero change).
Future<int?> applyStockMovement(
  AppDatabase db, {
  required String productId,
  required MovementType type,
  required int deltaMilli,
  AdjustmentReason? reason,
  String? note,
  String? refType,
  String? refId,
  DateTime? at,
}) async {
  if (deltaMilli == 0) return null;

  final product = await (db.select(
    db.products,
  )..where((t) => t.id.equals(productId))).getSingleOrNull();
  if (product == null || !product.trackStock) return null;

  final now = at ?? DateTime.now();
  final balance = product.stockMilli + deltaMilli;

  await db
      .into(db.stockMovements)
      .insert(
        StockMovementsCompanion.insert(
          id: newId('mov'),
          productId: productId,
          type: type.name,
          qtyMilli: deltaMilli,
          balanceAfterMilli: balance,
          createdAt: now,
          reason: Value(reason?.name),
          note: Value(note),
          refType: Value(refType),
          refId: Value(refId),
        ),
      );
  await (db.update(db.products)..where((t) => t.id.equals(productId))).write(
    ProductsCompanion(stockMilli: Value(balance), updatedAt: Value(now)),
  );
  return balance;
}
