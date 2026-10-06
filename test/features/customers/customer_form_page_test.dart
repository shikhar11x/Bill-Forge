import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/theme/app_theme.dart';
import 'package:billforge/features/customers/application/customer_providers.dart';
import 'package:billforge/features/customers/presentation/customer_form_page.dart';

import '../../support/customer_fakes.dart';

void main() {
  late FakeCustomerRepository repo;

  setUp(() => repo = FakeCustomerRepository());

  Future<void> pumpForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: AppRoutes.customerNew,
      routes: [
        GoRoute(
          path: AppRoutes.customers,
          builder: (context, state) =>
              const Scaffold(body: Text('customer list')),
        ),
        GoRoute(
          path: AppRoutes.customerNew,
          builder: (context, state) => const Scaffold(body: CustomerFormPage()),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [customerRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('name is required', (tester) async {
    await pumpForm(tester);
    await tester.tap(find.text('Add customer'));
    await tester.pumpAndSettle();

    expect(find.text('Customer name is required'), findsOneWidget);
    expect(repo.saved, isNull);
  });

  testWidgets('invalid optional fields are rejected', (tester) async {
    await pumpForm(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'Rahul');
    await tester.enterText(find.byType(TextFormField).at(1), '12345');
    await tester.tap(find.text('Add customer'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid 10-digit mobile number'), findsOneWidget);
    expect(repo.saved, isNull);
  });

  testWidgets('saves a valid customer and returns to the list', (tester) async {
    await pumpForm(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'Rahul Sharma');
    await tester.enterText(find.byType(TextFormField).at(1), '98765 43210');
    await tester.tap(find.text('Add customer'));
    await tester.pumpAndSettle();

    expect(repo.saved?.name, 'Rahul Sharma');
    expect(repo.saved?.phone, '9876543210');
    expect(find.text('customer list'), findsOneWidget);
  });
}
