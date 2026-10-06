import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/app/theme/app_theme.dart';
import 'package:billforge/features/customers/application/customer_providers.dart';
import 'package:billforge/features/customers/domain/customer.dart';
import 'package:billforge/features/customers/presentation/customers_page.dart';

import '../../support/customer_fakes.dart';

void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    List<Customer> customers = const [],
  }) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerRepositoryProvider.overrideWithValue(
            FakeCustomerRepository(customers),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: CustomersPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the first-customer empty state', (tester) async {
    await pumpPage(tester);
    expect(find.text('Add your first customer'), findsOneWidget);
  });

  testWidgets('lists customers with phone and credit limit', (tester) async {
    await pumpPage(
      tester,
      customers: [
        sampleCustomer(id: 'a', name: 'Amit Verma', phone: '9811122233'),
        sampleCustomer(id: 'b', name: 'Rahul Sharma', creditLimitPaise: 500000),
      ],
    );
    expect(find.text('Amit Verma'), findsOneWidget);
    expect(find.text('Rahul Sharma'), findsOneWidget);
    expect(find.text('9811122233'), findsOneWidget);
    expect(find.text('₹5,000'), findsOneWidget);
    expect(find.text('No limit'), findsOneWidget);
  });

  testWidgets('debounced search narrows the list', (tester) async {
    await pumpPage(
      tester,
      customers: [
        sampleCustomer(id: 'a', name: 'Amit Verma'),
        sampleCustomer(id: 'b', name: 'Rahul Sharma'),
      ],
    );

    await tester.enterText(find.byType(TextField), 'amit');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Amit Verma'), findsOneWidget);
    expect(find.text('Rahul Sharma'), findsNothing);
  });

  testWidgets('no matches offers to clear the search', (tester) async {
    await pumpPage(
      tester,
      customers: [sampleCustomer(id: 'a', name: 'Amit Verma')],
    );

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('No customers found'), findsOneWidget);
    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Amit Verma'), findsOneWidget);
  });
}
