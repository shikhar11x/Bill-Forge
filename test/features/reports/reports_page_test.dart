import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/app/theme/app_theme.dart';
import 'package:billforge/core/widgets/app_stat_card.dart';
import 'package:billforge/features/billing/application/invoice_pdf_providers.dart';
import 'package:billforge/features/billing/application/invoice_share_providers.dart';
import 'package:billforge/features/payments/application/payment_providers.dart';
import 'package:billforge/features/products/application/product_providers.dart';
import 'package:billforge/features/reports/application/report_providers.dart';
import 'package:billforge/features/reports/domain/report_data.dart';
import 'package:billforge/features/reports/domain/report_range.dart';
import 'package:billforge/features/reports/presentation/reports_page.dart';
import 'package:billforge/features/shop/application/shop_providers.dart';

import '../../support/fake_share_service.dart';
import '../../support/fakes.dart';
import '../../support/payment_fakes.dart';
import '../../support/pdf_test_fonts.dart';
import '../../support/report_fakes.dart';

void main() {
  late FakeReportRepository reports;
  late FakeShareService share;

  setUp(() {
    final now = DateTime.now();
    reports = FakeReportRepository(
      ReportData(
        invoices: [
          sampleOpenInvoice(
            id: 'i1',
            total: 100000,
            paid: 100000,
            issuedAt: now,
          ),
        ],
        invoiceItems: [
          rItem(productId: 'p1', name: 'Basmati Rice', taxable: 100000),
        ],
        payments: [rPayment(paidAt: now)],
        costByProductId: const {'p1': 30000},
      ),
    );
    share = FakeShareService();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1300, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportRepositoryProvider.overrideWithValue(reports),
          productRepositoryProvider.overrideWithValue(
            FakeProductRepository([sampleProduct(name: 'Parle-G')]),
          ),
          paymentRepositoryProvider.overrideWithValue(FakePaymentRepository()),
          invoiceShareServiceProvider.overrideWithValue(share),
          pdfFontsProvider.overrideWith((ref) async => loadTestFonts()),
          shopProfileProvider.overrideWith((ref) => Stream.value(sampleShop())),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: ReportsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String stat(WidgetTester tester, String label) =>
      tester.widget<AppStatCard>(find.widgetWithText(AppStatCard, label)).value;

  testWidgets('opens on the sales report for this month', (tester) async {
    await pumpPage(tester);

    expect(stat(tester, 'Net sales'), '₹1,000.00');
    expect(stat(tester, 'Orders'), '1');
    expect(stat(tester, 'Est. profit'), '₹700.00');
    expect(find.text('Sales by day'), findsOneWidget);
    expect(reports.lastRange, ReportPreset.thisMonth.range(DateTime.now()));
  });

  testWidgets('tabs switch the report', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Products'));
    await tester.pumpAndSettle();
    expect(find.text('Basmati Rice'), findsOneWidget);

    await tester.tap(find.text('GST'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No GST was charged'), findsOneWidget);

    await tester.tap(find.text('Payments & credit'));
    await tester.pumpAndSettle();
    expect(find.text('Cash'), findsOneWidget);

    await tester.tap(find.text('Stock & purchases'));
    await tester.pumpAndSettle();
    expect(find.text('Stock value (at cost)'), findsOneWidget);
  });

  testWidgets('changing the period reloads for that range', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byType(DropdownButtonFormField<ReportPreset>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last 7 days').last);
    await tester.pumpAndSettle();

    expect(reports.lastRange, ReportPreset.last7Days.range(DateTime.now()));
  });

  testWidgets('Copy CSV puts the report on the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await pumpPage(tester);
    await tester.tap(find.text('Copy CSV'));
    await tester.pumpAndSettle();

    expect(copied, isNotNull);
    expect(copied, startsWith('Sales report\r\n'));
    expect(copied, contains('Net sales,1000.00'));
    expect(find.textContaining('CSV copied'), findsOneWidget);
  });

  testWidgets('Share PDF hands over a PDF named after the report', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.text('Share PDF'));
    await tester.pumpAndSettle();

    expect(share.pdfCalls, 1);
    expect(share.pdfName, startsWith('sales-report-'));
    expect(share.pdfName, endsWith('.pdf'));
    expect(String.fromCharCodes(share.pdfBytes!.take(4)), '%PDF');
  });
}
