import 'package:drift/drift.dart';

import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/core/database/stock_writer.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/utils/ids.dart';
import 'package:billforge/features/billing/data/credit_note_mapper.dart';
import 'package:billforge/features/billing/data/invoice_mapper.dart';
import 'package:billforge/features/billing/domain/credit_note.dart';
import 'package:billforge/features/billing/domain/credit_note_repository.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/billing/domain/return_calculator.dart';
import 'package:billforge/features/inventory/domain/movement_type.dart';
import 'package:billforge/features/shop/domain/invoice_number.dart';

class DriftCreditNoteRepository implements CreditNoteRepository {
  DriftCreditNoteRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<CreditNote>> watchForInvoice(String invoiceId) {
    final select = _db.select(_db.creditNotes)
      ..where((t) => t.invoiceId.equals(invoiceId))
      ..orderBy([
        (t) => OrderingTerm.desc(t.issuedAt),
        (t) => OrderingTerm(
          expression: const CustomExpression<int>('rowid'),
          mode: OrderingMode.desc,
        ),
      ]);
    return select.watch().map(
      (rows) => rows.map(creditNoteFromRow).toList(growable: false),
    );
  }

  @override
  Future<CreditNoteDetail?> getDetail(String id) async {
    final row = await (_db.select(
      _db.creditNotes,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final items =
        await (_db.select(_db.creditNoteItems)
              ..where((t) => t.creditNoteId.equals(id))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    return CreditNoteDetail(
      creditNote: creditNoteFromRow(row),
      items: items.map(creditNoteItemFromRow).toList(growable: false),
    );
  }

  @override
  Future<List<CreditNoteItem>> returnedItems(String invoiceId) async {
    final rows = await (_db.select(_db.creditNoteItems).join([
      innerJoin(
        _db.creditNotes,
        _db.creditNotes.id.equalsExp(_db.creditNoteItems.creditNoteId),
      ),
    ])..where(_db.creditNotes.invoiceId.equals(invoiceId))).get();
    return rows
        .map((r) => creditNoteItemFromRow(r.readTable(_db.creditNoteItems)))
        .toList(growable: false);
  }

  @override
  Future<CreditNote> issue({
    required String invoiceId,
    required Map<String, int> quantities,
    required ReturnReason reason,
    String? note,
    required bool restock,
    PaymentMethod? refundMethod,
  }) => _create(
    invoiceId: invoiceId,
    quantities: quantities,
    reason: reason,
    note: note,
    restock: restock,
    refundMethod: refundMethod,
    cancel: false,
  );

  @override
  Future<CreditNote> cancelInvoice({
    required String invoiceId,
    String? note,
    required bool restock,
    PaymentMethod? refundMethod,
  }) => _create(
    invoiceId: invoiceId,
    quantities: const {},
    reason: ReturnReason.cancellation,
    note: note,
    restock: restock,
    refundMethod: refundMethod,
    cancel: true,
  );

  Future<CreditNote> _create({
    required String invoiceId,
    required Map<String, int> quantities,
    required ReturnReason reason,
    required String? note,
    required bool restock,
    required PaymentMethod? refundMethod,
    required bool cancel,
  }) {
    return _db.transaction(() async {
      final invoiceRow = await (_db.select(
        _db.invoices,
      )..where((t) => t.id.equals(invoiceId))).getSingleOrNull();
      if (invoiceRow == null) {
        throw const ConflictFailure('That invoice no longer exists.');
      }
      final invoice = invoiceFromRow(invoiceRow);
      if (invoice.isCancelled) {
        throw const ConflictFailure('This invoice is already cancelled.');
      }
      if (invoice.status != InvoiceStatus.issued) {
        throw const ConflictFailure('Only issued invoices can have returns.');
      }
      if (cancel && invoice.creditedPaise > 0) {
        throw const ConflictFailure(
          'Items were already returned on this invoice. Return the remaining items instead.',
        );
      }

      final itemRows =
          await (_db.select(_db.invoiceItems)
                ..where((t) => t.invoiceId.equals(invoiceId))
                ..orderBy([(t) => OrderingTerm.asc(t.position)]))
              .get();
      final lines = returnableLines(
        itemRows.map(itemFromRow).toList(),
        await returnedItems(invoiceId),
      );

      final outcome = planReturn(
        invoice: invoice,
        lines: lines,
        qtyByItemId: cancel ? selectAllRemaining(lines) : quantities,
      );
      final plan = outcome.plan;
      if (plan == null) {
        throw ConflictFailure(outcome.error ?? 'Nothing to return.');
      }

      final settlement = settleCreditNote(
        totalPaise: plan.totalPaise,
        invoiceDuePaise: invoice.duePaise,
      );
      final method = settlement.refundPaise > 0
          ? (refundMethod ?? PaymentMethod.cash)
          : null;

      // Credit notes are never deleted, so count + 1 is gapless.
      final countExpr = _db.creditNotes.id.count();
      final countRow = await (_db.selectOnly(
        _db.creditNotes,
      )..addColumns([countExpr])).getSingle();
      var sequence = (countRow.read(countExpr) ?? 0) + 1;
      var number = formatInvoiceNumber('CN', sequence);
      while (await _numberTaken(number)) {
        sequence++;
        number = formatInvoiceNumber('CN', sequence);
      }

      final now = DateTime.now();
      final id = newId('cn');
      final trimmed = note?.trim();
      final creditNote = CreditNote(
        id: id,
        creditNoteNumber: number,
        invoiceId: invoice.id,
        invoiceNumber: invoice.invoiceNumber ?? '',
        customerId: invoice.customerId,
        customerName: invoice.customerName,
        customerPhone: invoice.customerPhone,
        customerGstin: invoice.customerGstin,
        placeOfSupply: invoice.placeOfSupply,
        isInterState: invoice.isInterState,
        reason: reason,
        note: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
        isCancellation: cancel,
        restocked: restock,
        taxablePaise: plan.taxablePaise,
        cgstPaise: plan.cgstPaise,
        sgstPaise: plan.sgstPaise,
        igstPaise: plan.igstPaise,
        roundOffPaise: plan.roundOffPaise,
        totalPaise: plan.totalPaise,
        appliedPaise: settlement.appliedPaise,
        refundPaise: settlement.refundPaise,
        refundMethod: method,
        issuedAt: now,
      );
      await _db.into(_db.creditNotes).insert(creditNoteToCompanion(creditNote));

      for (var i = 0; i < plan.lines.length; i++) {
        final l = plan.lines[i];
        await _db
            .into(_db.creditNoteItems)
            .insert(
              creditNoteItemToCompanion(
                CreditNoteItem(
                  id: '$id-${i + 1}',
                  creditNoteId: id,
                  invoiceItemId: l.line.item.id,
                  position: i,
                  productId: l.line.item.productId,
                  name: l.line.item.name,
                  hsnCode: l.line.item.hsnCode,
                  unit: l.line.item.unit,
                  qtyMilli: l.qtyMilli,
                  unitPricePaise: l.line.item.unitPricePaise,
                  gstRatePercent: l.line.item.gstRatePercent,
                  taxablePaise: l.taxablePaise,
                  cgstPaise: l.cgstPaise,
                  sgstPaise: l.sgstPaise,
                  igstPaise: l.igstPaise,
                  totalPaise: l.totalPaise,
                ),
              ),
            );
      }

      await (_db.update(
        _db.invoices,
      )..where((t) => t.id.equals(invoiceId))).write(
        InvoicesCompanion(
          creditedPaise: Value(invoice.creditedPaise + plan.totalPaise),
          paidPaise: Value(invoice.paidPaise - settlement.refundPaise),
          status: cancel
              ? Value(InvoiceStatus.cancelled.name)
              : const Value.absent(),
          updatedAt: Value(now),
        ),
      );

      if (restock) {
        for (final l in plan.lines) {
          final productId = l.line.item.productId;
          if (productId == null) continue;
          await applyStockMovement(
            _db,
            productId: productId,
            type: MovementType.customerReturn,
            deltaMilli: l.qtyMilli,
            refType: StockRef.creditNote,
            refId: id,
            note: number,
            at: now,
          );
        }
      }
      return creditNote;
    });
  }

  Future<bool> _numberTaken(String number) async {
    final row =
        await (_db.select(_db.creditNotes)
              ..where((t) => t.creditNoteNumber.equals(number))
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }
}
