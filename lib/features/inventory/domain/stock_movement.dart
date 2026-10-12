import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:billforge/features/inventory/domain/movement_type.dart';

part 'stock_movement.freezed.dart';

@freezed
abstract class StockMovement with _$StockMovement {
  const StockMovement._();

  const factory StockMovement({
    required String id,
    required String productId,
    required MovementType type,

    /// Signed change in thousandths of the product's unit.
    required int qtyMilli,
    required int balanceAfterMilli,
    AdjustmentReason? reason,
    String? note,

    /// Links back to the invoice or purchase behind the movement.
    String? refType,
    String? refId,
    required DateTime createdAt,
  }) = _StockMovement;

  bool get isIncrease => qtyMilli > 0;

  /// "Damaged" for an adjustment with a reason, otherwise the type label.
  String get title => reason?.label ?? type.label;
}
