import 'package:drift/drift.dart';

@DataClassName('CustomerRow')
@TableIndex(name: 'customers_name_idx', columns: {#name})
@TableIndex(name: 'customers_phone_idx', columns: {#phone})
@TableIndex(name: 'customers_archived_idx', columns: {#archivedAt})
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get gstin => text().nullable()();
  TextColumn get addressLine1 => text().nullable()();
  TextColumn get addressLine2 => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get state => text().nullable()();
  TextColumn get pincode => text().nullable()();
  IntColumn get creditLimitPaise => integer().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  /// SQLite allows many NULLs in a UNIQUE column, so GSTIN stays optional.
  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {gstin},
  ];
}
