import 'package:drift/drift.dart';

import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/features/billing/data/credit_note_mapper.dart';
import 'package:billforge/features/billing/data/invoice_mapper.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/inventory/data/inventory_mapper.dart';
import 'package:billforge/features/reports/domain/report_data.dart';
import 'package:billforge/features/reports/domain/report_range.dart';
import 'package:billforge/features/reports/domain/report_repository.dart';

class DriftReportRepository implements ReportRepository {
  DriftReportRepository(this._db);

  final AppDatabase _db;

  @override
  Future<ReportData> load(ReportRange range) async {
    final from = range.from;
    final to = range.toExclusive;
    final statuses = [InvoiceStatus.issued.name, InvoiceStatus.cancelled.name];

    // Joins instead of "id IN (...)" lists: SQLite caps how many variables a
    // single query may use, and a year of invoices would exceed it.
    final inPeriod =
        _db.invoices.status.isIn(statuses) &
        _db.invoices.issuedAt.isBiggerOrEqualValue(from) &
        _db.invoices.issuedAt.isSmallerThanValue(to);

    final invoiceRows =
        await (_db.select(_db.invoices)
              ..where(
                (t) =>
                    t.status.isIn(statuses) &
                    t.issuedAt.isBiggerOrEqualValue(from) &
                    t.issuedAt.isSmallerThanValue(to),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.issuedAt)]))
            .get();

    final itemRows = await (_db.select(_db.invoiceItems).join([
      innerJoin(
        _db.invoices,
        _db.invoices.id.equalsExp(_db.invoiceItems.invoiceId),
      ),
    ])..where(inPeriod)).get();

    final noteRows =
        await (_db.select(_db.creditNotes)..where(
              (t) =>
                  t.issuedAt.isBiggerOrEqualValue(from) &
                  t.issuedAt.isSmallerThanValue(to),
            ))
            .get();

    final noteItemRows =
        await (_db.select(_db.creditNoteItems).join([
              innerJoin(
                _db.creditNotes,
                _db.creditNotes.id.equalsExp(_db.creditNoteItems.creditNoteId),
              ),
            ])..where(
              _db.creditNotes.issuedAt.isBiggerOrEqualValue(from) &
                  _db.creditNotes.issuedAt.isSmallerThanValue(to),
            ))
            .get();

    final paymentRows =
        await (_db.select(_db.invoicePayments)..where(
              (t) =>
                  t.paidAt.isBiggerOrEqualValue(from) &
                  t.paidAt.isSmallerThanValue(to),
            ))
            .get();

    final purchaseRows =
        await (_db.select(_db.purchases)..where(
              (t) =>
                  t.purchasedAt.isBiggerOrEqualValue(from) &
                  t.purchasedAt.isSmallerThanValue(to),
            ))
            .get();

    final costRows = await (_db.select(
      _db.products,
    )..where((t) => t.purchasePricePaise.isNotNull())).get();

    return ReportData(
      invoices: invoiceRows.map(invoiceFromRow).toList(growable: false),
      invoiceItems: itemRows
          .map((r) => itemFromRow(r.readTable(_db.invoiceItems)))
          .toList(growable: false),
      creditNotes: noteRows.map(creditNoteFromRow).toList(growable: false),
      creditNoteItems: noteItemRows
          .map((r) => creditNoteItemFromRow(r.readTable(_db.creditNoteItems)))
          .toList(growable: false),
      payments: paymentRows.map(paymentFromRow).toList(growable: false),
      purchases: purchaseRows.map(purchaseFromRow).toList(growable: false),
      costByProductId: {for (final r in costRows) r.id: r.purchasePricePaise!},
    );
  }
}
