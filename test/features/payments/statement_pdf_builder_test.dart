import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/payments/data/pdf/statement_pdf_builder.dart';
import 'package:billforge/features/payments/domain/customer_ledger.dart';
import 'package:billforge/features/payments/domain/statement.dart';

import '../../support/customer_fakes.dart';
import '../../support/fakes.dart';
import '../../support/payment_fakes.dart';
import '../../support/pdf_test_fonts.dart';
import 'statement_test.dart' as fixture;

bool isPdf(Uint8List bytes) =>
    bytes.length > 4 &&
    bytes[0] == 0x25 &&
    bytes[1] == 0x50 &&
    bytes[2] == 0x44 &&
    bytes[3] == 0x46;

void main() {
  final fonts = loadTestFonts();
  final shop = sampleShop().copyWith(gstin: '06AAPFU0939F1ZV');

  test('builds a statement PDF', () async {
    final bytes = await buildStatementPdf(
      shop: shop,
      customer: sampleCustomer(gstin: '07AAPFU0939F1ZV'),
      statement: buildStatement(ledger: fixture.makeLedger()),
      fonts: fonts,
    );
    expect(isPdf(bytes), isTrue);
  });

  test('builds for a period with no entries', () async {
    final bytes = await buildStatementPdf(
      shop: shop,
      customer: sampleCustomer(),
      statement: buildStatement(
        ledger: fixture.makeLedger(),
        from: DateTime(2026, 7, 1),
        to: DateTime(2026, 7, 31),
      ),
      fonts: fonts,
    );
    expect(isPdf(bytes), isTrue);
  });

  test('builds for an empty ledger', () async {
    final bytes = await buildStatementPdf(
      shop: shop,
      customer: sampleCustomer(),
      statement: buildStatement(
        ledger: const CustomerLedger(invoices: [], payments: [], receipts: []),
      ),
      fonts: fonts,
    );
    expect(isPdf(bytes), isTrue);
  });

  test('a long statement flows onto extra pages', () async {
    final invoices = [
      for (var n = 1; n <= 120; n++)
        sampleOpenInvoice(
          id: 'i$n',
          number: 'INV-${n.toString().padLeft(4, '0')}',
          total: 1000 + n,
          issuedAt: DateTime(2026, 1, 1).add(Duration(days: n)),
        ),
    ];
    final bytes = await buildStatementPdf(
      shop: shop,
      customer: sampleCustomer(),
      statement: buildStatement(
        ledger: CustomerLedger(
          invoices: invoices,
          payments: const [],
          receipts: const [],
        ),
      ),
      fonts: fonts,
    );
    expect(isPdf(bytes), isTrue);
  });
}
