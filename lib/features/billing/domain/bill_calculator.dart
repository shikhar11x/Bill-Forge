import 'package:billforge/features/billing/domain/cart_line.dart';
import 'package:billforge/features/billing/domain/discount.dart';

/// Round-half-up integer division for non-negative [numerator].
int roundHalfUpDiv(int numerator, int denominator) =>
    (numerator * 2 + denominator) ~/ (denominator * 2);

/// Splits [total] across [weights] in proportion, using the largest-remainder
/// method so the shares add up to exactly [total]. Requires total <= sum.
List<int> allocateProportionally(int total, List<int> weights) {
  final sum = weights.fold<int>(0, (a, b) => a + b);
  if (total <= 0 || sum <= 0) return List.filled(weights.length, 0);

  final shares = <int>[];
  final remainders = <int>[];
  var allocated = 0;
  for (final w in weights) {
    final product = total * w;
    shares.add(product ~/ sum);
    remainders.add(product % sum);
    allocated += product ~/ sum;
  }

  var leftover = total - allocated;
  final order = List<int>.generate(weights.length, (i) => i)
    ..sort((a, b) {
      final byRemainder = remainders[b].compareTo(remainders[a]);
      return byRemainder != 0 ? byRemainder : a.compareTo(b);
    });
  for (final i in order) {
    if (leftover <= 0) break;
    shares[i] += 1;
    leftover--;
  }
  return shares;
}

class LineAmounts {
  const LineAmounts({
    required this.grossPaise,
    required this.lineDiscountPaise,
    required this.billDiscountPaise,
    required this.taxablePaise,
    required this.cgstPaise,
    required this.sgstPaise,
    required this.igstPaise,
    required this.totalPaise,
  });

  /// Unit price x quantity, before any discount.
  final int grossPaise;
  final int lineDiscountPaise;

  /// This line's share of the bill-level discount.
  final int billDiscountPaise;
  final int taxablePaise;
  final int cgstPaise;
  final int sgstPaise;
  final int igstPaise;

  /// What the customer pays for the line (tax included).
  final int totalPaise;

  int get discountPaise => lineDiscountPaise + billDiscountPaise;
  int get taxPaise => cgstPaise + sgstPaise + igstPaise;
}

class BillTotals {
  const BillTotals({
    required this.lines,
    required this.discountableBasePaise,
    required this.billDiscountPaise,
    required this.roundOffPaise,
  });

  static const empty = BillTotals(
    lines: [],
    discountableBasePaise: 0,
    billDiscountPaise: 0,
    roundOffPaise: 0,
  );

  final List<LineAmounts> lines;

  /// Sum of line amounts after line discounts: the most a bill discount can take.
  final int discountableBasePaise;
  final int billDiscountPaise;
  final int roundOffPaise;

  int _sum(int Function(LineAmounts l) pick) =>
      lines.fold<int>(0, (s, l) => s + pick(l));

  int get discountPaise => _sum((l) => l.discountPaise);
  int get taxablePaise => _sum((l) => l.taxablePaise);
  int get cgstPaise => _sum((l) => l.cgstPaise);
  int get sgstPaise => _sum((l) => l.sgstPaise);
  int get igstPaise => _sum((l) => l.igstPaise);
  int get taxPaise => cgstPaise + sgstPaise + igstPaise;

  /// Sum of line totals, before round-off.
  int get subtotalPaise => _sum((l) => l.totalPaise);
  int get grandTotalPaise => subtotalPaise + roundOffPaise;
}

/// Pure billing maths in integer paise.
///
/// Per line: gross = price x qty; line discount; the bill discount is shared
/// out in proportion to what is left; then GST is taken out of (inclusive) or
/// added to (exclusive) the net amount. An odd tax paisa goes to SGST.
/// The grand total is rounded to the nearest rupee (half up).
BillTotals calculateBill({
  required List<CartLine> lines,
  required Discount billDiscount,
  required bool interState,
  required bool pricesIncludeTax,
  required bool chargesTax,
}) {
  final gross = <int>[];
  final lineDiscounts = <int>[];
  for (final line in lines) {
    final g = roundHalfUpDiv(line.unitPricePaise * line.qtyMilli, 1000);
    gross.add(g);
    lineDiscounts.add(line.discount.applyTo(g));
  }

  final afterLine = [
    for (var i = 0; i < lines.length; i++) gross[i] - lineDiscounts[i],
  ];
  final base = afterLine.fold<int>(0, (a, b) => a + b);
  final billDiscountTotal = billDiscount.applyTo(base);
  final shares = allocateProportionally(billDiscountTotal, afterLine);

  final amounts = <LineAmounts>[];
  for (var i = 0; i < lines.length; i++) {
    final net = afterLine[i] - shares[i];
    final rate = chargesTax ? lines[i].gstRatePercent : 0;

    int taxable;
    int tax;
    if (rate == 0) {
      taxable = net;
      tax = 0;
    } else if (pricesIncludeTax) {
      taxable = roundHalfUpDiv(net * 100, 100 + rate);
      tax = net - taxable;
    } else {
      taxable = net;
      tax = roundHalfUpDiv(net * rate, 100);
    }

    final cgst = interState ? 0 : tax ~/ 2;
    final sgst = interState ? 0 : tax - cgst;
    final igst = interState ? tax : 0;

    amounts.add(
      LineAmounts(
        grossPaise: gross[i],
        lineDiscountPaise: lineDiscounts[i],
        billDiscountPaise: shares[i],
        taxablePaise: taxable,
        cgstPaise: cgst,
        sgstPaise: sgst,
        igstPaise: igst,
        totalPaise: pricesIncludeTax ? net : net + tax,
      ),
    );
  }

  final subtotal = amounts.fold<int>(0, (s, l) => s + l.totalPaise);
  final rounded = roundHalfUpDiv(subtotal, 100) * 100;

  return BillTotals(
    lines: amounts,
    discountableBasePaise: base,
    billDiscountPaise: billDiscountTotal,
    roundOffPaise: rounded - subtotal,
  );
}
