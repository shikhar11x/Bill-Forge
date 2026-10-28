import 'package:drift/drift.dart';

import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/core/database/stock_writer.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/utils/ids.dart';
import 'package:billforge/features/billing/data/invoice_mapper.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/invoice_query.dart';
import 'package:billforge/features/billing/domain/invoice_repository.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/inventory/domain/movement_type.dart';
import 'package:billforge/features/payments/domain/credit_check.dart';
import 'package:billforge/features/shop/domain/invoice_number.dart';

class DriftInvoiceRepository implements InvoiceRepository {
  DriftInvoiceRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Invoice>> watchInvoices(InvoiceQuery query) {
    final select = _db.select(_db.invoices)
      ..where((t) => _filter(t, query))
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
      ..limit(query.limit);
    return select.watch().map(
      (rows) => rows.map(invoiceFromRow).toList(growable: false),
    );
  }

  Expression<bool> _filter($InvoicesTable t, InvoiceQuery q) {
    Expression<bool> e = const Constant(true);
    switch (q.status) {
      case InvoiceStatusFilter.all:
        break;
      case InvoiceStatusFilter.drafts:
        e = e & t.status.equals(InvoiceStatus.draft.name);
      case InvoiceStatusFilter.issued:
        e = e & t.status.equals(InvoiceStatus.issued.name);
      case InvoiceStatusFilter.cancelled:
        e = e & t.status.equals(InvoiceStatus.cancelled.name);
    }
    final text = q.search.trim().toLowerCase();
    if (text.isNotEmpty) {
      e =
          e &
          (t.invoiceNumber.lower().contains(text) |
              t.customerName.lower().contains(text));
    }
    return e;
  }

  @override
  Future<InvoiceDetail?> getDetail(String id) async {
    final row = await (_db.select(
      _db.invoices,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;

    final items =
        await (_db.select(_db.invoiceItems)
              ..where((t) => t.invoiceId.equals(id))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    final payments =
        await (_db.select(_db.invoicePayments)
              ..where((t) => t.invoiceId.equals(id))
              ..orderBy([(t) => OrderingTerm.asc(t.paidAt)]))
            .get();

    return InvoiceDetail(
      invoice: invoiceFromRow(row),
      items: items.map(itemFromRow).toList(growable: false),
      payments: payments.map(paymentFromRow).toList(growable: false),
    );
  }

  @override
  Future<void> saveDraft(InvoiceDetail draft) {
    return _db.transaction(() async {
      await _ensureNotIssued(draft.invoice.id);
      await _writeInvoice(draft.invoice, draft.items);
    });
  }

  @override
  Future<void> deleteDraft(String id) async {
    await (_db.delete(
      _db.invoices,
    )..where((t) => t.id.equals(id) & t.status.equals('draft'))).go();
  }

  @override
  Future<Invoice> issue(
    InvoiceDetail draft,
    List<PaymentEntry> payments, {
    DateTime? dueDate,
  }) {
    return _db.transaction(() async {
      final base = draft.invoice;
      await _ensureNotIssued(base.id);

      if (draft.items.isEmpty) {
        throw const ConflictFailure(
          'Add at least one item before issuing the bill.',
        );
      }
      final problem = validatePayments(
        totalPaise: base.grandTotalPaise,
        entries: payments,
        hasCustomer: base.customerId != null,
      );
      if (problem != null) throw ConflictFailure(problem);

      final paid = payments.fold<int>(0, (sum, p) => sum + p.amountPaise);
      final due = base.grandTotalPaise - paid;
      await _enforceCreditLimit(base.customerId, due);

      final shop = await (_db.select(
        _db.shopProfiles,
      )..limit(1)).getSingleOrNull();
      if (shop == null) {
        throw const ConflictFailure(
          'Set up your shop before issuing invoices.',
        );
      }

      // Gapless numbering; skip forward if the counter was moved onto a
      // number that is already used.
      var next = shop.nextInvoiceNumber;
      var number = formatInvoiceNumber(shop.invoicePrefix, next);
      while (await _numberTaken(number)) {
        next++;
        number = formatInvoiceNumber(shop.invoicePrefix, next);
      }

      final now = DateTime.now();
      await (_db.update(
        _db.shopProfiles,
      )..where((t) => t.id.equals(shop.id))).write(
        ShopProfilesCompanion(
          nextInvoiceNumber: Value(next + 1),
          updatedAt: Value(now),
        ),
      );

      for (final item in draft.items) {
        final productId = item.productId;
        if (productId == null) continue;
        await applyStockMovement(
          _db,
          productId: productId,
          type: MovementType.sale,
          deltaMilli: -item.qtyMilli,
          refType: StockRef.invoice,
          refId: base.id,
          note: number,
          at: now,
        );
      }

      final issued = base.copyWith(
        invoiceNumber: number,
        status: InvoiceStatus.issued,
        paidPaise: paid,
        dueDate: due > 0 ? dueDate : null,
        issuedAt: now,
        updatedAt: now,
      );
      await _writeInvoice(issued, draft.items);

      await (_db.delete(
        _db.invoicePayments,
      )..where((t) => t.invoiceId.equals(base.id))).go();
      for (final p in payments) {
        await _db
            .into(_db.invoicePayments)
            .insert(
              InvoicePaymentsCompanion.insert(
                id: newId('pay'),
                invoiceId: base.id,
                method: p.method.name,
                amountPaise: p.amountPaise,
                paidAt: now,
              ),
            );
      }
      return issued;
    });
  }

  /// A bill that adds credit may not take the customer over their limit.
  Future<void> _enforceCreditLimit(String? customerId, int duePaise) async {
    if (customerId == null || duePaise <= 0) return;

    final customer = await (_db.select(
      _db.customers,
    )..where((t) => t.id.equals(customerId))).getSingleOrNull();
    final limit = customer?.creditLimitPaise;
    if (limit == null) return;

    final openRows =
        await (_db.select(_db.invoices)..where(
              (t) =>
                  t.customerId.equals(customerId) &
                  t.status.equals(InvoiceStatus.issued.name) &
                  (t.grandTotalPaise - t.creditedPaise).isBiggerThan(
                    t.paidPaise,
                  ),
            ))
            .get();
    final outstanding = openRows.fold<int>(
      0,
      (sum, r) => sum + r.grandTotalPaise - r.creditedPaise - r.paidPaise,
    );

    final check = checkCredit(
      limitPaise: limit,
      outstandingPaise: outstanding,
      newDuePaise: duePaise,
    );
    if (!check.allowed) throw ConflictFailure(creditLimitMessage(check));
  }

  Future<void> _ensureNotIssued(String id) async {
    final row = await (_db.select(
      _db.invoices,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row != null && row.status == InvoiceStatus.issued.name) {
      throw const ConflictFailure('This invoice has already been issued.');
    }
  }

  Future<bool> _numberTaken(String number) async {
    final row =
        await (_db.select(_db.invoices)
              ..where((t) => t.invoiceNumber.equals(number))
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  Future<void> _writeInvoice(Invoice invoice, List<InvoiceItem> items) async {
    await _db
        .into(_db.invoices)
        .insertOnConflictUpdate(invoiceToCompanion(invoice));
    await (_db.delete(
      _db.invoiceItems,
    )..where((t) => t.invoiceId.equals(invoice.id))).go();
    for (final item in items) {
      await _db.into(_db.invoiceItems).insert(itemToCompanion(item));
    }
  }
}
