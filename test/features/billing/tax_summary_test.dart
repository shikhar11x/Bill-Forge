import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/tax_summary.dart';
import 'package:billforge/features/products/domain/product_unit.dart';

InvoiceItem item(
  String id, {
  String? hsn,
  int rate = 5,
  int taxable = 10000,
  int cgst = 250,
  int sgst = 250,
  int igst = 0,
}) =>
    InvoiceItem(
      id: id,
      invoiceId: 'i',
      position: 0,
      name: id,
      hsnCode: hsn,
      unit: ProductUnit.piece,
      qtyMilli: 1000,
      unitPricePaise: taxable,
      gstRatePercent: rate,
      discountPaise: 0,
      taxablePaise: taxable,
      cgstPaise: cgst,
      sgstPaise: sgst,
      igstPaise: igst,
      totalPaise: taxable + cgst + sgst + igst,
    );

void main() {
  test('groups by HSN and rate and sums amounts', () {
    final rows = buildTaxSummary([
      item('a', hsn: '1006'),
      item('b', hsn: '1006', taxable: 20000, cgst: 500, sgst: 500),
      item('c', hsn: '1905', rate: 18, taxable: 10000, cgst: 900, sgst: 900),
    ]);

    expect(rows, hasLength(2));
    expect(rows[0].hsnCode, '1006');
    expect(rows[0].taxablePaise, 30000);
    expect(rows[0].cgstPaise, 750);
    expect(rows[0].sgstPaise, 750);
    expect(rows[0].taxPaise, 1500);
    expect(rows[1].hsnCode, '1905');
    expect(rows[1].ratePercent, 18);
  });

  test('the same HSN at different rates stays separate', () {
    final rows = buildTaxSummary([
      item('a', hsn: '1006'),
      item('b', hsn: '1006', rate: 12, cgst: 600, sgst: 600),
    ]);
    expect(rows.map((r) => r.ratePercent), [5, 12]);
  });

  test('items without an HSN code group together', () {
    final rows = buildTaxSummary([item('a'), item('b')]);
    expect(rows, hasLength(1));
    expect(rows.single.hsnCode, '');
    expect(rows.single.taxablePaise, 20000);
  });

  test('inter-state items keep IGST', () {
    final rows = buildTaxSummary([item('a', cgst: 0, sgst: 0, igst: 500)]);
    expect(rows.single.igstPaise, 500);
    expect(rows.single.taxPaise, 500);
  });

  test('grouped taxable values add up to the total', () {
    final items = [
      item('a', hsn: '1', taxable: 12345),
      item('b', hsn: '2', rate: 12, taxable: 6789),
      item('c', hsn: '1', taxable: 1111),
    ];
    final total = buildTaxSummary(items).fold<int>(0, (s, r) => s + r.taxablePaise);
    expect(total, 12345 + 6789 + 1111);
  });
}