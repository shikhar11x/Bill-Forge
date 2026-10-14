import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/core/database/database_providers.dart';
import 'package:billforge/core/utils/async_value_x.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/payments/data/drift_payment_repository.dart';
import 'package:billforge/features/payments/domain/customer_ledger.dart';
import 'package:billforge/features/payments/domain/customer_payment.dart';
import 'package:billforge/features/payments/domain/outstanding.dart';
import 'package:billforge/features/payments/domain/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => DriftPaymentRepository(ref.watch(appDatabaseProvider)),
);

/// Every issued invoice that still has a balance. Feeds the dashboard, the
/// customers list and the outstanding report.
final openInvoicesProvider = StreamProvider<List<Invoice>>(
  (ref) => ref.watch(paymentRepositoryProvider).watchOpenInvoices(),
);

final outstandingReportProvider = Provider<OutstandingReport>((ref) {
  final invoices = ref.watch(openInvoicesProvider).dataOrNull;
  if (invoices == null) return OutstandingReport.empty;
  return buildOutstandingReport(invoices, now: DateTime.now());
});

/// What each customer owes, by customer id. Customers who owe nothing are
/// absent.
final customerBalancesProvider = Provider<Map<String, int>>((ref) {
  final report = ref.watch(outstandingReportProvider);
  return {for (final e in report.entries) e.customerId: e.outstandingPaise};
});

final customerOpenInvoicesProvider = StreamProvider.autoDispose
    .family<List<Invoice>, String>(
  (ref, customerId) =>
      ref.watch(paymentRepositoryProvider).watchOpenInvoicesFor(customerId),
);

final customerReceiptsProvider = StreamProvider.autoDispose
    .family<List<CustomerPayment>, String>(
  (ref, customerId) => ref
      .watch(paymentRepositoryProvider)
      .watchReceipts(customerId, limit: 50),
);

final customerLedgerProvider =
    FutureProvider.autoDispose.family<CustomerLedger, String>(
  (ref, customerId) =>
      ref.watch(paymentRepositoryProvider).loadLedger(customerId),
);