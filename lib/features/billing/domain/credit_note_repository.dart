import 'package:billforge/features/billing/domain/credit_note.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';

abstract interface class CreditNoteRepository {
  /// Newest first.
  Stream<List<CreditNote>> watchForInvoice(String invoiceId);

  Future<CreditNoteDetail?> getDetail(String id);

  /// Lines already credited on the invoice, across all its credit notes.
  Future<List<CreditNoteItem>> returnedItems(String invoiceId);

  /// Atomically issues a credit note for [quantities] (invoice item id to
  /// thousandths), settles it, and returns stock when [restock] is true.
  /// Throws `ConflictFailure` for invalid selections or invoices.
  Future<CreditNote> issue({
    required String invoiceId,
    required Map<String, int> quantities,
    required ReturnReason reason,
    String? note,
    required bool restock,
    PaymentMethod? refundMethod,
  });

  /// Returns everything on an invoice with nothing returned yet and marks the
  /// invoice cancelled.
  Future<CreditNote> cancelInvoice({
    required String invoiceId,
    String? note,
    required bool restock,
    PaymentMethod? refundMethod,
  });
}
