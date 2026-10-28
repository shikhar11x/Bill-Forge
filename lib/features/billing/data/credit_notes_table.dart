import 'package:drift/drift.dart';

import 'package:billforge/features/billing/data/invoices_table.dart';
import 'package:billforge/features/customers/data/customers_table.dart';
import 'package:billforge/features/products/data/products_table.dart';

@DataClassName('CreditNoteRow')
@TableIndex(name: 'credit_notes_invoice_idx', columns: {#invoiceId})
@TableIndex(
  name: 'credit_notes_customer_idx',
  columns: {#customerId, #issuedAt},
)
class CreditNotes extends Table {
  TextColumn get id => text()();
  TextColumn get creditNoteNumber => text()();
  TextColumn get invoiceId => text().references(Invoices, #id)();
  TextColumn get invoiceNumber => text()();
  TextColumn get customerId => text().nullable().references(Customers, #id)();
  TextColumn get customerName => text().nullable()();
  TextColumn get customerPhone => text().nullable()();
  TextColumn get customerGstin => text().nullable()();
  TextColumn get placeOfSupply => text()();
  BoolColumn get isInterState => boolean()();
  TextColumn get reason => text()();
  TextColumn get note => text().nullable()();
  BoolColumn get isCancellation => boolean()();
  BoolColumn get restocked => boolean()();
  IntColumn get taxablePaise => integer()();
  IntColumn get cgstPaise => integer()();
  IntColumn get sgstPaise => integer()();
  IntColumn get igstPaise => integer()();
  IntColumn get roundOffPaise => integer()();
  IntColumn get totalPaise => integer()();
  IntColumn get appliedPaise => integer()();
  IntColumn get refundPaise => integer()();
  TextColumn get refundMethod => text().nullable()();
  DateTimeColumn get issuedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {creditNoteNumber},
  ];
}

@DataClassName('CreditNoteItemRow')
@TableIndex(name: 'credit_note_items_note_idx', columns: {#creditNoteId})
@TableIndex(name: 'credit_note_items_item_idx', columns: {#invoiceItemId})
class CreditNoteItems extends Table {
  TextColumn get id => text()();
  TextColumn get creditNoteId =>
      text().references(CreditNotes, #id, onDelete: KeyAction.cascade)();
  TextColumn get invoiceItemId => text().references(InvoiceItems, #id)();
  IntColumn get position => integer()();
  TextColumn get productId => text().nullable().references(Products, #id)();
  TextColumn get name => text()();
  TextColumn get hsnCode => text().nullable()();
  TextColumn get unit => text()();
  IntColumn get qtyMilli => integer()();
  IntColumn get unitPricePaise => integer()();
  IntColumn get gstRatePercent => integer()();
  IntColumn get taxablePaise => integer()();
  IntColumn get cgstPaise => integer()();
  IntColumn get sgstPaise => integer()();
  IntColumn get igstPaise => integer()();
  IntColumn get totalPaise => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
