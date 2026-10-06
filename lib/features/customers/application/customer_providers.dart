import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/core/database/database_providers.dart';
import 'package:billforge/features/customers/data/drift_customer_repository.dart';
import 'package:billforge/features/customers/domain/customer.dart';
import 'package:billforge/features/customers/domain/customer_query.dart';
import 'package:billforge/features/customers/domain/customer_repository.dart';

final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) => DriftCustomerRepository(ref.watch(appDatabaseProvider)),
);

class CustomerQueryNotifier extends Notifier<CustomerQuery> {
  @override
  CustomerQuery build() => const CustomerQuery();

  void setSearch(String value) =>
      state = state.copyWith(search: value, limit: kCustomerPageSize);

  void setShowArchived(bool value) =>
      state = state.copyWith(showArchived: value, limit: kCustomerPageSize);

  /// Called by the UI when the user scrolls near the end of the list.
  void loadMore() =>
      state = state.copyWith(limit: state.limit + kCustomerPageSize);

  void reset() => state = const CustomerQuery();
}

final customerQueryProvider =
    NotifierProvider<CustomerQueryNotifier, CustomerQuery>(
      CustomerQueryNotifier.new,
    );

/// Live list for the current query.
final customersProvider = StreamProvider<List<Customer>>((ref) {
  final query = ref.watch(customerQueryProvider);
  return ref.watch(customerRepositoryProvider).watchCustomers(query);
});

final customerByIdProvider = FutureProvider.autoDispose
    .family<Customer?, String>(
      (ref, id) => ref.watch(customerRepositoryProvider).getById(id),
    );
