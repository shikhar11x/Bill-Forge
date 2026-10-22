import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/app/theme/app_theme.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/customers/application/customer_providers.dart';
import 'package:billforge/features/payments/application/payment_providers.dart';
import 'package:billforge/features/payments/domain/customer_payment.dart';
import 'package:billforge/features/payments/presentation/customer_account_page.dart';
import 'package:billforge/features/shop/application/shop_providers.dart';

import '../../support/customer_fakes.dart';
import '../../support/fakes.dart';
import '../../support/payment_fakes.dart';

void main() {
  final open = [
    sampleOpenInvoice(
      id: 'i1',
      number: 'INV-0001',
      total: 100000,
      issuedAt: DateTime(2020, 1, 1),
      dueDate: DateTime(2020, 1, 15), // long overdue
    ),
    sampleOpenInvoice(
      id: 'i2',
      number: 'INV-0002',
      total: 50000,
      paid: 20000,
      issuedAt: DateTime(2020, 2, 1),
    ),
  ];

  Future<void> pumpPage(
    WidgetTester tester, {
    List<Invoice> invoices = const [],
    List<CustomerPayment> receipts = const [],
  }) async {
    tester.view.physicalSize = const Size(1100, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerRepositoryProvider.overrideWithValue(
            FakeCustomerRepository([sampleCustomer(creditLimitPaise: 500000)]),
          ),
          paymentRepositoryProvider.overrideWithValue(
            FakePaymentRepository(openInvoices: invoices, receipts: receipts),
          ),
          shopProfileProvider.overrideWith((ref) => Stream.value(sampleShop())),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: CustomerAccountPage(customerId: 'c1')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows balance, overdue amount and credit available', (
    tester,
  ) async {
    await pumpPage(tester, invoices: open);

    expect(find.text('Rahul Sharma'), findsOneWidget);
    expect(find.text('₹1,300.00'), findsOneWidget); // outstanding
    expect(find.text('₹1,000.00'), findsWidgets); // overdue stat + invoice
    expect(find.text('₹5,000'), findsOneWidget); // credit limit
    expect(find.text('₹3,700.00 available'), findsOneWidget);
  });

  testWidgets('lists open invoices and flags overdue ones', (tester) async {
    await pumpPage(tester, invoices: open);

    expect(find.text('INV-0001'), findsOneWidget);
    expect(find.text('INV-0002'), findsOneWidget);
    // One in the stat card label, one badge on the overdue invoice.
    expect(find.text('Overdue'), findsNWidgets(2));
  });

  testWidgets('shows recent payments', (tester) async {
    await pumpPage(
      tester,
      invoices: open,
      receipts: [sampleReceipt(amountPaise: 50000, note: 'Cheque')],
    );

    expect(find.text('Recent payments'), findsOneWidget);
    expect(find.text('+₹500.00'), findsOneWidget);
    expect(find.textContaining('Cheque'), findsOneWidget);
  });

  testWidgets('a paid-up customer cannot be charged or reminded', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(
      find.text('No pending invoices. This customer is paid up.'),
      findsOneWidget,
    );
    expect(find.text('No payments collected yet.'), findsOneWidget);

    FilledButton buttonFor(String label) => tester.widget<FilledButton>(
      find.ancestor(of: find.text(label), matching: find.byType(FilledButton)),
    );
    expect(buttonFor('Collect payment').onPressed, isNull);
  });

  testWidgets('Collect payment opens the dialog for this customer', (
    tester,
  ) async {
    await pumpPage(tester, invoices: open);
    await tester.tap(find.text('Collect payment'));
    await tester.pumpAndSettle();

    expect(find.text('Collect payment · Rahul Sharma'), findsOneWidget);
    expect(find.text('Total due: ₹1,300.00'), findsOneWidget);
  });

  testWidgets('Send reminder opens a prefilled message', (tester) async {
    await pumpPage(tester, invoices: open);
    await tester.tap(find.text('Send reminder'));
    await tester.pumpAndSettle();

    expect(find.text('Payment reminder'), findsOneWidget);
    expect(find.textContaining('Hello Rahul Sharma'), findsOneWidget);
  });
}
