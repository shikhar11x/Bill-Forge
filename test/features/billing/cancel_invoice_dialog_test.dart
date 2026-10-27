import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/app/theme/app_theme.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/features/billing/application/credit_note_providers.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/billing/presentation/widgets/cancel_invoice_dialog.dart';

import '../../support/credit_note_fakes.dart';
import '../../support/invoice_fakes.dart';

void main() {
  late FakeCreditNoteRepository credits;
  bool? result;

  setUp(() {
    credits = FakeCreditNoteRepository();
    result = null;
  });

  Future<void> openDialog(WidgetTester tester, Invoice invoice) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [creditNoteRepositoryProvider.overrideWithValue(credits)],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await CancelInvoiceDialog.show(context, invoice);
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

  testWidgets('a paid invoice shows the refund and cancels with it', (
    tester,
  ) async {
    await openDialog(
      tester,
      sampleInvoice(grandTotalPaise: 127500, paidPaise: 127500),
    );

    expect(find.text('Cancel INV-0001?'), findsOneWidget);
    expect(
      find.text('₹1,275.00 will be refunded to the customer.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel invoice'));
    await tester.pumpAndSettle();

    final call = credits.cancelled!;
    expect(call.invoiceId, 'i1');
    expect(call.restock, isTrue);
    expect(call.refundMethod, PaymentMethod.cash);
    expect(result, isTrue);
  });

  testWidgets('an unpaid invoice has nothing to refund', (tester) async {
    await openDialog(
      tester,
      sampleInvoice(grandTotalPaise: 127500, paidPaise: 0),
    );
    expect(find.textContaining('will be refunded'), findsNothing);

    await tester.tap(find.text('Cancel invoice'));
    await tester.pumpAndSettle();

    expect(credits.cancelled!.refundMethod, isNull);
  });

  testWidgets('goods can be left out of stock', (tester) async {
    await openDialog(tester, sampleInvoice());
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel invoice'));
    await tester.pumpAndSettle();

    expect(credits.cancelled!.restock, isFalse);
  });

  testWidgets('keeping the invoice does nothing', (tester) async {
    await openDialog(tester, sampleInvoice());
    await tester.tap(find.text('Keep invoice'));
    await tester.pumpAndSettle();

    expect(credits.cancelled, isNull);
    expect(result, isFalse);
  });

  testWidgets('a conflict is shown inside the dialog', (tester) async {
    credits.failure = const ConflictFailure(
      'This invoice is already cancelled.',
    );
    await openDialog(tester, sampleInvoice());
    await tester.tap(find.text('Cancel invoice'));
    await tester.pumpAndSettle();

    expect(find.text('This invoice is already cancelled.'), findsOneWidget);
    expect(find.byType(CancelInvoiceDialog), findsOneWidget);
    expect(result, isNull);
  });
}
