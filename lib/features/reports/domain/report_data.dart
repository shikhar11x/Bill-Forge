import 'package:billforge/features/billing/domain/credit_note.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/inventory/domain/purchase.dart';
import 'package:billforge/features/reports/domain/report_range.dart';

DateTime invoiceMoment(Invoice invoice) =>
    invoice.issuedAt ?? invoice.createdAt;

/// The raw facts for a period. Every report is a pure function of this.
class ReportData {
  const ReportData({
    this.invoices = const [],
    this.invoiceItems = const [],
    this.creditNotes = const [],
    this.creditNoteItems = const [],
    this.payments = const [],
    this.purchases = const [],
    this.costByProductId = const {},
  });

  /// Issued and cancelled invoices dated in the period.
  final List<Invoice> invoices;
  final List<InvoiceItem> invoiceItems;

  /// Credit notes dated in the period (returns, refunds, cancellations).
  final List<CreditNote> creditNotes;
  final List<CreditNoteItem> creditNoteItems;

  /// Payment rows dated in the period: money taken at sale and later
  /// collections spread over invoices.
  final List<InvoicePayment> payments;
  final List<Purchase> purchases;

  /// Current purchase price in paise, for products that have one.
  final Map<String, int> costByProductId;

  /// The part of this data that falls inside [range].
  ReportData slice(ReportRange range) {
    final invs = invoices
        .where((i) => range.contains(invoiceMoment(i)))
        .toList();
    final invoiceIds = {for (final i in invs) i.id};
    final notes = creditNotes.where((n) => range.contains(n.issuedAt)).toList();
    final noteIds = {for (final n in notes) n.id};

    return ReportData(
      invoices: invs,
      invoiceItems: invoiceItems
          .where((i) => invoiceIds.contains(i.invoiceId))
          .toList(),
      creditNotes: notes,
      creditNoteItems: creditNoteItems
          .where((i) => noteIds.contains(i.creditNoteId))
          .toList(),
      payments: payments.where((p) => range.contains(p.paidAt)).toList(),
      purchases: purchases.where((p) => range.contains(p.purchasedAt)).toList(),
      costByProductId: costByProductId,
    );
  }
}
