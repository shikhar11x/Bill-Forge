import 'package:billforge/features/customers/domain/customer.dart';
import 'package:billforge/features/customers/domain/customer_query.dart';
import 'package:billforge/features/customers/domain/customer_repository.dart';

Customer sampleCustomer({
  String id = 'c1',
  String name = 'Rahul Sharma',
  String? phone = '9876543210',
  String? gstin,
  int? creditLimitPaise,
  DateTime? archivedAt,
}) => Customer(
  id: id,
  name: name,
  phone: phone,
  gstin: gstin,
  city: 'Gurugram',
  state: 'Haryana',
  creditLimitPaise: creditLimitPaise,
  archivedAt: archivedAt,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

class FakeCustomerRepository implements CustomerRepository {
  FakeCustomerRepository([List<Customer> customers = const []])
    : _customers = List.of(customers);

  final List<Customer> _customers;
  Customer? saved;

  @override
  Stream<List<Customer>> watchCustomers(CustomerQuery query) {
    final search = query.search.trim().toLowerCase();
    final result = _customers
        .where((c) => c.isArchived == query.showArchived)
        .where(
          (c) =>
              search.isEmpty ||
              c.name.toLowerCase().contains(search) ||
              (c.phone ?? '').contains(search),
        )
        .take(query.limit)
        .toList();
    return Stream.value(result);
  }

  @override
  Future<Customer?> getById(String id) async {
    for (final c in _customers) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Future<void> save(Customer customer) async {
    saved = customer;
    _customers
      ..removeWhere((c) => c.id == customer.id)
      ..add(customer);
  }

  @override
  Future<void> setArchived(String id, {required bool archived}) async {
    final index = _customers.indexWhere((c) => c.id == id);
    if (index < 0) return;
    _customers[index] = _customers[index].copyWith(
      archivedAt: archived ? DateTime(2026, 6, 1) : null,
    );
  }
}
