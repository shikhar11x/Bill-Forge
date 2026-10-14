import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/payments/domain/customer_ledger.dart';
import 'package:billforge/features/payments/domain/customer_payment.dart';

abstract interface class PaymentRepository {
  /// Issued invoices with a balance, for every customer, oldest first.
  Stream<List<Invoice>> watchOpenInvoices();

  Stream<List<Invoice>> watchOpenInvoicesFor(String customerId);

  /// Newest first.
  Stream<List<CustomerPayment>> watchReceipts(
    String customerId, {
    required int limit,
  });

  Future<CustomerLedger> loadLedger(String customerId);

  /// Atomically records a receipt and spreads it over the customer's open
  /// invoices (oldest first), or over [invoiceId] alone. Throws
  /// `ConflictFailure` when the amount is zero, nothing is due, or the amount
  /// is more than what is due.
  Future<CustomerPayment> collect({
    required String customerId,
    required int amountPaise,
    required PaymentMethod method,
    String? note,
    String? invoiceId,
  });
}