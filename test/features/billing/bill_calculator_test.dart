import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/billing/domain/bill_calculator.dart';
import 'package:billforge/features/billing/domain/cart_line.dart';
import 'package:billforge/features/billing/domain/discount.dart';
import 'package:billforge/features/products/domain/product_unit.dart';

CartLine line({
  int price = 10000,
  int qtyMilli = 1000,
  int gst = 0,
  Discount discount = const Discount.none(),
  ProductUnit unit = ProductUnit.piece,
  String id = 'p',
}) => CartLine(
  productId: id,
  name: id,
  unit: unit,
  unitPricePaise: price,
  qtyMilli: qtyMilli,
  discount: discount,
  gstRatePercent: gst,
  trackStock: false,
  stockMilli: 0,
);

BillTotals bill(
  List<CartLine> lines, {
  Discount billDiscount = const Discount.none(),
  bool interState = false,
  bool inclusive = false,
  bool chargesTax = true,
}) => calculateBill(
  lines: lines,
  billDiscount: billDiscount,
  interState: interState,
  pricesIncludeTax: inclusive,
  chargesTax: chargesTax,
);

void main() {
  test('empty bill is zero', () {
    final t = bill([]);
    expect(t.grandTotalPaise, 0);
    expect(t.roundOffPaise, 0);
  });

  group('tax-exclusive prices', () {
    test('adds GST on top and splits it CGST/SGST', () {
      final t = bill([line(price: 10000, qtyMilli: 2000, gst: 18)]);
      expect(t.taxablePaise, 20000);
      expect(t.cgstPaise, 1800);
      expect(t.sgstPaise, 1800);
      expect(t.igstPaise, 0);
      expect(t.grandTotalPaise, 23600);
      expect(t.roundOffPaise, 0);
    });

    test('inter-state supplies attract IGST only', () {
      final t = bill([line(gst: 18)], interState: true);
      expect(t.igstPaise, 1800);
      expect(t.cgstPaise, 0);
      expect(t.sgstPaise, 0);
      expect(t.grandTotalPaise, 11800);
    });

    test('an odd tax paisa goes to SGST, then the total rounds to rupees', () {
      final t = bill([line(price: 1010, gst: 5)]);
      expect(t.taxPaise, 51);
      expect(t.cgstPaise, 25);
      expect(t.sgstPaise, 26);
      expect(t.subtotalPaise, 1061);
      expect(t.roundOffPaise, 39);
      expect(t.grandTotalPaise, 1100);
    });
  });

  group('tax-inclusive prices', () {
    test('backs GST out of the price', () {
      final t = bill([line(price: 11800, gst: 18)], inclusive: true);
      expect(t.taxablePaise, 10000);
      expect(t.cgstPaise, 900);
      expect(t.sgstPaise, 900);
      expect(t.grandTotalPaise, 11800);
    });

    test('works for 5%', () {
      final t = bill([line(price: 10500, gst: 5)], inclusive: true);
      expect(t.taxablePaise, 10000);
      expect(t.taxPaise, 500);
      expect(t.grandTotalPaise, 10500);
    });
  });

  group('non-taxpayers', () {
    test('charge no GST even if the product has a rate', () {
      final t = bill([line(gst: 18)], chargesTax: false);
      expect(t.taxPaise, 0);
      expect(t.grandTotalPaise, 10000);
    });

    test('zero-rated items carry no tax', () {
      final t = bill([line(gst: 0)]);
      expect(t.taxPaise, 0);
    });
  });

  group('quantity and rounding', () {
    test('fractional quantities', () {
      final t = bill([
        line(price: 12000, qtyMilli: 2500, unit: ProductUnit.kilogram),
      ]);
      expect(t.lines.single.grossPaise, 30000);
    });

    test('gross rounds half up', () {
      final t = bill([line(price: 333, qtyMilli: 1500)]);
      expect(t.lines.single.grossPaise, 500);
    });

    test('round-off goes down below 50 paise and up from 50', () {
      expect(bill([line(price: 10049)]).roundOffPaise, -49);
      expect(bill([line(price: 10049)]).grandTotalPaise, 10000);
      expect(bill([line(price: 10050)]).roundOffPaise, 50);
      expect(bill([line(price: 10050)]).grandTotalPaise, 10100);
    });
  });

  group('discounts', () {
    test('line percent discount', () {
      final t = bill([
        line(
          price: 20000,
          discount: const Discount(DiscountType.percent, 1000),
        ),
      ]);
      expect(t.lines.single.lineDiscountPaise, 2000);
      expect(t.grandTotalPaise, 18000);
    });

    test('a line discount cannot exceed the line', () {
      final t = bill([
        line(
          price: 20000,
          discount: const Discount(DiscountType.amount, 50000),
        ),
      ]);
      expect(t.lines.single.lineDiscountPaise, 20000);
      expect(t.grandTotalPaise, 0);
    });

    test('discount reduces the taxable value', () {
      final t = bill([
        line(
          price: 10000,
          gst: 18,
          discount: const Discount(DiscountType.amount, 1000),
        ),
      ]);
      expect(t.taxablePaise, 9000);
      expect(t.taxPaise, 1620);
      expect(t.grandTotalPaise, 10620);
    });

    test('bill discount is shared in proportion and sums exactly', () {
      final t = bill([
        line(price: 10000, id: 'a'),
        line(price: 30000, id: 'b'),
      ], billDiscount: const Discount(DiscountType.amount, 1001));
      expect(t.billDiscountPaise, 1001);
      expect(t.lines[0].billDiscountPaise, 250);
      expect(t.lines[1].billDiscountPaise, 751);
      expect(t.discountPaise, 1001);
      expect(t.grandTotalPaise, 38999 + 1); // 38999 rounds to 39000
    });

    test('percent bill discount applies after line discounts', () {
      final t = bill([
        line(price: 20000, discount: const Discount(DiscountType.amount, 5000)),
      ], billDiscount: const Discount(DiscountType.percent, 1000));
      expect(t.discountableBasePaise, 15000);
      expect(t.billDiscountPaise, 1500);
      expect(t.grandTotalPaise, 13500);
    });

    test('a bill discount cannot exceed what is left to discount', () {
      final t = bill([
        line(price: 10000),
      ], billDiscount: const Discount(DiscountType.amount, 999999));
      expect(t.billDiscountPaise, 10000);
      expect(t.grandTotalPaise, 0);
    });
  });

  test('totals always reconcile: taxable + tax = subtotal', () {
    final combos = [
      (inclusive: true, interState: false),
      (inclusive: false, interState: false),
      (inclusive: true, interState: true),
      (inclusive: false, interState: true),
    ];
    for (final c in combos) {
      final t = bill(
        [
          line(price: 1999, qtyMilli: 3000, gst: 18, id: 'a'),
          line(price: 4950, qtyMilli: 1500, gst: 5, id: 'b'),
          line(price: 777, qtyMilli: 7000, gst: 12, id: 'c'),
        ],
        billDiscount: const Discount(DiscountType.amount, 1234),
        inclusive: c.inclusive,
        interState: c.interState,
      );
      expect(
        t.taxablePaise + t.taxPaise,
        t.subtotalPaise,
        reason: 'inclusive=${c.inclusive}, interState=${c.interState}',
      );
      expect(t.grandTotalPaise % 100, 0);
    }
  });
}
