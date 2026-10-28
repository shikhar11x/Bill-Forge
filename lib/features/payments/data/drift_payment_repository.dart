import 'package:drift/drift.dart';

import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/utils/ids.dart';
import 'package:billforge/features/billing/data/credit_note_mapper.dart';
import 'package:billforge/features/billing/data/invoice_mapper.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/payments/data/payment_mapper.dart';
import 'package:billforge/features/payments/domain/customer_ledger.dart';
import 'package:billforge/features/payments/domain/customer_payment.dart';
import 'package:billforge/features/payments/domain/payment_allocation.dart';
import 'package:billforge/features/payments/domain/payment_repository.dart';

class DriftPaymentRepository implements PaymentRepository {
  DriftPaymentRepository(this._db);

  final AppDatabase _db;

  /// Issued, belongs to a customer, and not fully paid after credits.
  Expression<bool> _open($InvoicesTable t) =>
      t.status.equals(InvoiceStatus.issued.name) &
      t.customerId.isNotNull() &
      (t.grandTotalPaise - t.creditedPaise).isBiggerThan(t.paidPaise);

  @override
  Stream<List<Invoice>> watchOpenInvoices() {
    final select = _db.select(_db.invoices)
      ..where(_open)
      ..orderBy([(t) => OrderingTerm.asc(t.issuedAt)]);
    return select.watch().map(
      (rows) => rows.map(invoiceFromRow).toList(growable: false),
    );
  }

  @override
  Stream<List<Invoice>> watchOpenInvoicesFor(String customerId) {
    final select = _db.select(_db.invoices)
      ..where((t) => _open(t) & t.customerId.equals(customerId))
      ..orderBy([(t) => OrderingTerm.asc(t.issuedAt)]);
    return select.watch().map(
      (rows) => rows.map(invoiceFromRow).toList(growable: false),
    );
  }

  @override
  Stream<List<CustomerPayment>> watchReceipts(
    String customerId, {
    required int limit,
  }) {
    final select = _db.select(_db.customerPayments)
      ..where((t) => t.customerId.equals(customerId))
      ..orderBy([
        (t) => OrderingTerm.desc(t.receivedAt),
        (t) => OrderingTerm(
          expression: const CustomExpression<int>('rowid'),
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(limit);
    return select.watch().map(
      (rows) => rows.map(receiptFromRow).toList(growable: false),
    );
  }

  @override
  Future<CustomerLedger> loadLedger(String customerId) async {
    // Cancelled invoices stay in the ledger so their credit notes balance.
    final statuses = [InvoiceStatus.issued.name, InvoiceStatus.cancelled.name];

    final invoiceRows =
        await (_db.select(_db.invoices)..where(
              (t) => t.customerId.equals(customerId) & t.status.isIn(statuses),
            ))
            .get();

    final paymentRows =
        await (_db.select(_db.invoicePayments).join([
              innerJoin(
                _db.invoices,
                _db.invoices.id.equalsExp(_db.invoicePayments.invoiceId),
              ),
            ])..where(
              _db.invoices.customerId.equals(customerId) &
                  _db.invoices.status.isIn(statuses),
            ))
            .get();

    final receiptRows = await (_db.select(
      _db.customerPayments,
    )..where((t) => t.customerId.equals(customerId))).get();

    final creditRows = await (_db.select(
      _db.creditNotes,
    )..where((t) => t.customerId.equals(customerId))).get();

    return CustomerLedger(
      invoices: invoiceRows.map(invoiceFromRow).toList(growable: false),
      payments: paymentRows
          .map((r) => paymentFromRow(r.readTable(_db.invoicePayments)))
          .toList(growable: false),
      receipts: receiptRows.map(receiptFromRow).toList(growable: false),
      creditNotes: creditRows.map(creditNoteFromRow).toList(growable: false),
    );
  }

  @override
  Future<CustomerPayment> collect({
    required String customerId,
    required int amountPaise,
    required PaymentMethod method,
    String? note,
    String? invoiceId,
  }) {
    return _db.transaction(() async {
      if (amountPaise <= 0) {
        throw const ConflictFailure('Enter an amount greater than zero.');
      }

      final rows =
          await (_db.select(_db.invoices)
                ..where((t) => _open(t) & t.customerId.equals(customerId))
                ..orderBy([(t) => OrderingTerm.asc(t.issuedAt)]))
              .get();
      var open = rows.map(invoiceFromRow).toList();
      if (invoiceId != null) {
        open = open.where((i) => i.id == invoiceId).toList();
        if (open.isEmpty) {
          throw const ConflictFailure('That invoice has no balance due.');
        }
      }
      if (open.isEmpty) {
        throw const ConflictFailure('This customer has nothing due.');
      }

      final due = open.fold<int>(0, (sum, i) => sum + i.duePaise);
      if (amountPaise > due) {
        throw ConflictFailure(
          'The amount is more than the ${formatPaise(due)} due.',
        );
      }

      final allocations = allocatePayment(amountPaise, open);
      final now = DateTime.now();
      final trimmedNote = note?.trim();
      final receipt = CustomerPayment(
        id: newId('rcp'),
        customerId: customerId,
        method: method,
        amountPaise: amountPaise,
        note: (trimmedNote == null || trimmedNote.isEmpty) ? null : trimmedNote,
        receivedAt: now,
        createdAt: now,
      );
      await _db.into(_db.customerPayments).insert(receiptToCompanion(receipt));

      for (final a in allocations) {
        final row = rows.firstWhere((r) => r.id == a.invoiceId);
        await _db
            .into(_db.invoicePayments)
            .insert(
              InvoicePaymentsCompanion.insert(
                id: newId('pay'),
                invoiceId: a.invoiceId,
                method: method.name,
                amountPaise: a.amountPaise,
                paidAt: now,
                receiptId: Value(receipt.id),
              ),
            );
        await (_db.update(
          _db.invoices,
        )..where((t) => t.id.equals(a.invoiceId))).write(
          InvoicesCompanion(
            paidPaise: Value(row.paidPaise + a.amountPaise),
            updatedAt: Value(now),
          ),
        );
      }
      return receipt;
    });
  }
}
