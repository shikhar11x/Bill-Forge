import 'package:billforge/features/customers/domain/customer.dart';
import 'package:billforge/features/customers/domain/customer_query.dart';

abstract interface class CustomerRepository {
  Stream<List<Customer>> watchCustomers(CustomerQuery query);

  Future<Customer?> getById(String id);

  /// Upsert by id. Throws `ConflictFailure` on a duplicate GSTIN.
  Future<void> save(Customer customer);

  Future<void> setArchived(String id, {required bool archived});
}
