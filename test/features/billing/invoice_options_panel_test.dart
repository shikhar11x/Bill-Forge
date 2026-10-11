import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/app/theme/app_theme.dart';
import 'package:billforge/features/billing/application/invoice_pdf_providers.dart';
import 'package:billforge/features/billing/domain/invoice_template_options.dart';
import 'package:billforge/features/billing/presentation/widgets/invoice_options_panel.dart';

void main() {
  late ProviderContainer container;

  Future<void> pumpPanel(WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(
            body: SingleChildScrollView(child: InvoiceOptionsPanel()),
          ),
        ),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(InvoiceOptionsPanel)),
    );
  }

  testWidgets('defaults to A4 with everything shown', (tester) async {
    await pumpPanel(tester);
    final options = container.read(invoiceTemplateProvider);
    expect(options.paper, InvoicePaper.a4);
    expect(options.showLogo, isTrue);
    expect(options.showTaxSummary, isTrue);
  });

  testWidgets('choosing a paper size updates the options', (tester) async {
    await pumpPanel(tester);
    await tester.tap(find.text('80 mm'));
    await tester.pumpAndSettle();
    expect(container.read(invoiceTemplateProvider).paper, InvoicePaper.thermal80);

    await tester.tap(find.text('58 mm'));
    await tester.pumpAndSettle();
    expect(container.read(invoiceTemplateProvider).paper, InvoicePaper.thermal58);
  });

  testWidgets('toggles update the options', (tester) async {
    await pumpPanel(tester);
    await tester.tap(find.text('Shop logo'));
    await tester.pumpAndSettle();
    expect(container.read(invoiceTemplateProvider).showLogo, isFalse);

    await tester.tap(find.text('Amount in words'));
    await tester.pumpAndSettle();
    expect(container.read(invoiceTemplateProvider).showAmountInWords, isFalse);
  });
}