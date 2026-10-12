import 'package:billforge/core/utils/quantity.dart';
import 'package:billforge/features/inventory/domain/purchase_math.dart';

enum AdjustMode {
  setTo('Set to'),
  add('Add'),
  remove('Remove');

  const AdjustMode(this.label);

  final String label;
}

class Adjustment {
  const Adjustment({required this.deltaMilli, required this.newStockMilli});

  final int deltaMilli;
  final int newStockMilli;
}

/// A user-facing problem with the entered quantity, or null when it is valid.
String? validateAdjustment({
  required AdjustMode mode,
  required int currentMilli,
  required String text,
  required bool fractional,
}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 'Enter a quantity';
  final milli = parseMilli(trimmed);
  if (milli == null) return 'Enter a valid number (up to 3 decimals)';
  if (!fractional && milli % 1000 != 0) return 'This unit cannot have decimals';
  if (milli > kMaxStockQtyMilli) return 'Quantity is too large';
  if (mode != AdjustMode.setTo && milli == 0) {
    return 'Quantity must be more than zero';
  }
  if (mode == AdjustMode.remove && milli > currentMilli) {
    return 'Cannot remove more than the current stock';
  }
  if (mode == AdjustMode.setTo && milli == currentMilli) {
    return 'This is already the current stock';
  }
  return null;
}

/// The change implied by the entered text, or null if it can't be read.
Adjustment? computeAdjustment({
  required AdjustMode mode,
  required int currentMilli,
  required String text,
}) {
  final milli = parseMilli(text.trim());
  if (milli == null) return null;
  final delta = switch (mode) {
    AdjustMode.setTo => milli - currentMilli,
    AdjustMode.add => milli,
    AdjustMode.remove => -milli,
  };
  return Adjustment(deltaMilli: delta, newStockMilli: currentMilli + delta);
}