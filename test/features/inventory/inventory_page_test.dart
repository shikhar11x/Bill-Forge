import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/app/theme/app_theme.dart';
import 'package:billforge/features/inventory/application/inventory_providers.dart';
import 'package:billforge/features/inventory/presentation/inventory_page.dart';
import 'package:billforge/features/products/application/product_providers.dart';
import 'package:billforge/features/products/domain/product.dart';

import '../../support/fakes.dart';
import '../../support/inventory_fakes.dart';

void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    required List<Product> products,
  }) async {
    tester.view.physicalSize = const Size(1300, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(
            FakeProductRepository(products),
          ),
          supplierRepositoryProvider.overrideWithValue(
            FakeSupplierRepository(),
          ),
          purchaseRepositoryProvider.overrideWithValue(
            FakePurchaseRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: InventoryPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final healthy = sampleProduct(
    id: 'a',
    name: 'Amul Butter',
    stockMilli: 50000,
  );
  final low = sampleProduct(
    id: 'b',
    name: 'Parle-G Biscuits',
    stockMilli: 2000,
    lowStockThresholdMilli: 5000,
  );
  final out = sampleProduct(id: 'c', name: 'Maggi Noodles', stockMilli: 0);

  testWidgets('Needs attention lists only low and out-of-stock products', (
    tester,
  ) async {
    await pumpPage(tester, products: [healthy, low, out]);

    expect(find.text('Parle-G Biscuits'), findsOneWidget);
    expect(find.text('Maggi Noodles'), findsOneWidget);
    expect(find.text('Amul Butter'), findsNothing);
  });

  testWidgets('All stock lists every product', (tester) async {
    await pumpPage(tester, products: [healthy, low, out]);
    await tester.tap(find.text('All stock'));
    await tester.pumpAndSettle();

    expect(find.text('Amul Butter'), findsOneWidget);
    expect(find.text('Parle-G Biscuits'), findsOneWidget);
    expect(find.text('Maggi Noodles'), findsOneWidget);
  });

  testWidgets('shows a reassuring empty state when nothing needs restocking', (
    tester,
  ) async {
    await pumpPage(tester, products: [healthy]);
    expect(find.text('Stock looks good'), findsOneWidget);
  });

  testWidgets('the Purchases and Suppliers tabs show their empty states', (
    tester,
  ) async {
    await pumpPage(tester, products: [healthy]);

    await tester.tap(find.text('Purchases'));
    await tester.pumpAndSettle();
    expect(find.text('No purchases yet'), findsOneWidget);

    await tester.tap(find.text('Suppliers'));
    await tester.pumpAndSettle();
    expect(find.text('No suppliers yet'), findsOneWidget);
  });
}
