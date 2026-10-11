import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/app/theme/app_theme.dart';
import 'package:billforge/features/billing/application/billing_providers.dart';
import 'package:billforge/features/billing/application/invoice_pdf_providers.dart';
import 'package:billforge/features/billing/data/pdf/pdf_fonts.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/presentation/invoice_preview_page.dart';
import 'package:billforge/features/shop/application/shop_providers.dart';

import '../../support/fakes.dart';
import '../../support/invoice_fakes.dart';

void main() {
  testWidgets('a draft cannot be printed', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          invoiceRepositoryProvider.overrideWithValue(
            FakeInvoiceRepository([
              sampleInvoice(
                id: 'd1',
                number: null,
                status: InvoiceStatus.draft,
                paidPaise: 0,
              ),
            ]),
          ),
          shopProfileProvider.overrideWith((ref) => Stream.value(sampleShop())),
          pdfFontsProvider.overrideWith((ref) async => PdfFonts.builtIn()),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: InvoicePreviewPage(invoiceId: 'd1')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Only issued invoices can be printed'), findsOneWidget);
  });

  testWidgets('a missing invoice shows the same guard', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          invoiceRepositoryProvider.overrideWithValue(FakeInvoiceRepository()),
          shopProfileProvider.overrideWith((ref) => Stream.value(sampleShop())),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: InvoicePreviewPage(invoiceId: 'nope')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Only issued invoices can be printed'), findsOneWidget);
  });
}
