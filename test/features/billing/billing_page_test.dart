import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/app/theme/app_theme.dart';
import 'package:billforge/features/billing/application/billing_providers.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/presentation/billing_page.dart';

import '../../support/invoice_fakes.dart';

void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    List<Invoice> invoices = const [],
  }) async {
    tester.view.physicalSize = const Size(1300, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          invoiceRepositoryProvider.overrideWithValue(
            FakeInvoiceRepository(invoices),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: BillingPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the first-bill empty state', (tester) async {
    await pumpPage(tester);
    expect(find.text('Create your first bill'), findsOneWidget);
  });

  testWidgets('lists invoices with number, customer and status', (
    tester,
  ) async {
    await pumpPage(
      tester,
      invoices: [
        sampleInvoice(customerName: 'Rahul Sharma'),
        sampleInvoice(
          id: 'i2',
          number: 'INV-0002',
          grandTotalPaise: 20000,
          paidPaise: 5000,
        ),
        sampleInvoice(
          id: 'i3',
          number: null,
          status: InvoiceStatus.draft,
          grandTotalPaise: 3000,
          paidPaise: 0,
        ),
      ],
    );

    expect(find.text('INV-0001'), findsOneWidget);
    expect(find.text('Rahul Sharma'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Partial'), findsOneWidget);
    expect(find.text('Draft bill'), findsOneWidget);
    expect(find.text('Draft'), findsWidgets);
    expect(find.text('₹200.00'), findsOneWidget);
  });

  testWidgets('the Drafts filter hides issued invoices', (tester) async {
    await pumpPage(
      tester,
      invoices: [
        sampleInvoice(),
        sampleInvoice(
          id: 'i3',
          number: null,
          status: InvoiceStatus.draft,
          paidPaise: 0,
        ),
      ],
    );

    await tester.tap(find.text('Drafts'));
    await tester.pumpAndSettle();

    expect(find.text('INV-0001'), findsNothing);
    expect(find.text('Draft bill'), findsOneWidget);
  });
}
