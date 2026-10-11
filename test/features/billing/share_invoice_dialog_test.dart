import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/app/theme/app_theme.dart';
import 'package:billforge/features/billing/application/invoice_pdf_providers.dart';
import 'package:billforge/features/billing/application/invoice_share_providers.dart';
import 'package:billforge/features/billing/presentation/widgets/share_invoice_dialog.dart';
import '../../support/fake_share_service.dart';
import '../../support/invoice_document_fakes.dart';
import '../../support/pdf_test_fonts.dart';

void main() {
  late FakeShareService service;

  setUp(() => service = FakeShareService());

  Future<void> pumpDialog(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          invoiceShareServiceProvider.overrideWithValue(service),
          pdfFontsProvider.overrideWith((ref) async => loadTestFonts()),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: ShareInvoiceDialog(document: makeInvoiceDocument()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('prefills the customer number and the message', (tester) async {
    await pumpDialog(tester);
    expect(find.text('9876543210'), findsOneWidget);
    expect(find.textContaining('INV-0042'), findsOneWidget);
  });

  testWidgets('Open WhatsApp sends the number and message', (tester) async {
    await pumpDialog(tester);
    await tester.tap(find.text('Open WhatsApp'));
    await tester.pumpAndSettle();

    expect(service.chatCalls, 1);
    expect(service.chatPhone, '9876543210');
    expect(service.chatMessage, contains('INV-0042'));
    expect(service.chatMessage, contains('Total: *₹1,275.00*'));
  });

  testWidgets('an empty number is allowed (contact picker)', (tester) async {
    await pumpDialog(tester);
    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.tap(find.text('Open WhatsApp'));
    await tester.pumpAndSettle();

    expect(service.chatCalls, 1);
    expect(service.chatPhone, isNull);
  });

  testWidgets('an invalid number is rejected before anything opens',
      (tester) async {
    await pumpDialog(tester);
    await tester.enterText(find.byType(TextFormField).first, '12345');
    await tester.tap(find.text('Open WhatsApp'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid 10-digit mobile number'), findsOneWidget);
    expect(service.chatCalls, 0);
  });

  testWidgets('an empty message is rejected', (tester) async {
    await pumpDialog(tester);
    await tester.enterText(find.byType(TextFormField).at(1), '');
    await tester.tap(find.text('Open WhatsApp'));
    await tester.pumpAndSettle();

    expect(find.text('Message cannot be empty'), findsOneWidget);
    expect(service.chatCalls, 0);
  });

  testWidgets('shows a hint when WhatsApp cannot be opened', (tester) async {
    service.chatResult = false;
    await pumpDialog(tester);
    await tester.tap(find.text('Open WhatsApp'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not open WhatsApp'), findsOneWidget);
  });

  testWidgets('Share PDF builds the invoice PDF and hands it over',
      (tester) async {
    await pumpDialog(tester);
    await tester.tap(find.text('Share PDF'));
    await tester.pumpAndSettle();

    expect(service.pdfCalls, 1);
    expect(service.pdfName, 'INV-0042.pdf');
    final bytes = service.pdfBytes!;
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(service.pdfMessage, contains('INV-0042'));
  });

  testWidgets('a failed PDF share shows an inline error', (tester) async {
    service.pdfThrows = true;
    await pumpDialog(tester);
    await tester.tap(find.text('Share PDF'));
    await tester.pumpAndSettle();

    expect(find.text('Could not share the PDF. Please try again.'), findsOneWidget);
  });
}