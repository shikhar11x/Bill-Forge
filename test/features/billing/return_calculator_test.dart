import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/billing/domain/credit_note.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/return_calculator.dart';
import 'package:billforge/features/products/domain/product_unit.dart';

import '../../support/payment_fakes.dart';

InvoiceItem item({
  String id = 'it1',
  int qty = 4000,
  int taxable = 40000,
  int cgst = 1000,
  int sgst = 1000,
  int igst = 0,
}) => InvoiceItem(
  id: id,
  invoiceId: 'inv',
  position: 0,
  productId: 'p1',
  name: 'Rice',
  unit: ProductUnit.piece,
  qtyMilli: qty,
  unitPricePaise: 10000,
  gstRatePercent: 5,
  discountPaise: 0,
  taxablePaise: taxable,
  cgstPaise: cgst,
  sgstPaise: sgst,
  igstPaise: igst,
  totalPaise: taxable + cgst + sgst + igst,
);

CreditNoteItem returned({
  String itemId = 'it1',
  int qty = 1000,
  int taxable = 10000,
  int cgst = 250,
  int sgst = 250,
  int igst = 0,
}) => CreditNoteItem(
  id: 'x',
  creditNoteId: 'cn',
  invoiceItemId: itemId,
  position: 0,
  name: 'Rice',
  unit: ProductUnit.piece,
  qtyMilli: qty,
  unitPricePaise: 10000,
  gstRatePercent: 5,
  taxablePaise: taxable,
  cgstPaise: cgst,
  sgstPaise: sgst,
  igstPaise: igst,
  totalPaise: taxable + cgst + sgst + igst,
);

Invoice invoice({int grand = 42000, int credited = 0, int paid = 42000}) =>
    sampleOpenInvoice(
      total: grand,
      paid: paid,
    ).copyWith(creditedPaise: credited);

