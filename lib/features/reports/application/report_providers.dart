import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/core/database/database_providers.dart';
import 'package:billforge/features/billing/application/billing_providers.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/invoice_query.dart';
import 'package:billforge/features/payments/application/payment_providers.dart';
import 'package:billforge/features/products/application/product_providers.dart';
import 'package:billforge/features/products/domain/product.dart';
import 'package:billforge/features/products/domain/product_query.dart';
import 'package:billforge/features/reports/data/drift_report_repository.dart';
import 'package:billforge/features/reports/domain/customer_report.dart';
import 'package:billforge/features/reports/domain/gst_report.dart';
import 'package:billforge/features/reports/domain/payment_report.dart';
import 'package:billforge/features/reports/domain/product_report.dart';
import 'package:billforge/features/reports/domain/report_data.dart';
import 'package:billforge/features/reports/domain/report_models.dart';
import 'package:billforge/features/reports/domain/report_range.dart';
import 'package:billforge/features/reports/domain/report_repository.dart';
import 'package:billforge/features/reports/domain/sales_report.dart';
import 'package:billforge/features/reports/domain/stock_report.dart';

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => DriftReportRepository(ref.watch(appDatabaseProvider)),
);

/// Loaded when a screen opens and dropped when it closes, so coming back to a
/// report always shows fresh numbers.
final reportDataProvider = FutureProvider.autoDispose
    .family<ReportData, ReportRange>(
      (ref, range) => ref.watch(reportRepositoryProvider).load(range),
    );

/// Active products, for the stock valuation.
final activeProductsProvider = FutureProvider.autoDispose<List<Product>>(
  (ref) => ref
      .watch(productRepositoryProvider)
      .watchProducts(const ProductQuery(limit: 1000000))
      .first,
);

final recentInvoicesProvider = StreamProvider.autoDispose<List<Invoice>>(
  (ref) => ref
      .watch(invoiceRepositoryProvider)
      .watchInvoices(
        const InvoiceQuery(status: InvoiceStatusFilter.issued, limit: 6),
      ),
);

enum ReportTab {
  sales('Sales'),
  products('Products'),
  customers('Customers'),
  gst('GST'),
  payments('Payments & credit'),
  stock('Stock & purchases');

  const ReportTab(this.label);

  final String label;
}

final reportDocumentProvider = FutureProvider.autoDispose
    .family<ReportDocument, (ReportTab, ReportRange)>((ref, key) async {
      final (tab, range) = key;
      final data = await ref.watch(reportDataProvider(range).future);

      switch (tab) {
        case ReportTab.sales:
          return buildSalesDocument(data, range);
        case ReportTab.products:
          return buildProductsDocument(data, range);
        case ReportTab.customers:
          return buildCustomersDocument(data, range);
        case ReportTab.gst:
          return buildGstDocument(data, range);
        case ReportTab.payments:
          final open = await ref.watch(openInvoicesProvider.future);
          return buildPaymentsDocument(data, range, open, DateTime.now());
        case ReportTab.stock:
          final products = await ref.watch(activeProductsProvider.future);
          return buildStockDocument(
            products: products,
            data: data,
            range: range,
          );
      }
    });
