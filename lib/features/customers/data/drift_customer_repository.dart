import 'package:drift/drift.dart';

import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/features/customers/data/customer_mapper.dart';
import 'package:billforge/features/customers/domain/customer.dart';
import 'package:billforge/features/customers/domain/customer_query.dart';
import 'package:billforge/features/customers/domain/customer_repository.dart';

class DriftCustomerRepository implements CustomerRepository {
  DriftCustomerRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Customer>> watchCustomers(CustomerQuery query) {
    final select = _db.select(_db.customers)
      ..where((t) => _filter(t, query))
      ..orderBy([(t) => OrderingTerm.asc(t.name.collate(Collate.noCase))])
      ..limit(query.limit);
    return select.watch().map(
      (rows) => rows.map(customerFromRow).toList(growable: false),
    );
  }

  Expression<bool> _filter($CustomersTable t, CustomerQuery q) {
    Expression<bool> e = q.showArchived
        ? t.archivedAt.isNotNull()
        : t.archivedAt.isNull();

    final text = q.search.trim().toLowerCase();
    if (text.isNotEmpty) {
      e =
          e &
          (t.name.lower().contains(text) |
              t.phone.lower().contains(text) |
              t.gstin.lower().contains(text));
    }
    return e;
  }

  @override
  Future<Customer?> getById(String id) async {
    final row = await (_db.select(
      _db.customers,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : customerFromRow(row);
  }

  @override
  Future<void> save(Customer customer) async {
    final gstin = customer.gstin;
    if (gstin != null) {
      final clash =
          await (_db.select(_db.customers)
                ..where(
                  (t) => t.gstin.equals(gstin) & t.id.equals(customer.id).not(),
                )
                ..limit(1))
              .getSingleOrNull();
      if (clash != null) {
        throw const ConflictFailure(
          'Another customer (possibly archived) already uses this GSTIN.',
        );
      }
    }
    await _db
        .into(_db.customers)
        .insertOnConflictUpdate(customerToCompanion(customer));
  }

  @override
  Future<void> setArchived(String id, {required bool archived}) async {
    final now = DateTime.now();
    await (_db.update(_db.customers)..where((t) => t.id.equals(id))).write(
      CustomersCompanion(
        archivedAt: Value(archived ? now : null),
        updatedAt: Value(now),
      ),
    );
  }
}
