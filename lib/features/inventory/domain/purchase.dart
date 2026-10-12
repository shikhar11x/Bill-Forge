import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:billforge/features/products/domain/product_unit.dart';

part 'purchase.freezed.dart';

@freezed
abstract class Purchase with _$Purchase {
  const factory Purchase({
    required String id,
    String? supplierId,

    /// Copied so renaming or archiving a supplier doesn't change history.
    String? supplierName,

    /// The supplier's own bill or invoice number.
    String? billNumber,
    required DateTime purchasedAt,
    String? note,
    required int totalPaise,
    required DateTime createdAt,
  }) = _Purchase;
}

@freezed
abstract class PurchaseItem with _$PurchaseItem {
  const factory PurchaseItem({
    required String id,
    required String purchaseId,
    required int position,
    required String productId,
    required String productName,
    required ProductUnit unit,
    required int qtyMilli,
    required int unitCostPaise,
    required int totalPaise,
  }) = _PurchaseItem;
}

class PurchaseDetail {
  const PurchaseDetail({required this.purchase, required this.items});

  final Purchase purchase;
  final List<PurchaseItem> items;
}