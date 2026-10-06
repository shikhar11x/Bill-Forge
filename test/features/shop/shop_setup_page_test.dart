import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/app/theme/app_theme.dart';
import 'package:billforge/features/shop/application/shop_providers.dart';
import 'package:billforge/features/shop/domain/business_type.dart';
import 'package:billforge/features/shop/presentation/shop_setup_page.dart';

import '../../support/fakes.dart';

void main() {
  late FakeShopRepository repo;

  setUp(() => repo = FakeShopRepository());

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [shopRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const ShopSetupPage(mode: SetupMode.create),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('step 1 blocks continuing with empty fields', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Shop name is required'), findsOneWidget);
    expect(find.text('Select your business type'), findsOneWidget);
    expect(find.text('Phone number is required'), findsOneWidget);
    expect(find.text('Step 1 of 4 · Business'), findsOneWidget);
  });

  testWidgets('completing all four steps saves the shop', (tester) async {
    await pumpPage(tester);

    // Step 1: business
    await tester.enterText(find.byType(TextFormField).at(0), 'Test Store');
    await tester.tap(find.byType(DropdownButtonFormField<BusinessType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(BusinessType.grocery.label).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '9876543210');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 2: address (first state in the list avoids scrolling the menu)
    await tester.enterText(find.byType(TextFormField).at(0), '1 Main Road');
    await tester.enterText(find.byType(TextFormField).at(2), 'Port Blair');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Andaman and Nicobar Islands').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(3), '744101');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 3: tax (defaults to unregistered, nothing required)
    expect(find.text('Step 3 of 4 · Tax'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 4: defaults are valid
    expect(find.text('Example: INV-0001'), findsOneWidget);
    await tester.tap(find.text('Create shop'));
    await tester.pumpAndSettle();

    expect(repo.saved?.name, 'Test Store');
    expect(repo.saved?.state, 'Andaman and Nicobar Islands');
    expect(repo.saved?.invoicePrefix, 'INV');
  });
}
