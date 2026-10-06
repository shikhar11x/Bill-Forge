import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/invoice_query.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';

abstract interface class InvoiceRepository {
  /// Newest first. Headers only (no items).
  Stream<List<Invoice>> watchInvoices(InvoiceQuery query);

  Future<InvoiceDetail?> getDetail(String id);

  /// Creates or replaces a draft. Throws `ConflictFailure` if already issued.
  Future<void> saveDraft(InvoiceDetail draft);

  Future<void> deleteDraft(String id);

  /// Atomically: assigns the next invoice number, stores the invoice with its
  /// payments, and deducts stock. Throws `ConflictFailure` on invalid payments.
  Future<Invoice> issue(InvoiceDetail draft, List<PaymentEntry> payments);
}
