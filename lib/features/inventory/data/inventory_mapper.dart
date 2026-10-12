import 'package:drift/drift.dart' show Value;

import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/features/inventory/domain/movement_type.dart';
import 'package:billforge/features/inventory/domain/purchase.dart';
import 'package:billforge/features/inventory/domain/stock_movement.dart';
import 'package:billforge/features/inventory/domain/supplier.dart';
import 'package:billforge/features/products/domain/product_unit.dart';

StockMovement movementFromRow(StockMovementRow r) => StockMovement(
      id: r.id,
      productId: r.productId,
      type: MovementType.fromName(r.type),
      qtyMilli: r.qtyMilli,
      balanceAfterMilli: r.balanceAfterMilli,
      reason: r.reason == null ? null : AdjustmentReason.fromName(r.reason!),
      note: r.note,
      refType: r.refType,
      refId: r.refId,
      createdAt: r.createdAt,
    );

Supplier supplierFromRow(SupplierRow r) => Supplier(
      id: r.id,
      name: r.name,
      phone: r.phone,
      email: r.email,
      gstin: r.gstin,
      city: r.city,
      notes: r.notes,
      archivedAt: r.archivedAt,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );

SuppliersCompanion supplierToCompanion(Supplier s) => SuppliersCompanion(
      id: Value(s.id),
      name: Value(s.name),
      phone: Value(s.phone),
      email: Value(s.email),
      gstin: Value(s.gstin),
      city: Value(s.city),
      notes: Value(s.notes),
      archivedAt: Value(s.archivedAt),
      createdAt: Value(s.createdAt),
      updatedAt: Value(s.updatedAt),
    );

Purchase purchaseFromRow(PurchaseRow r) => Purchase(
      id: r.id,
      supplierId: r.supplierId,
      supplierName: r.supplierName,
      billNumber: r.billNumber,
      purchasedAt: r.purchasedAt,
      note: r.note,
      totalPaise: r.totalPaise,
      createdAt: r.createdAt,
    );

PurchasesCompanion purchaseToCompanion(Purchase p) => PurchasesCompanion(
      id: Value(p.id),
      supplierId: Value(p.supplierId),
      supplierName: Value(p.supplierName),
      billNumber: Value(p.billNumber),
      purchasedAt: Value(p.purchasedAt),
      note: Value(p.note),
      totalPaise: Value(p.totalPaise),
      createdAt: Value(p.createdAt),
    );

PurchaseItem purchaseItemFromRow(PurchaseItemRow r) => PurchaseItem(
      id: r.id,
      purchaseId: r.purchaseId,
      position: r.position,
      productId: r.productId,
      productName: r.productName,
      unit: ProductUnit.fromName(r.unit),
      qtyMilli: r.qtyMilli,
      unitCostPaise: r.unitCostPaise,
      totalPaise: r.totalPaise,
    );

PurchaseItemsCompanion purchaseItemToCompanion(PurchaseItem i) =>
    PurchaseItemsCompanion(
      id: Value(i.id),
      purchaseId: Value(i.purchaseId),
      position: Value(i.position),
      productId: Value(i.productId),
      productName: Value(i.productName),
      unit: Value(i.unit.name),
      qtyMilli: Value(i.qtyMilli),
      unitCostPaise: Value(i.unitCostPaise),
      totalPaise: Value(i.totalPaise),
    );