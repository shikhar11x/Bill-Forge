import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/billing/data/pdf/credit_note_pdf_builder.dart';

import '../../support/credit_note_fakes.dart';
import '../../support/fakes.dart';
import '../../support/pdf_test_fonts.dart';

void main() {
  final fonts = loadTestFonts();

  bool isPdf(List<int> bytes) =>
      bytes.length > 4 && String.fromCharCodes(bytes.take(4)) == '%PDF';

  test('builds a credit note PDF for a refund', () async {
    final bytes = await buildCreditNotePdf(
      shop: sampleShop().copyWith(gstin: '06AAPFU0939F1ZV'),
      detail: sampleCreditNoteDetail(),
      fonts: fonts,
    );
    expect(isPdf(bytes), isTrue);
  });

  test('builds when the credit only reduced the balance', () async {
    final bytes = await buildCreditNotePdf(
      shop: sampleShop(),
      detail: sampleCreditNoteDetail(applied: 45000, refund: 0),
      fonts: fonts,
    );
    expect(isPdf(bytes), isTrue);
  });
}
