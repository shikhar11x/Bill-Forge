import 'package:billforge/features/inventory/domain/inventory_queries.dart';
import 'package:billforge/features/inventory/domain/purchase.dart';

abstract interface class PurchaseRepository {
  /// Newest first. Headers only.
  Stream<List<Purchase>> watchPurchases(PurchaseQuery query);

  Future<PurchaseDetail?> getDetail(String id);

  /// Atomically stores the purchase and adds every line to stock. Throws
  /// `ConflictFailure` for an empty purchase, a non-positive quantity, or a
  /// product that is missing or not tracking stock.
  Future<void> receive(PurchaseDetail detail, {required bool updateCostPrices});
}
