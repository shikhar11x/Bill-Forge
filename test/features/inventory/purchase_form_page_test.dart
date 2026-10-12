import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/theme/app_theme.dart';
import 'package:billforge/features/inventory/application/inventory_providers.dart';
import 'package:billforge/features/inventory/presentation/purchase_form_page.dart';
import 'package:billforge/features/products/application/product_providers.dart';
import '../../support/fakes.dart';
import '../../support/inventory_fakes.dart';

void main() {
  late FakePurchaseRepository purchases;

  setUp(() => purchases = FakePurchaseRepository());

  Future<void> pumpForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: AppRoutes.purchaseNew,
      routes: [
        GoRoute(
          path: AppRoutes.inventory,
          builder: (context, state) =>
              const Scaffold(body: Text('inventory page')),
        ),
        GoRoute(
          path: AppRoutes.purchaseNew,
          builder: (context, state) =>
              const Scaffold(body: PurchaseFormPage()),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(
            FakeProductRepository([
              sampleProduct(id: 'p1', name: 'Parle-G Biscuits'),
              sampleProduct(id: 'p2', name: 'Service Charge', trackStock: false),
            ]),
          ),
          supplierRepositoryProvider.overrideWithValue(
            FakeSupplierRepository([sampleSupplier()]),
          ),
          purchaseRepositoryProvider.overrideWithValue(purchases),
        ],
        child: MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester) async {
    final button = find.text('Save purchase');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('saving with no items asks for at least one product',
      (tester) async {
    await pumpForm(tester);
    await tapSave(tester);

    expect(find.text('Add at least one product.'), findsOneWidget);
    expect(purchases.received, isNull);
  });

  testWidgets('a product without stock tracking cannot be added',
      (tester) async {
    await pumpForm(tester);
    await tester.tap(find.text('Add product'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Service Charge'));
    await tester.pumpAndSettle();

    expect(find.textContaining('stock tracking turned off'), findsOneWidget);
    expect(find.byKey(const ValueKey('qty-p2')), findsNothing);
  });

  testWidgets('adding a product, entering quantity and cost, and saving',
      (tester) async {
    await pumpForm(tester);
    await tester.tap(find.text('Add product'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Parle-G Biscuits'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('qty-p1')), '10');
    await tester.enterText(find.byKey(const ValueKey('cost-p1')), '8');
    await tester.pumpAndSettle();
    expect(find.text('Line total: ₹80.00'), findsOneWidget);

    await tapSave(tester);

    final detail = purchases.received!;
    expect(detail.purchase.totalPaise, 8000);
    expect(detail.items.single.productId, 'p1');
    expect(detail.items.single.qtyMilli, 10000);
    expect(detail.items.single.unitCostPaise, 800);
    expect(purchases.receivedUpdateCosts, isTrue);
    expect(find.text('inventory page'), findsOneWidget);
  });

  testWidgets('a missing cost blocks saving', (tester) async {
    await pumpForm(tester);
    await tester.tap(find.text('Add product'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Parle-G Biscuits'));
    await tester.pumpAndSettle();

    await tapSave(tester);

    expect(find.text('Cost is required'), findsOneWidget);
    expect(purchases.received, isNull);
  });
}