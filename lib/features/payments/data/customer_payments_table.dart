import 'package:drift/drift.dart';

import 'package:billforge/features/customers/data/customers_table.dart';

@DataClassName('CustomerPaymentRow')
@TableIndex(
  name: 'customer_payments_customer_idx',
  columns: {#customerId, #receivedAt},
)
class CustomerPayments extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text().references(Customers, #id)();
  TextColumn get method => text()();
  IntColumn get amountPaise => integer()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get receivedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}