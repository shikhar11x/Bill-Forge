import 'package:drift/drift.dart';

@DataClassName('ShopProfileRow')
class ShopProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get businessType => text()();
  TextColumn get phone => text()();
  TextColumn get email => text().nullable()();
  TextColumn get addressLine1 => text()();
  TextColumn get addressLine2 => text().nullable()();
  TextColumn get city => text()();
  TextColumn get state => text()();
  TextColumn get pincode => text()();
  TextColumn get gstRegistration => text()();
  TextColumn get gstin => text().nullable()();
  IntColumn get defaultGstRate => integer().withDefault(const Constant(18))();
  BoolColumn get pricesIncludeTax =>
      boolean().withDefault(const Constant(true))();
  TextColumn get currencyCode => text().withDefault(const Constant('INR'))();
  TextColumn get invoicePrefix => text()();
  IntColumn get nextInvoiceNumber => integer()();
  TextColumn get invoiceFooter => text().nullable()();
  TextColumn get paymentInstructions => text().nullable()();
  BlobColumn get logo => blob().nullable()();
  IntColumn get primaryColor => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
