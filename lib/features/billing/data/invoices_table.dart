import 'package:drift/drift.dart';

import 'package:billforge/features/customers/data/customers_table.dart';
import 'package:billforge/features/products/data/products_table.dart';

@DataClassName('InvoiceRow')
@TableIndex(name: 'invoices_status_idx', columns: {#status})
@TableIndex(name: 'invoices_updated_idx', columns: {#updatedAt})
@TableIndex(name: 'invoices_customer_idx', columns: {#customerId})
class Invoices extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceNumber => text().nullable()();
  TextColumn get status => text()();
  TextColumn get customerId => text().nullable().references(Customers, #id)();
  TextColumn get customerName => text().nullable()();
  TextColumn get customerPhone => text().nullable()();
  TextColumn get customerGstin => text().nullable()();
  TextColumn get placeOfSupply => text()();
  BoolColumn get isInterState => boolean()();
  BoolColumn get pricesIncludeTax => boolean()();
  TextColumn get billDiscountType => text()();
  IntColumn get billDiscountValue => integer()();
  IntColumn get discountPaise => integer()();
  IntColumn get taxablePaise => integer()();
  IntColumn get cgstPaise => integer()();
  IntColumn get sgstPaise => integer()();
  IntColumn get igstPaise => integer()();
  IntColumn get roundOffPaise => integer()();
  IntColumn get grandTotalPaise => integer()();
  IntColumn get paidPaise => integer().withDefault(const Constant(0))();
  DateTimeColumn get issuedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  /// Drafts have no number (NULL), so many drafts can coexist.
  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {invoiceNumber},
  ];
}

@DataClassName('InvoiceItemRow')
@TableIndex(name: 'invoice_items_invoice_idx', columns: {#invoiceId})
class InvoiceItems extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceId =>
      text().references(Invoices, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get productId => text().nullable().references(Products, #id)();
  TextColumn get name => text()();
  TextColumn get hsnCode => text().nullable()();
  TextColumn get unit => text()();
  IntColumn get qtyMilli => integer()();
  IntColumn get unitPricePaise => integer()();
  TextColumn get discountType => text()();
  IntColumn get discountValue => integer()();
  IntColumn get gstRatePercent => integer()();
  IntColumn get discountPaise => integer()();
  IntColumn get taxablePaise => integer()();
  IntColumn get cgstPaise => integer()();
  IntColumn get sgstPaise => integer()();
  IntColumn get igstPaise => integer()();
  IntColumn get totalPaise => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('InvoicePaymentRow')
@TableIndex(name: 'invoice_payments_invoice_idx', columns: {#invoiceId})
class InvoicePayments extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceId =>
      text().references(Invoices, #id, onDelete: KeyAction.cascade)();
  TextColumn get method => text()();
  IntColumn get amountPaise => integer()();
  DateTimeColumn get paidAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