void main() {
  group('mulDivRound', () {
    test('rounds half up', () {
      expect(mulDivRound(1, 1, 2), 1);
      expect(mulDivRound(1, 1, 3), 0);
      expect(mulDivRound(2, 1, 3), 1);
      expect(mulDivRound(5, 1, 2), 3);
    });

    test('stays exact for the largest amounts', () {
      expect(mulDivRound(999999999999, 9999999, 9999999), 999999999999);
      expect(mulDivRound(999999999999, 9999999, 19999998), 500000000000);
    });
  });

  group('returnableLines', () {
    test('everything is returnable when nothing was returned', () {
      final lines = returnableLines([item()], const []);
      expect(lines.single.remainingQtyMilli, 4000);
      expect(lines.single.totalPaise, 42000);
      expect(lines.single.canReturn, isTrue);
    });

    test('earlier credit notes are taken off', () {
      final lines = returnableLines([item()], [returned()]);
      expect(lines.single.remainingQtyMilli, 3000);
      expect(lines.single.taxablePaise, 30000);
      expect(lines.single.cgstPaise, 750);
      expect(lines.single.totalPaise, 31500);
    });

    test('a fully returned line cannot be returned again', () {
      final lines = returnableLines(
        [item()],
        [returned(qty: 4000, taxable: 40000, cgst: 1000, sgst: 1000)],
      );
      expect(lines.single.canReturn, isFalse);
      expect(lines.single.totalPaise, 0);
    });
  });

  group('planReturn', () {
    test('a partial return credits the tax in proportion', () {
      final outcome = planReturn(
        invoice: invoice(),
        lines: returnableLines([item()], const []),
        qtyByItemId: {'it1': 1000},
      );
      final plan = outcome.plan!;
      expect(plan.taxablePaise, 10000);
      expect(plan.cgstPaise, 250);
      expect(plan.sgstPaise, 250);
      expect(plan.subtotalPaise, 10500);
      expect(plan.totalPaise, 10500);
      expect(plan.roundOffPaise, 0);
      expect(plan.returnsEverything, isFalse);
    });

    test('inter-state tax is credited as IGST', () {
      final plan = planReturn(
        invoice: invoice(),
        lines: returnableLines([item(cgst: 0, sgst: 0, igst: 2000)], const []),
        qtyByItemId: {'it1': 1000},
      ).plan!;
      expect(plan.igstPaise, 500);
      expect(plan.cgstPaise, 0);
    });

    test('a partial credit note is rounded to the rupee', () {
      final plan = planReturn(
        invoice: invoice(grand: 10000, paid: 10000),
        lines: returnableLines([
          item(qty: 3000, taxable: 10000, cgst: 0, sgst: 0),
        ], const []),
        qtyByItemId: {'it1': 1000},
      ).plan!;
      expect(plan.subtotalPaise, 3333);
      expect(plan.totalPaise, 3300);
      expect(plan.roundOffPaise, -33);
    });

    test('returning everything credits the whole invoice total', () {
      final plan = planReturn(
        invoice: invoice(grand: 42000),
        lines: returnableLines([item()], const []),
        qtyByItemId: {'it1': 4000},
      ).plan!;
      expect(plan.returnsEverything, isTrue);
      expect(plan.totalPaise, 42000);
      expect(plan.roundOffPaise, 0);
    });

    test('the final return takes exactly what is left, undoing round-off', () {
      // ₹100.00 invoice, 3 units. First return of 1 unit was credited ₹33.00.
      final item3 = item(qty: 3000, taxable: 10000, cgst: 0, sgst: 0);
      final firstNote = returned(qty: 1000, taxable: 3333, cgst: 0, sgst: 0);
      final plan = planReturn(
        invoice: invoice(grand: 10000, credited: 3300, paid: 6700),
        lines: returnableLines([item3], [firstNote]),
        qtyByItemId: {'it1': 2000},
      ).plan!;

      expect(plan.subtotalPaise, 6667);
      expect(plan.returnsEverything, isTrue);
      expect(plan.totalPaise, 6700); // 10000 - 3300
      expect(plan.roundOffPaise, 33);
    });

    test('rounding never credits more than what is left', () {
      final plan = planReturn(
        invoice: invoice(grand: 10000, credited: 9980, paid: 0),
        lines: returnableLines(
          [item(qty: 2000, taxable: 100, cgst: 0, sgst: 0)],
          [returned(qty: 1000, taxable: 50, cgst: 0, sgst: 0)],
        ),
        qtyByItemId: {'it1': 500},
      ).plan!;
      expect(plan.totalPaise, lessThanOrEqualTo(20));
    });

    test('rejects an empty selection', () {
      final outcome = planReturn(
        invoice: invoice(),
        lines: returnableLines([item()], const []),
        qtyByItemId: const {},
      );
      expect(outcome.plan, isNull);
      expect(outcome.error, 'Select at least one item to return.');
    });

    test('rejects more than is left on a line', () {
      final outcome = planReturn(
        invoice: invoice(),
        lines: returnableLines([item()], [returned()]),
        qtyByItemId: {'it1': 4000},
      );
      expect(outcome.error, contains('Only 3 pcs'));
    });

    test('rejects a line that was already fully returned', () {
      final outcome = planReturn(
        invoice: invoice(),
        lines: returnableLines(
          [item()],
          [returned(qty: 4000, taxable: 40000, cgst: 1000, sgst: 1000)],
        ),
        qtyByItemId: {'it1': 1000},
      );
      expect(outcome.error, contains('already been fully returned'));
    });

    test('with two lines, returning one is not "everything"', () {
      final lines = returnableLines([item(id: 'a'), item(id: 'b')], const []);
      final plan = planReturn(
        invoice: invoice(grand: 84000),
        lines: lines,
        qtyByItemId: {'a': 4000},
      ).plan!;
      expect(plan.returnsEverything, isFalse);

      final all = planReturn(
        invoice: invoice(grand: 84000),
        lines: lines,
        qtyByItemId: selectAllRemaining(lines),
      ).plan!;
      expect(all.returnsEverything, isTrue);
      expect(all.totalPaise, 84000);
    });
  });

  group('settleCreditNote', () {
    test('a paid invoice is refunded in full', () {
      final s = settleCreditNote(totalPaise: 5000, invoiceDuePaise: 0);
      expect(s.appliedPaise, 0);
      expect(s.refundPaise, 5000);
    });

    test('an unpaid invoice just reduces the balance', () {
      final s = settleCreditNote(totalPaise: 5000, invoiceDuePaise: 20000);
      expect(s.appliedPaise, 5000);
      expect(s.refundPaise, 0);
    });

    test('a credit bigger than the balance clears it and refunds the rest', () {
      final s = settleCreditNote(totalPaise: 5000, invoiceDuePaise: 3000);
      expect(s.appliedPaise, 3000);
      expect(s.refundPaise, 2000);
    });

    test('a negative due is treated as nothing owed', () {
      final s = settleCreditNote(totalPaise: 5000, invoiceDuePaise: -100);
      expect(s.appliedPaise, 0);
      expect(s.refundPaise, 5000);
    });
  });

  test('the invoice stays consistent after a settled return', () {
    // ₹875.00 still owed on a ₹1,275.00 invoice (₹400.00 paid), full return.
    final inv = invoice(grand: 127500, paid: 40000);
    final s = settleCreditNote(
      totalPaise: 127500,
      invoiceDuePaise: inv.duePaise,
    );
    final after = inv.copyWith(
      creditedPaise: inv.creditedPaise + 127500,
      paidPaise: inv.paidPaise - s.refundPaise,
    );
    expect(s.appliedPaise, 87500);
    expect(s.refundPaise, 40000);
    expect(after.duePaise, 0);
    expect(after.paidPaise, 0);
  });
}
