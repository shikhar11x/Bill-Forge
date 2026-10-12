import 'package:flutter/material.dart';

import 'package:billforge/core/utils/money.dart';
import 'package:billforge/core/utils/quantity.dart';
import 'package:billforge/features/inventory/domain/purchase.dart';
import 'package:billforge/features/inventory/domain/purchase_math.dart';
import 'package:billforge/features/inventory/domain/supplier.dart';
import 'package:billforge/features/products/domain/product.dart';

class PurchaseLineEditor {
  PurchaseLineEditor(this.product, {String qty = '1', String cost = ''})
    : qty = TextEditingController(text: qty),
      cost = TextEditingController(text: cost);

  final Product product;
  final TextEditingController qty;
  final TextEditingController cost;

  int? get qtyMilli => parseMilli(qty.text);
  int? get costPaise => parsePaise(cost.text);

  int? get totalPaise {
    final q = qtyMilli;
    final c = costPaise;
    return (q == null || c == null) ? null : purchaseLineTotal(q, c);
  }

  void dispose() {
    qty.dispose();
    cost.dispose();
  }
}

class PurchaseFormState extends ChangeNotifier {
  PurchaseFormState({DateTime? now}) : date = now ?? DateTime.now();

  final billNumber = TextEditingController();
  final note = TextEditingController();
  final List<PurchaseLineEditor> lines = [];

  Supplier? supplier;
  DateTime date;
  bool updateCostPrices = true;

  /// Adds a line, prefilling the last known cost. False if already present.
  bool addProduct(Product product) {
    if (lines.any((l) => l.product.id == product.id)) return false;
    final last = product.purchasePricePaise;
    lines.add(
      PurchaseLineEditor(product, cost: last == null ? '' : paiseToInput(last)),
    );
    notifyListeners();
    return true;
  }

  void removeLine(PurchaseLineEditor line) {
    lines.remove(line);
    line.dispose();
    notifyListeners();
  }

  void setSupplier(Supplier? value) {
    supplier = value;
    notifyListeners();
  }

  void setDate(DateTime value) {
    date = value;
    notifyListeners();
  }

  void setUpdateCostPrices(bool value) {
    updateCostPrices = value;
    notifyListeners();
  }

  /// Rebuilds whoever depends on a typed quantity or cost.
  Listenable get fieldsListenable => Listenable.merge([
    this,
    for (final l in lines) ...[l.qty, l.cost],
  ]);

  int get totalPaise => lines.fold<int>(0, (s, l) => s + (l.totalPaise ?? 0));

  String? _optional(TextEditingController c) {
    final text = c.text.trim();
    return text.isEmpty ? null : text;
  }

  /// Call only after every line has validated.
  PurchaseDetail toDetail({required String id, required DateTime now}) {
    final items = <PurchaseItem>[
      for (var i = 0; i < lines.length; i++)
        PurchaseItem(
          id: '$id-${i + 1}',
          purchaseId: id,
          position: i,
          productId: lines[i].product.id,
          productName: lines[i].product.name,
          unit: lines[i].product.unit,
          qtyMilli: lines[i].qtyMilli!,
          unitCostPaise: lines[i].costPaise!,
          totalPaise: lines[i].totalPaise!,
        ),
    ];
    return PurchaseDetail(
      purchase: Purchase(
        id: id,
        supplierId: supplier?.id,
        supplierName: supplier?.name,
        billNumber: _optional(billNumber),
        purchasedAt: DateTime(date.year, date.month, date.day),
        note: _optional(note),
        totalPaise: items.fold<int>(0, (s, i) => s + i.totalPaise),
        createdAt: now,
      ),
      items: items,
    );
  }

  @override
  void dispose() {
    billNumber.dispose();
    note.dispose();
    for (final l in lines) {
      l.dispose();
    }
    super.dispose();
  }
}
