import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/theme/app_theme.dart';
import 'package:billforge/features/billing/application/billing_providers.dart';
import 'package:billforge/features/billing/application/credit_note_providers.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/billing/presentation/return_items_page.dart';

import '../../support/credit_note_fakes.dart';
import '../../support/invoice_document_fakes.dart';
import '../../support/invoice_fakes.dart';

void main() {
  late FakeCreditNoteRepository credits;

  setUp(() => credits = FakeCreditNoteRepository());

  // Rice: 2 pcs, ₹900.00. Dal: 2.5 kg, ₹375.00. Invoice total ₹1,275.00.
  Future<void> pumpPage(WidgetTester tester, {int paid = 127500}) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final detail = makeInvoiceDocument(paidPaise: paid).detail;
    final router = GoRouter(
      initialLocation: AppRoutes.invoiceReturn('inv_1'),
      routes: [
        GoRoute(
          path: '/billing/:id',
          builder: (context, state) =>
              const Scaffold(body: Text('invoice page')),
          routes: [
            GoRoute(
              path: 'return',
              builder: (context, state) =>
                  const Scaffold(body: ReturnItemsPage(invoiceId: 'inv_1')),
            ),
          ],
        ),
        GoRoute(
          path: '/billing/credit-notes/:id',
          builder: (context, state) =>
              const Scaffold(body: Text('credit note page')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          creditNoteRepositoryProvider.overrideWithValue(credits),
          invoiceRepositoryProvider.overrideWithValue(
            FakeInvoiceRepository()..details['inv_1'] = detail,
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapIssue(WidgetTester tester) async {
    final button = find.text('Issue credit note');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('lists the items that can be returned', (tester) async {
    await pumpPage(tester);
    expect(find.text('Basmati Rice 5 kg'), findsOneWidget);
    expect(find.text('Toor Dal'), findsOneWidget);
    expect(find.text('Sold 2 pcs · can return 2'), findsOneWidget);
    expect(find.text('Sold 2.5 kg · can return 2.5'), findsOneWidget);
  });

  testWidgets('a paid invoice is refunded and the selection is sent', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.enterText(find.byType(TextFormField).first, '1');
    await tester.pumpAndSettle();

    expect(find.text('Credit note total'), findsOneWidget);
    expect(find.text('Refund to customer'), findsOneWidget);
    expect(find.text('Reduces balance due'), findsNothing);
    expect(find.text('₹450.00'), findsWidgets);

    await tapIssue(tester);

    final call = credits.issued!;
    expect(call.invoiceId, 'inv_1');
    expect(call.quantities, {'inv_1-1': 1000});
    expect(call.restock, isTrue);
    expect(call.refundMethod, PaymentMethod.cash);
    expect(find.text('credit note page'), findsOneWidget);
  });

  testWidgets('a credit sale reduces the balance instead of refunding', (
    tester,
  ) async {
    await pumpPage(tester, paid: 0);
    await tester.enterText(find.byType(TextFormField).first, '1');
    await tester.pumpAndSettle();

    expect(find.text('Reduces balance due'), findsOneWidget);
    expect(find.text('Refund to customer'), findsNothing);

    await tapIssue(tester);
    expect(credits.issued!.refundMethod, isNull);
  });

  testWidgets('nothing entered cannot be issued', (tester) async {
    await pumpPage(tester);
    expect(
      find.text('Enter the quantity to return for each item.'),
      findsOneWidget,
    );

    await tapIssue(tester);
    expect(find.text('Select at least one item to return.'), findsOneWidget);
    expect(credits.issued, isNull);
  });

  testWidgets('returning more than was sold is rejected', (tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byType(TextFormField).first, '3');
    await tapIssue(tester);

    expect(find.text('Only 2 can be returned'), findsOneWidget);
    expect(credits.issued, isNull);
  });

  testWidgets('"All" fills in everything that can be returned', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('All').first);
    await tester.pumpAndSettle();

    expect(find.text('2'), findsWidgets);
    await tapIssue(tester);
    expect(credits.issued!.quantities, {'inv_1-1': 2000});
  });
}
