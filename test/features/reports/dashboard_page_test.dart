import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/app/theme/app_theme.dart';
import 'package:billforge/core/widgets/app_stat_card.dart';
import 'package:billforge/features/billing/application/billing_providers.dart';
import 'package:billforge/features/dashboard/presentation/dashboard_page.dart';
import 'package:billforge/features/payments/application/payment_providers.dart';
import 'package:billforge/features/products/application/product_providers.dart';
import 'package:billforge/features/reports/application/report_providers.dart';
import 'package:billforge/features/reports/domain/report_data.dart';

import '../../support/fakes.dart';
import '../../support/invoice_fakes.dart';
import '../../support/payment_fakes.dart';
import '../../support/report_fakes.dart';

void main() {
  Future<void> pumpDashboard(
    WidgetTester tester, {
    ReportData data = const ReportData(),
  }) async {
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportRepositoryProvider.overrideWithValue(
            FakeReportRepository(data),
          ),
          invoiceRepositoryProvider.overrideWithValue(
            FakeInvoiceRepository([sampleInvoice(number: 'INV-0042')]),
          ),
          paymentRepositoryProvider.overrideWithValue(
            FakePaymentRepository(
              openInvoices: [sampleOpenInvoice(total: 60000)],
            ),
          ),
          productRepositoryProvider.overrideWithValue(
            FakeProductRepository([
              sampleProduct(stockMilli: 1000, lowStockThresholdMilli: 5000),
            ]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: DashboardPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String stat(WidgetTester tester, String label) =>
      tester.widget<AppStatCard>(find.widgetWithText(AppStatCard, label)).value;

  testWidgets("shows today's real numbers", (tester) async {
    final now = DateTime.now();
    await pumpDashboard(
      tester,
      data: ReportData(
        invoices: [
          sampleOpenInvoice(
            id: 'i1',
            total: 100000,
            paid: 100000,
            issuedAt: now,
          ),
          // Yesterday's sale does not count towards today.
          sampleOpenInvoice(
            id: 'i0',
            total: 50000,
            paid: 50000,
            issuedAt: DateTime(now.year, now.month, now.day - 1, 12),
          ),
        ],
        invoiceItems: [
          rItem(invoiceId: 'i1', productId: 'p1', name: 'Basmati Rice'),
        ],
        payments: [rPayment(paidAt: now)],
        costByProductId: const {'p1': 30000},
      ),
    );

    expect(stat(tester, "Today's sales"), '₹1,000.00');
    expect(stat(tester, 'Orders today'), '1');
    expect(stat(tester, "Today's est. profit"), '₹700.00');
    expect(stat(tester, 'Pending payments'), '₹600.00');
    expect(stat(tester, 'Low-stock items'), '1');
  });

  testWidgets('lists top products, payments and recent invoices', (
    tester,
  ) async {
    final now = DateTime.now();
    await pumpDashboard(
      tester,
      data: ReportData(
        invoices: [
          sampleOpenInvoice(
            id: 'i1',
            total: 100000,
            paid: 100000,
            issuedAt: now,
          ),
        ],
        invoiceItems: [
          rItem(invoiceId: 'i1', productId: 'p1', name: 'Basmati Rice'),
        ],
        payments: [rPayment(paidAt: now)],
      ),
    );

    expect(find.text('Top products (30 days)'), findsOneWidget);
    expect(find.text('Basmati Rice'), findsOneWidget);
    expect(find.text('Payments (30 days)'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('Recent invoices'), findsOneWidget);
    expect(find.text('INV-0042'), findsOneWidget);
  });

  testWidgets('a shop with no sales yet shows empty states', (tester) async {
    await pumpDashboard(tester);

    expect(stat(tester, "Today's sales"), '₹0.00');
    expect(stat(tester, 'Orders today'), '0');
    expect(stat(tester, "Today's est. profit"), '—');
    expect(find.text('No sales yet'), findsWidgets);
    expect(find.text('No payments yet'), findsOneWidget);
  });

  testWidgets('the chart can switch between 7 and 30 days', (tester) async {
    await pumpDashboard(tester);
    await tester.tap(find.text('30 days'));
    await tester.pumpAndSettle();

    expect(find.text('Sales overview'), findsOneWidget);
  });

  testWidgets('the hero greets and offers quick actions', (tester) async {
    await pumpDashboard(tester);

    expect(find.textContaining('Welcome back'), findsOneWidget);
    expect(find.text('New bill'), findsOneWidget);
    expect(find.text('Add product'), findsOneWidget);
    expect(
      find.text('No sales yet today. Ready to make the first bill?'),
      findsOneWidget,
    );
  });

  testWidgets('the hero summarises todays sales', (tester) async {
    final now = DateTime.now();
    await pumpDashboard(
      tester,
      data: ReportData(
        invoices: [
          sampleOpenInvoice(
            id: 'i1',
            total: 100000,
            paid: 100000,
            issuedAt: now,
          ),
        ],
        invoiceItems: [rItem(invoiceId: 'i1')],
        payments: [rPayment(paidAt: now)],
      ),
    );

    expect(
      find.text('1 bill and ₹1,000.00 in sales so far today.'),
      findsOneWidget,
    );
  });
}
