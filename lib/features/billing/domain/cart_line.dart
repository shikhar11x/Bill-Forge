import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:billforge/features/billing/domain/discount.dart';
import 'package:billforge/features/products/domain/product.dart';
import 'package:billforge/features/products/domain/product_unit.dart';

part 'cart_line.freezed.dart';

/// Keeps every intermediate integer inside what JS numbers (web) hold exactly.
const kMaxQtyMilli = 9999999; // 9,999.999 units
const kMaxUnitPricePaise = 100000000; // ₹10,00,000

@freezed
abstract class CartLine with _$CartLine {
  const CartLine._();

  const factory CartLine({
    required String productId,
    required String name,
    String? hsnCode,
    required ProductUnit unit,
    required int unitPricePaise,

    /// Quantity in thousandths of [unit].
    required int qtyMilli,
    @Default(Discount.none()) Discount discount,
    required int gstRatePercent,

    /// Stock when the line was added; used only for a warning.
    required bool trackStock,
    required int stockMilli,
  }) = _CartLine;

  factory CartLine.fromProduct(Product product) => CartLine(
    productId: product.id,
    name: product.name,
    hsnCode: product.hsnCode,
    unit: product.unit,
    unitPricePaise: product.sellingPricePaise,
    qtyMilli: 1000,
    gstRatePercent: product.gstRatePercent,
    trackStock: product.trackStock,
    stockMilli: product.stockMilli,
  );

  bool get exceedsStock => trackStock && qtyMilli > stockMilli;
}
