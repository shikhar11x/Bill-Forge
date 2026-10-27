import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/reports/domain/gst_report.dart';
import 'package:billforge/features/reports/domain/report_data.dart';
import 'package:billforge/features/reports/domain/report_range.dart';

import '../../support/credit_note_fakes.dart';
import '../../support/payment_fakes.dart';
import '../../support/report_fakes.dart';

void main() {
  final range = ReportRange.between(
    DateTime(2026, 6, 1),
    DateTime(2026, 6, 30),
  );

  final data = ReportData(
    invoices: [
      sampleOpenInvoice(
        id: 'a',
        total: 164000,
      ).copyWith(taxablePaise: 150000, cgstPaise: 7000, sgstPaise: 7000),
    ],
    invoiceItems: [
      rItem(
        id: 'i1',
        hsn: '1006',
        rate: 5,
        taxable: 100000,
        cgst: 2500,
        sgst: 2500,
      ),
      rItem(
        id: 'i2',
        productId: 'p2',
        hsn: '1905',
        rate: 18,
        taxable: 50000,
        cgst: 4500,
        sgst: 4500,
      ),
    ],
    creditNotes: [
      sampleCreditNote(
        total: 21000,
        refund: 21000,
      ).copyWith(taxablePaise: 20000, cgstPaise: 500, sgstPaise: 500),
    ],
    creditNoteItems: [
      rCnItem(hsn: '1006', rate: 5, taxable: 20000, cgst: 500, sgst: 500),
    ],
  );

  final doc = buildGstDocument(data, range);

  String metric(String label) =>
      doc.metrics.firstWhere((m) => m.label == label).value.text;

  test('summary is net of credit notes', () {
    expect(metric('Taxable value'), '₹1,300.00');
    expect(metric('CGST'), '₹65.00');
    expect(metric('SGST'), '₹65.00');
    expect(metric('IGST'), '₹0.00');
    expect(metric('Net GST'), '₹130.00');
    expect(metric('GST on invoices'), '₹140.00');
    expect(metric('GST on credit notes'), '₹10.00');
  });

  test('by rate', () {
    final rows = doc.sections[0].table.rows;
    expect(rows.map((r) => r.first.text), ['5%', '18%']);
    expect(rows[0].map((r) => r.text), [
      '5%',
      '₹800.00',
      '₹20.00',
      '₹20.00',
      '₹0.00',
      '₹40.00',
    ]);
    expect(rows[1][1].text, '₹500.00');
    expect(doc.sections[0].table.footer!.last.text, '₹130.00');
  });

  test('by HSN keeps each code and rate apart', () {
    final rows = doc.sections[1].table.rows;
    expect(rows.map((r) => r.first.text), ['1006', '1905']);
    expect(rows.map((r) => r[1].text), ['5%', '18%']);
    expect(doc.sections[1].table.footer!.last.text, '₹130.00');
  });

  test('inter-state tax lands in the IGST column', () {
    final inter = buildGstDocument(
      ReportData(
        invoices: [
          sampleOpenInvoice(total: 118000)
              .copyWith(taxablePaise: 100000, igstPaise: 18000),
        ],
        invoiceItems: [
          rItem(hsn: '1905', rate: 18, taxable: 100000, igst: 18000),
        ],
      ),
      range,
    );
    expect(
      inter.metrics.firstWhere((m) => m.label == 'IGST').value.text,
      '₹180.00',
    );
    expect(
      inter.metrics.firstWhere((m) => m.label == 'CGST').value.text,
      '₹0.00',
    );
  });

  test('items without an HSN code show a dash', () {
    final plain = buildGstDocument(
      ReportData(invoiceItems: [rItem(taxable: 1000)]),
      range,
    );
    expect(plain.sections[1].table.rows.single.first.text, '—');
  });

  test('a period with no GST says so', () {
    final none = buildGstDocument(
      ReportData(invoiceItems: [rItem()], invoices: [sampleOpenInvoice()]),
      range,
    );
    expect(none.notes.any((n) => n.contains('No GST was charged')), isTrue);
    expect(doc.notes.any((n) => n.contains('No GST was charged')), isFalse);
  });
}
