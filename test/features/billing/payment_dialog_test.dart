import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/app/theme/app_theme.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/billing/presentation/widgets/payment_dialog.dart';
import 'package:billforge/features/payments/domain/credit_check.dart';

void main() {
  PaymentResult? result;

  setUp(() => result = null);

  Future<void> openDialog(
    WidgetTester tester, {
    int total = 10000,
    bool hasCustomer = false,
    CreditContext? credit,
  }) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await PaymentDialog.show(
                  context,
                  totalPaise: total,
                  hasCustomer: hasCustomer,
                  credit: credit,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  FilledButton saveButton(WidgetTester tester) => tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Save & issue'),
          matching: find.byType(FilledButton),
        ),
      );

  testWidgets('a fully paid bill has no credit and no due date', (tester) async {
    await openDialog(tester, hasCustomer: true);
    expect(find.text('No due date'), findsNothing);

    await tester.tap(find.text('Save & issue'));
    await tester.pumpAndSettle();

    final entry = result!.entries.single;
    expect(entry.method, PaymentMethod.cash);
    expect(entry.amountPaise, 10000);
    expect(result!.dueDate, isNull);
  });

  testWidgets('a credit sale offers due-date choices', (tester) async {
    await openDialog(tester, hasCustomer: true);
    await tester.tap(find.byTooltip('Remove payment'));
    await tester.pumpAndSettle();

    expect(find.text('On credit'), findsOneWidget);
    expect(find.text('No due date'), findsOneWidget);
    expect(find.text('7 days'), findsOneWidget);
    expect(find.text('15 days'), findsOneWidget);
    expect(find.text('30 days'), findsOneWidget);
    expect(find.text('Pick date'), findsOneWidget);
  });

  testWidgets('picking 7 days sets the due date a week from today',
      (tester) async {
    await openDialog(tester, hasCustomer: true);
    await tester.tap(find.byTooltip('Remove payment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('7 days'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save & issue'));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    expect(result!.entries, isEmpty);
    expect(result!.dueDate, DateTime(now.year, now.month, now.day + 7));
  });

  testWidgets('leaving the due date alone means no due date', (tester) async {
    await openDialog(tester, hasCustomer: true);
    await tester.tap(find.byTooltip('Remove payment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save & issue'));
    await tester.pumpAndSettle();

    expect(result!.dueDate, isNull);
  });

  testWidgets('a shortfall without a customer cannot be issued',
      (tester) async {
    await openDialog(tester);
    await tester.enterText(find.byType(TextField).first, '50');
    await tester.pumpAndSettle();

    expect(
      find.text('Select a customer to put the remaining amount on credit.'),
      findsOneWidget,
    );
    expect(saveButton(tester).onPressed, isNull);
    expect(find.text('No due date'), findsNothing);
  });

  testWidgets('credit up to the limit is allowed, one paisa over is blocked',
      (tester) async {
    // Limit ₹500.00, already owes ₹300.00, bill is ₹300.00.
    await openDialog(
      tester,
      total: 30000,
      hasCustomer: true,
      credit: const CreditContext(limitPaise: 50000, outstandingPaise: 30000),
    );

    // Pay ₹100.00: ₹200.00 on credit, so exactly ₹500.00 owed.
    await tester.enterText(find.byType(TextField).first, '100');
    await tester.pumpAndSettle();
    expect(
      find.text('Credit limit ₹500.00: owes ₹300.00, ₹500.00 after this bill.'),
      findsOneWidget,
    );
    expect(saveButton(tester).onPressed, isNotNull);

    // Pay ₹99.99: ₹200.01 on credit, one paisa over the limit.
    await tester.enterText(find.byType(TextField).first, '99.99');
    await tester.pumpAndSettle();
    expect(find.textContaining('would be exceeded'), findsOneWidget);
    expect(saveButton(tester).onPressed, isNull);
  });

  testWidgets('a bill with no credit is never blocked by the limit',
      (tester) async {
    await openDialog(
      tester,
      total: 30000,
      hasCustomer: true,
      credit: const CreditContext(limitPaise: 0, outstandingPaise: 90000),
    );

    // Fully paid by default, so no credit is added.
    expect(find.textContaining('would be exceeded'), findsNothing);
    expect(saveButton(tester).onPressed, isNotNull);
  });
}