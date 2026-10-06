import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:billforge/features/products/domain/product_unit.dart';

part 'product.freezed.dart';

@freezed
abstract class Product with _$Product {
  const Product._();

  const factory Product({
    required String id,
    required String name,
    String? sku,
    String? barcode,
    String? hsnCode,
    String? categoryId,
    @Default(ProductUnit.piece) ProductUnit unit,

    /// Money is integer paise. Purchase price/MRP are optional.
    int? purchasePricePaise,
    required int sellingPricePaise,
    int? mrpPaise,
    @Default(0) int gstRatePercent,

    /// Quantities are integer thousandths of [unit].
    @Default(true) bool trackStock,
    @Default(0) int stockMilli,
    @Default(0) int lowStockThresholdMilli,
    DateTime? archivedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Product;

  bool get isArchived => archivedAt != null;
  bool get isOutOfStock => trackStock && stockMilli <= 0;
  bool get isLowStock =>
      trackStock && stockMilli > 0 && stockMilli <= lowStockThresholdMilli;
}
