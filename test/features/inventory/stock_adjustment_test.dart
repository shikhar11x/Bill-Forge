import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/inventory/domain/movement_type.dart';
import 'package:billforge/features/inventory/domain/stock_adjustment.dart';

String? validate(
  AdjustMode mode,
  String text, {
  int current = 10000,
  bool fractional = true,
}) =>
    validateAdjustment(
      mode: mode,
      currentMilli: current,
      text: text,
      fractional: fractional,
    );

void main() {
  group('validateAdjustment', () {
    test('needs a readable quantity', () {
      expect(validate(AdjustMode.add, ''), 'Enter a quantity');
      expect(validate(AdjustMode.add, 'abc'), isNotNull);
      expect(validate(AdjustMode.add, '1.2345'), isNotNull);
    });

    test('whole-number units reject decimals', () {
      expect(
        validate(AdjustMode.add, '2.5', fractional: false),
        'This unit cannot have decimals',
      );
      expect(validate(AdjustMode.add, '2', fractional: false), isNull);
    });

    test('add and remove need more than zero', () {
      expect(validate(AdjustMode.add, '0'), 'Quantity must be more than zero');
      expect(
        validate(AdjustMode.remove, '0'),
        'Quantity must be more than zero',
      );
    });

    test('cannot remove more than is in stock', () {
      expect(
        validate(AdjustMode.remove, '11'),
        'Cannot remove more than the current stock',
      );
      expect(validate(AdjustMode.remove, '10'), isNull);
    });

    test('set-to may be zero but not the current value', () {
      expect(validate(AdjustMode.setTo, '0'), isNull);
      expect(
        validate(AdjustMode.setTo, '10'),
        'This is already the current stock',
      );
    });

    test('rejects absurdly large quantities', () {
      expect(validate(AdjustMode.add, '10000'), 'Quantity is too large');
    });
  });

  group('computeAdjustment', () {
    test('set to a counted quantity', () {
      final a = computeAdjustment(
        mode: AdjustMode.setTo,
        currentMilli: 4000,
        text: '10',
      )!;
      expect(a.deltaMilli, 6000);
      expect(a.newStockMilli, 10000);
    });

    test('set to a lower quantity is a negative change', () {
      final a = computeAdjustment(
        mode: AdjustMode.setTo,
        currentMilli: 10000,
        text: '7.5',
      )!;
      expect(a.deltaMilli, -2500);
      expect(a.newStockMilli, 7500);
    });

    test('add and remove', () {
      final add = computeAdjustment(
        mode: AdjustMode.add,
        currentMilli: 10000,
        text: '2.5',
      )!;
      expect(add.deltaMilli, 2500);
      expect(add.newStockMilli, 12500);

      final remove = computeAdjustment(
        mode: AdjustMode.remove,
        currentMilli: 10000,
        text: '3',
      )!;
      expect(remove.deltaMilli, -3000);
      expect(remove.newStockMilli, 7000);
    });

    test('unreadable text gives null', () {
      expect(
        computeAdjustment(mode: AdjustMode.add, currentMilli: 0, text: 'x'),
        isNull,
      );
    });
  });

  test('returned-to-supplier is its own movement type', () {
    expect(
      AdjustmentReason.returnedToSupplier.movementType,
      MovementType.supplierReturn,
    );
    expect(AdjustmentReason.damaged.movementType, MovementType.adjustment);
    expect(AdjustmentReason.recount.movementType, MovementType.adjustment);
  });
}