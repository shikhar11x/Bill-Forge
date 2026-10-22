import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/app/theme/app_theme.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/payments/application/payment_providers.dart';
import 'package:billforge/features/payments/presentation/widgets/collect_payment_dialog.dart';

import '../../support/customer_fakes.dart';
import '../../support/payment_fakes.dart';

void main() {
  late FakePaymentRepository repo;
  bool? result;

  // Rahul owes ₹1,000.00 on INV-0001 and ₹300.00 on INV-0002 (₹1,300.00).
  final invoices = [
    sampleOpenInvoice(
      id: 'i1',
      number: 'INV-0001',
      total: 100000,
      issuedAt: DateTime(2026, 5, 1),
    ),
    sampleOpenInvoice(
      id: 'i2',
      number: 'INV-0002',
      total: 50000,
      paid: 20000,
      issuedAt: DateTime(2026, 5, 10),
    ),
  ];

  setUp(() {
    repo = FakePaymentRepository(openInvoices: invoices);
    result = null;
  });

  Future<void> openDialog(WidgetTester tester, {String? invoiceId}) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [paymentRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await CollectPaymentDialog.show(
                    context,
                    customer: sampleCustomer(),
                    openInvoices: invoices,
                    invoiceId: invoiceId,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('starts with the whole balance as the amount', (tester) async {
    await openDialog(tester);
    expect(find.text('Total due: ₹1,300.00'), findsOneWidget);
    expect(find.text('1300.00'), findsOneWidget);
  });

  testWidgets('a partial payment goes to the oldest invoices first', (
    tester,
  ) async {
    await openDialog(tester);
    await tester.enterText(find.byType(TextFormField).first, '500');
    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();

    final call = repo.collected.single;
    expect(call.customerId, 'c1');
    expect(call.amountPaise, 50000);
    expect(call.method, PaymentMethod.cash);
    expect(call.invoiceId, isNull);
    expect(result, isTrue);
  });

  testWidgets('more than is due is rejected', (tester) async {
    await openDialog(tester);
    await tester.enterText(find.byType(TextFormField).first, '2000');
    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();

    expect(find.text('Cannot be more than the ₹1,300.00 due'), findsOneWidget);
    expect(repo.collected, isEmpty);
  });

  testWidgets('an empty amount is rejected', (tester) async {
    await openDialog(tester);
    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();

    expect(find.text('Amount is required'), findsOneWidget);
    expect(repo.collected, isEmpty);
  });

  testWidgets('a preselected invoice limits the amount and is sent along', (
    tester,
  ) async {
    await openDialog(tester, invoiceId: 'i2');
    expect(find.text('300.00'), findsOneWidget);

    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();

    expect(repo.collected.single.invoiceId, 'i2');
    expect(repo.collected.single.amountPaise, 30000);
  });

  testWidgets('choosing an invoice updates the suggested amount', (
    tester,
  ) async {
    await openDialog(tester);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('INV-0002 · due ₹300.00').last);
    await tester.pumpAndSettle();

    expect(find.text('300.00'), findsOneWidget);
  });

  testWidgets('the payment method can be changed', (tester) async {
    await openDialog(tester);
    await tester.tap(find.byType(DropdownButtonFormField<PaymentMethod>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('UPI').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();

    expect(repo.collected.single.method, PaymentMethod.upi);
  });

  testWidgets('a repository conflict is shown inside the dialog', (
    tester,
  ) async {
    repo.failure = const ConflictFailure('This customer has nothing due.');
    await openDialog(tester);
    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();

    expect(find.text('This customer has nothing due.'), findsOneWidget);
    expect(find.byType(CollectPaymentDialog), findsOneWidget);
    expect(result, isNull);
  });
}
