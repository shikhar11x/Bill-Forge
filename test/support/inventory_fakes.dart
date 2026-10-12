import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/features/inventory/domain/inventory_queries.dart';
import 'package:billforge/features/inventory/domain/movement_type.dart';
import 'package:billforge/features/inventory/domain/purchase.dart';
import 'package:billforge/features/inventory/domain/purchase_repository.dart';
import 'package:billforge/features/inventory/domain/stock_movement.dart';
import 'package:billforge/features/inventory/domain/stock_repository.dart';
import 'package:billforge/features/inventory/domain/supplier.dart';
import 'package:billforge/features/inventory/domain/supplier_repository.dart';

Supplier sampleSupplier({
  String id = 's1',
  String name = 'Metro Wholesale',
  DateTime? archivedAt,
}) => Supplier(
  id: id,
  name: name,
  archivedAt: archivedAt,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

class AdjustCall {
  const AdjustCall(this.productId, this.deltaMilli, this.reason, this.note);

  final String productId;
  final int deltaMilli;
  final AdjustmentReason reason;
  final String? note;
}

class FakeStockRepository implements StockRepository {
  FakeStockRepository({this.movements = const []});

  final List<StockMovement> movements;
  final List<AdjustCall> calls = [];
  ConflictFailure? failure;

  @override
  Stream<List<StockMovement>> watchMovements(
    String productId, {
    required int limit,
  }) => Stream.value(movements.take(limit).toList());

  @override
  Future<void> adjust({
    required String productId,
    required int deltaMilli,
    required AdjustmentReason reason,
    String? note,
  }) async {
    if (failure != null) throw failure!;
    calls.add(AdjustCall(productId, deltaMilli, reason, note));
  }
}

class FakeSupplierRepository implements SupplierRepository {
  FakeSupplierRepository([List<Supplier> suppliers = const []])
    : _suppliers = List.of(suppliers);

  final List<Supplier> _suppliers;
  Supplier? saved;

  @override
  Stream<List<Supplier>> watchSuppliers(SupplierQuery query) {
    final search = query.search.trim().toLowerCase();
    return Stream.value(
      _suppliers
          .where((s) => s.isArchived == query.showArchived)
          .where((s) => search.isEmpty || s.name.toLowerCase().contains(search))
          .toList(),
    );
  }

  @override
  Future<Supplier?> getById(String id) async {
    for (final s in _suppliers) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Future<void> save(Supplier supplier) async {
    saved = supplier;
    _suppliers
      ..removeWhere((s) => s.id == supplier.id)
      ..add(supplier);
  }

  @override
  Future<void> setArchived(String id, {required bool archived}) async {}
}

class FakePurchaseRepository implements PurchaseRepository {
  FakePurchaseRepository([List<PurchaseDetail> purchases = const []])
    : _purchases = List.of(purchases);

  final List<PurchaseDetail> _purchases;
  PurchaseDetail? received;
  bool? receivedUpdateCosts;

  @override
  Stream<List<Purchase>> watchPurchases(PurchaseQuery query) => Stream.value(
    _purchases.map((d) => d.purchase).take(query.limit).toList(),
  );

  @override
  Future<PurchaseDetail?> getDetail(String id) async {
    for (final d in _purchases) {
      if (d.purchase.id == id) return d;
    }
    return null;
  }

  @override
  Future<void> receive(
    PurchaseDetail detail, {
    required bool updateCostPrices,
  }) async {
    received = detail;
    receivedUpdateCosts = updateCostPrices;
    _purchases.add(detail);
  }
}
