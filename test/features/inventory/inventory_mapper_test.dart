import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/features/inventory/data/inventory_mapper.dart';
import 'package:billforge/features/inventory/domain/movement_type.dart';
import 'package:billforge/features/products/domain/product_unit.dart';

void main() {
  final when = DateTime(2026, 6, 1, 14, 5);

  test('maps a stock movement, with fallbacks for unknown names', () {
    final movement = movementFromRow(
      StockMovementRow(
        id: 'm1',
        productId: 'p1',
        type: 'supplierReturn',
        qtyMilli: -3000,
        balanceAfterMilli: 7000,
        reason: 'returnedToSupplier',
        note: 'Faulty batch',
        refType: null,
        refId: null,
        createdAt: when,
      ),
    );
    expect(movement.type, MovementType.supplierReturn);
    expect(movement.reason, AdjustmentReason.returnedToSupplier);
    expect(movement.isIncrease, isFalse);
    expect(movement.title, 'Returned to supplier');

    final unknown = movementFromRow(
      StockMovementRow(
        id: 'm2',
        productId: 'p1',
        type: 'removed_type',
        qtyMilli: 1000,
        balanceAfterMilli: 1000,
        reason: null,
        note: null,
        refType: 'invoice',
        refId: 'inv_1',
        createdAt: when,
      ),
    );
    expect(unknown.type, MovementType.adjustment);
    expect(unknown.title, 'Adjustment');
    expect(unknown.refType, StockRef.invoice);
  });

  test('maps a supplier both ways', () {
    final supplier = supplierFromRow(
      SupplierRow(
        id: 's1',
        name: 'Metro Wholesale',
        phone: '9876543210',
        email: null,
        gstin: '07AAPFU0939F1ZV',
        city: 'Delhi',
        notes: null,
        archivedAt: null,
        createdAt: when,
        updatedAt: when,
      ),
    );
    expect(supplier.name, 'Metro Wholesale');
    expect(supplier.isArchived, isFalse);

    final companion = supplierToCompanion(supplier);
    expect(companion.gstin.value, '07AAPFU0939F1ZV');
    expect(companion.email.value, isNull);
  });

  test('maps a purchase and its items', () {
    final purchase = purchaseFromRow(
      PurchaseRow(
        id: 'pur_1',
        supplierId: 's1',
        supplierName: 'Metro Wholesale',
        billNumber: 'B-77',
        purchasedAt: DateTime(2026, 6, 1),
        note: null,
        totalPaise: 38000,
        createdAt: when,
      ),
    );
    expect(purchase.billNumber, 'B-77');
    expect(purchaseToCompanion(purchase).totalPaise.value, 38000);

    final item = purchaseItemFromRow(
      const PurchaseItemRow(
        id: 'pur_1-1',
        purchaseId: 'pur_1',
        position: 0,
        productId: 'p1',
        productName: 'Toor Dal',
        unit: 'kilogram',
        qtyMilli: 2500,
        unitCostPaise: 12000,
        totalPaise: 30000,
      ),
    );
    expect(item.unit, ProductUnit.kilogram);
    expect(purchaseItemToCompanion(item).unit.value, 'kilogram');
  });
}