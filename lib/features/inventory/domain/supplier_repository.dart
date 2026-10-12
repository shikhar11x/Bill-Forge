import 'package:billforge/features/inventory/domain/inventory_queries.dart';
import 'package:billforge/features/inventory/domain/supplier.dart';

abstract interface class SupplierRepository {
  Stream<List<Supplier>> watchSuppliers(SupplierQuery query);

  Future<Supplier?> getById(String id);

  /// Upsert by id. Throws `ConflictFailure` on a duplicate GSTIN.
  Future<void> save(Supplier supplier);

  Future<void> setArchived(String id, {required bool archived});
}