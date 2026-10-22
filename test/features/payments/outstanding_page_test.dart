import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/app/theme/app_theme.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/customers/application/customer_providers.dart';
import 'package:billforge/features/payments/application/payment_providers.dart';
import 'package:billforge/features/payments/presentation/outstanding_page.dart';
import 'package:billforge/features/shop/application/shop_providers.dart';

import '../../support/customer_fakes.dart';
import '../../support/fakes.dart';
import '../../support/payment_fakes.dart';

void main() {
  // Dates are far in the past or future so the tests do not depend on today.
  final invoices = [
    sampleOpenInvoice(
      id: 'i1',
      number: 'INV-0001',
      total: 100000,
      issuedAt: DateTime(2020, 1, 1),
      dueDate: DateTime(2020, 1, 15), // overdue
    ),
    sampleOpenInvoice(
      id: 'i2',
      number: 'INV-0002',
      total: 50000,
      paid: 20000,
      issuedAt: DateTime(2020, 2, 1),
    ),
    sampleOpenInvoice(
      id: 'i3',
      number: 'INV-0003',
      customerId: 'c2',
      customerName: 'Amit Verma',
      total: 20000,
      issuedAt: DateTime(2020, 3, 1),
    ),
  ];

  Future<void> pumpPage(
    WidgetTester tester, {
    List<Invoice> open = const [],
    Size size = const Size(1300, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          paymentRepositoryProvider.overrideWithValue(
            FakePaymentRepository(openInvoices: open),
          ),
          customerRepositoryProvider.overrideWithValue(
            FakeCustomerRepository([sampleCustomer()]),
          ),
          shopProfileProvider.overrideWith((ref) => Stream.value(sampleShop())),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: OutstandingPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows totals and one row per customer', (tester) async {
    await pumpPage(tester, open: invoices);

    expect(find.text('Outstanding balances'), findsOneWidget);
    expect(find.text('Total outstanding'), findsOneWidget);
    expect(find.text('₹1,500.00'), findsOneWidget);
    expect(find.text('₹1,000.00'), findsWidgets); // overdue
    expect(find.text('Customers owing'), findsOneWidget);
    expect(find.text('Rahul Sharma'), findsOneWidget);
    expect(find.text('Amit Verma'), findsOneWidget);
    expect(find.text('₹1,300.00'), findsOneWidget);
    expect(find.text('₹200.00'), findsOneWidget);
  });

  testWidgets('shows a cheerful empty state when nobody owes anything', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(find.text('No pending payments'), findsOneWidget);
  });

  testWidgets('the mobile layout lists customers as cards', (tester) async {
    await pumpPage(tester, open: invoices, size: const Size(400, 900));

    expect(find.text('Rahul Sharma'), findsOneWidget);
    expect(find.textContaining('2 open invoices'), findsOneWidget);
    expect(find.textContaining('overdue'), findsOneWidget);
  });

  testWidgets('Send reminder opens a message prefilled for that customer', (
    tester,
  ) async {
    await pumpPage(tester, open: invoices);
    await tester.tap(find.byTooltip('Send reminder').first);
    await tester.pumpAndSettle();

    expect(find.text('Payment reminder'), findsOneWidget);
    expect(find.text('9876543210'), findsOneWidget);
    expect(find.textContaining('Hello Rahul Sharma'), findsOneWidget);
  });
}
