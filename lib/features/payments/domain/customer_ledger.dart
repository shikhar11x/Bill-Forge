import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/payments/domain/customer_payment.dart';

/// Everything needed to build one customer's statement.
class CustomerLedger {
  const CustomerLedger({
    required this.invoices,
    required this.payments,
    required this.receipts,
  });

  /// Issued invoices only.
  final List<Invoice> invoices;

  /// Every payment row on those invoices: paid at sale (no `receiptId`) and
  /// allocations of later receipts.
  final List<InvoicePayment> payments;
  final List<CustomerPayment> receipts;
}