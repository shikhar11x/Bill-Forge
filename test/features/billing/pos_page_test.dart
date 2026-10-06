import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/theme/app_theme.dart';
import 'package:billforge/features/billing/application/billing_providers.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/billing/presentation/pos_page.dart';
import 'package:billforge/features/customers/application/customer_providers.dart';
import 'package:billforge/features/products/application/product_providers.dart';
import 'package:billforge/features/shop/application/shop_providers.dart';

import '../../support/customer_fakes.dart';
import '../../support/fakes.dart';
import '../../support/invoice_fakes.dart';

void main() {
  late FakeInvoiceRepository invoices;

  setUp(() => invoices = FakeInvoiceRepository());

  Future<void> pumpPos(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1300, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: AppRoutes.billingNew,
      routes: [
        GoRoute(
          path: AppRoutes.billing,
          builder: (context, state) =>
              const Scaffold(body: Text('invoice list')),
        ),
        GoRoute(
          path: AppRoutes.billingNew,
          builder: (context, state) => const Scaffold(body: PosPage()),
        ),
        GoRoute(
          path: '/billing/:id',
          builder: (context, state) =>
              const Scaffold(body: Text('invoice page')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(
            FakeProductRepository([
              sampleProduct(
                id: 'a',
                name: 'Amul Butter',
                sellingPricePaise: 5500,
                barcode: '8901234567890',
              ),
              sampleProduct(id: 'b', name: 'Parle-G Biscuits'),
            ]),
          ),
          customerRepositoryProvider.overrideWithValue(
            FakeCustomerRepository([sampleCustomer()]),
          ),
          invoiceRepositoryProvider.overrideWithValue(invoices),
          shopProfileProvider.overrideWith((ref) => Stream.value(sampleShop())),
        ],
        child: MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('starts with an empty cart', (tester) async {
    await pumpPos(tester);
    expect(find.text('Cart is empty'), findsOneWidget);
    expect(find.text('Amul Butter'), findsOneWidget);
  });

  testWidgets('tapping a product adds it and shows the total', (tester) async {
    await pumpPos(tester);
    await tester.tap(find.text('Amul Butter'));
    await tester.pumpAndSettle();

    expect(find.text('Cart is empty'), findsNothing);
    expect(find.text('Charge ₹55.00'), findsOneWidget);

    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pumpAndSettle();
    expect(find.text('Charge ₹110.00'), findsOneWidget);
  });

  testWidgets('Enter on an exact barcode adds that product', (tester) async {
    await pumpPos(tester);
    await tester.enterText(find.byType(TextField).first, '8901234567890');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Charge ₹55.00'), findsOneWidget);
  });

  testWidgets('charging issues the invoice with the entered payment', (
    tester,
  ) async {
    await pumpPos(tester);
    await tester.tap(find.text('Amul Butter'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Charge ₹55.00'));
    await tester.pumpAndSettle();
    expect(find.text('Take payment'), findsOneWidget);

    await tester.tap(find.text('Save & issue'));
    await tester.pumpAndSettle();

    expect(invoices.lastIssued, isNotNull);
    expect(invoices.lastIssued!.items.single.name, 'Amul Butter');
    expect(invoices.lastIssued!.invoice.grandTotalPaise, 5500);
    expect(invoices.lastPayments, hasLength(1));
    expect(invoices.lastPayments!.single.method, PaymentMethod.cash);
    expect(invoices.lastPayments!.single.amountPaise, 5500);
    expect(find.text('invoice page'), findsOneWidget);
  });

  testWidgets('a credit sale needs a customer', (tester) async {
    await pumpPos(tester);
    await tester.tap(find.text('Amul Butter'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Charge ₹55.00'));
    await tester.pumpAndSettle();

    // Remove the pre-filled cash payment: the whole bill becomes credit.
    await tester.tap(find.byTooltip('Remove payment'));
    await tester.pumpAndSettle();

    expect(
      find.text('Select a customer to put the remaining amount on credit.'),
      findsOneWidget,
    );
    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Save & issue'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('saving a draft stores it and returns to the list', (
    tester,
  ) async {
    await pumpPos(tester);
    await tester.tap(find.text('Amul Butter'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save draft'));
    await tester.pumpAndSettle();

    expect(invoices.lastDraft, isNotNull);
    expect(invoices.lastDraft!.items, hasLength(1));
    expect(find.text('invoice list'), findsOneWidget);
  });
}
