import 'package:billforge/features/inventory/domain/movement_type.dart';
import 'package:billforge/features/inventory/domain/stock_movement.dart';

abstract interface class StockRepository {
  /// Newest first.
  Stream<List<StockMovement>> watchMovements(
    String productId, {
    required int limit,
  });

  /// Throws `ConflictFailure` if stock tracking is off, the change is zero,
  /// or the result would be below zero.
  Future<void> adjust({
    required String productId,
    required int deltaMilli,
    required AdjustmentReason reason,
    String? note,
  });
}