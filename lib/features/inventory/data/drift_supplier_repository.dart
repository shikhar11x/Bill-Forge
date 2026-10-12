import 'package:drift/drift.dart';

import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/features/inventory/data/inventory_mapper.dart';
import 'package:billforge/features/inventory/domain/inventory_queries.dart';
import 'package:billforge/features/inventory/domain/supplier.dart';
import 'package:billforge/features/inventory/domain/supplier_repository.dart';

class DriftSupplierRepository implements SupplierRepository {
  DriftSupplierRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Supplier>> watchSuppliers(SupplierQuery query) {
    final select = _db.select(_db.suppliers)
      ..where((t) => _filter(t, query))
      ..orderBy([(t) => OrderingTerm.asc(t.name.collate(Collate.noCase))])
      ..limit(kSupplierLimit);
    return select
        .watch()
        .map((rows) => rows.map(supplierFromRow).toList(growable: false));
  }

  Expression<bool> _filter($SuppliersTable t, SupplierQuery q) {
    Expression<bool> e =
        q.showArchived ? t.archivedAt.isNotNull() : t.archivedAt.isNull();
    final text = q.search.trim().toLowerCase();
    if (text.isNotEmpty) {
      e = e &
          (t.name.lower().contains(text) |
              t.phone.lower().contains(text) |
              t.gstin.lower().contains(text) |
              t.city.lower().contains(text));
    }
    return e;
  }

  @override
  Future<Supplier?> getById(String id) async {
    final row = await (_db.select(_db.suppliers)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : supplierFromRow(row);
  }

  @override
  Future<void> save(Supplier supplier) async {
    final gstin = supplier.gstin;
    if (gstin != null) {
      final clash = await (_db.select(_db.suppliers)
            ..where(
              (t) => t.gstin.equals(gstin) & t.id.equals(supplier.id).not(),
            )
            ..limit(1))
          .getSingleOrNull();
      if (clash != null) {
        throw const ConflictFailure(
          'Another supplier (possibly archived) already uses this GSTIN.',
        );
      }
    }
    await _db.into(_db.suppliers).insertOnConflictUpdate(
          supplierToCompanion(supplier),
        );
  }

  @override
  Future<void> setArchived(String id, {required bool archived}) async {
    final now = DateTime.now();
    await (_db.update(_db.suppliers)..where((t) => t.id.equals(id))).write(
      SuppliersCompanion(
        archivedAt: Value(archived ? now : null),
        updatedAt: Value(now),
      ),
    );
  }
}