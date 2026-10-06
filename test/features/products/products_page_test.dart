import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/app/theme/app_theme.dart';
import 'package:billforge/features/products/application/product_providers.dart';
import 'package:billforge/features/products/domain/product.dart';
import 'package:billforge/features/products/presentation/products_page.dart';
import 'package:billforge/features/shop/application/shop_providers.dart';

import '../../support/fakes.dart';

void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    List<Product> products = const [],
  }) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(
            FakeProductRepository(products),
          ),
          categoryRepositoryProvider.overrideWithValue(
            FakeCategoryRepository(),
          ),
          shopProfileProvider.overrideWith((ref) => Stream.value(sampleShop())),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: ProductsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the first-product empty state', (tester) async {
    await pumpPage(tester);
    expect(find.text('Add your first product'), findsOneWidget);
  });

  testWidgets('lists products with price and stock', (tester) async {
    await pumpPage(
      tester,
      products: [
        sampleProduct(id: 'a', name: 'Amul Butter', sellingPricePaise: 5500),
        sampleProduct(
          id: 'b',
          name: 'Parle-G Biscuits',
          stockMilli: 2000,
          lowStockThresholdMilli: 5000,
        ),
      ],
    );
    expect(find.text('Amul Butter'), findsOneWidget);
    expect(find.text('Parle-G Biscuits'), findsOneWidget);
    expect(find.text('₹55.00'), findsOneWidget);
    expect(find.text('Low · 2 pcs'), findsOneWidget);
  });

  testWidgets('debounced search narrows the list', (tester) async {
    await pumpPage(
      tester,
      products: [
        sampleProduct(id: 'a', name: 'Amul Butter'),
        sampleProduct(id: 'b', name: 'Parle-G Biscuits'),
      ],
    );

    await tester.enterText(find.byType(TextField), 'amul');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Amul Butter'), findsOneWidget);
    expect(find.text('Parle-G Biscuits'), findsNothing);
  });

  testWidgets('no matches offers to clear the search', (tester) async {
    await pumpPage(
      tester,
      products: [sampleProduct(id: 'a', name: 'Amul Butter')],
    );

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('No products found'), findsOneWidget);
    await tester.tap(find.text('Clear search & filters'));
    await tester.pumpAndSettle();
    expect(find.text('Amul Butter'), findsOneWidget);
  });
}
