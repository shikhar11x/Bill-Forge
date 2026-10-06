import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/core/database/database_providers.dart';
import 'package:billforge/features/billing/data/drift_invoice_repository.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/invoice_query.dart';
import 'package:billforge/features/billing/domain/invoice_repository.dart';
import 'package:billforge/features/customers/application/customer_providers.dart';
import 'package:billforge/features/customers/domain/customer.dart';
import 'package:billforge/features/customers/domain/customer_query.dart';
import 'package:billforge/features/products/application/product_providers.dart';
import 'package:billforge/features/products/domain/product.dart';
import 'package:billforge/features/products/domain/product_query.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>(
  (ref) => DriftInvoiceRepository(ref.watch(appDatabaseProvider)),
);

class InvoiceQueryNotifier extends Notifier<InvoiceQuery> {
  @override
  InvoiceQuery build() => const InvoiceQuery();

  void setSearch(String value) =>
      state = state.copyWith(search: value, limit: kInvoicePageSize);

  void setStatus(InvoiceStatusFilter value) =>
      state = state.copyWith(status: value, limit: kInvoicePageSize);

  void loadMore() =>
      state = state.copyWith(limit: state.limit + kInvoicePageSize);

  void reset() => state = const InvoiceQuery();
}

final invoiceQueryProvider =
    NotifierProvider<InvoiceQueryNotifier, InvoiceQuery>(
      InvoiceQueryNotifier.new,
    );

final invoicesProvider = StreamProvider<List<Invoice>>((ref) {
  final query = ref.watch(invoiceQueryProvider);
  return ref.watch(invoiceRepositoryProvider).watchInvoices(query);
});

final invoiceDetailProvider = FutureProvider.autoDispose
    .family<InvoiceDetail?, String>(
      (ref, id) => ref.watch(invoiceRepositoryProvider).getDetail(id),
    );

/// Product search used by the POS screen. Auto-disposes, so it starts clean
/// every time the screen opens.
class BillProductQueryNotifier extends Notifier<ProductQuery> {
  @override
  ProductQuery build() => const ProductQuery();

  void setSearch(String value) =>
      state = state.copyWith(search: value, limit: kProductPageSize);

  void loadMore() =>
      state = state.copyWith(limit: state.limit + kProductPageSize);
}

final billProductQueryProvider =
    NotifierProvider.autoDispose<BillProductQueryNotifier, ProductQuery>(
      BillProductQueryNotifier.new,
    );

final billProductsProvider = StreamProvider.autoDispose<List<Product>>((ref) {
  final query = ref.watch(billProductQueryProvider);
  return ref.watch(productRepositoryProvider).watchProducts(query);
});

final customerSearchProvider = StreamProvider.autoDispose
    .family<List<Customer>, String>((ref, search) {
      return ref
          .watch(customerRepositoryProvider)
          .watchCustomers(CustomerQuery(search: search));
    });
