import 'package:flutter/material.dart';

import 'package:billforge/core/utils/money.dart';
import 'package:billforge/core/utils/quantity.dart';
import 'package:billforge/features/products/domain/product.dart';
import 'package:billforge/features/products/domain/product_unit.dart';
import 'package:billforge/features/products/presentation/product_validators.dart';
import 'package:billforge/features/shop/domain/shop_profile.dart';

class ProductFormState extends ChangeNotifier {
  ProductFormState({required this.shop, Product? existing})
    : name = TextEditingController(text: existing?.name),
      sku = TextEditingController(text: existing?.sku),
      barcode = TextEditingController(text: existing?.barcode),
      hsn = TextEditingController(text: existing?.hsnCode),
      purchase = TextEditingController(
        text: _money(existing?.purchasePricePaise),
      ),
      selling = TextEditingController(
        text: _money(existing?.sellingPricePaise),
      ),
      mrp = TextEditingController(text: _money(existing?.mrpPaise)),
      gstRate = TextEditingController(
        text: '${existing?.gstRatePercent ?? shop.defaultGstRate}',
      ),
      stock = TextEditingController(
        text: formatMilli(existing?.stockMilli ?? 0),
      ),
      lowStock = TextEditingController(
        text: formatMilli(existing?.lowStockThresholdMilli ?? 0),
      ),
      unit = existing?.unit ?? ProductUnit.piece,
      categoryId = existing?.categoryId,
      trackStock = existing?.trackStock ?? true;

  static String _money(int? paise) => paise == null ? '' : paiseToInput(paise);

  final ShopProfile shop;

  final TextEditingController name;
  final TextEditingController sku;
  final TextEditingController barcode;
  final TextEditingController hsn;
  final TextEditingController purchase;
  final TextEditingController selling;
  final TextEditingController mrp;
  final TextEditingController gstRate;
  final TextEditingController stock;
  final TextEditingController lowStock;

  ProductUnit unit;
  String? categoryId;
  bool trackStock;

  /// Bumped to force the category dropdown to redraw (e.g. after cancelling
  /// the "new category" prompt).
  int categoryRevision = 0;

  /// GST fields only apply to regular taxpayers.
  bool get showGst => shop.gstRegistration.chargesTax;

  /// MRP includes all taxes, so the "selling price <= MRP" rule only makes
  /// sense when the entered selling price is also tax-inclusive (or untaxed).
  bool get enforceMrpCap => shop.pricesIncludeTax || !showGst;

  void setUnit(ProductUnit v) {
    unit = v;
    notifyListeners();
  }

  void setCategory(String? v) {
    categoryId = v;
    categoryRevision++;
    notifyListeners();
  }

  void bumpCategoryField() {
    categoryRevision++;
    notifyListeners();
  }

  void setTrackStock(bool v) {
    trackStock = v;
    notifyListeners();
  }

  String? validateSelling(String? value) {
    final base = ProductValidators.amount(
      required: true,
      label: 'Selling price',
    )(value);
    if (base != null) return base;
    if (enforceMrpCap) {
      final mrpPaise = parsePaise(mrp.text);
      final sellingPaise = parsePaise(value!);
      if (mrpPaise != null && sellingPaise != null && sellingPaise > mrpPaise) {
        return 'Selling price cannot exceed the MRP';
      }
    }
    return null;
  }

  String? _optional(TextEditingController c) {
    final text = c.text.trim();
    return text.isEmpty ? null : text;
  }

  /// Call only after the form has validated.
  Product toProduct({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? archivedAt,
  }) {
    return Product(
      id: id,
      name: name.text.trim(),
      sku: _optional(sku)?.toUpperCase(),
      barcode: _optional(barcode),
      hsnCode: _optional(hsn),
      categoryId: categoryId,
      unit: unit,
      purchasePricePaise: parsePaise(purchase.text),
      sellingPricePaise: parsePaise(selling.text)!,
      mrpPaise: parsePaise(mrp.text),
      gstRatePercent: showGst ? int.parse(gstRate.text.trim()) : 0,
      trackStock: trackStock,
      stockMilli: trackStock ? parseMilli(stock.text)! : 0,
      lowStockThresholdMilli: trackStock ? parseMilli(lowStock.text)! : 0,
      archivedAt: archivedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  void dispose() {
    for (final c in [
      name,
      sku,
      barcode,
      hsn,
      purchase,
      selling,
      mrp,
      gstRate,
      stock,
      lowStock,
    ]) {
      c.dispose();
    }
    super.dispose();
  }
}
