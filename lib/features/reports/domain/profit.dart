import 'package:billforge/features/billing/domain/credit_note.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/return_calculator.dart'
    show mulDivRound;

/// Profit before GST: taxable value minus cost, for items whose product has a
/// purchase price. Returns are taken off. Cost uses today's purchase price,
/// so this is an estimate.
class ProfitEstimate {
  const ProfitEstimate({
    required this.profitPaise,
    required this.costedRevenuePaise,
    required this.totalRevenuePaise,
  });

  static const none = ProfitEstimate(
    profitPaise: 0,
    costedRevenuePaise: 0,
    totalRevenuePaise: 0,
  );

  final int profitPaise;

  /// Net taxable sales of products that have a purchase price.
  final int costedRevenuePaise;

  /// Net taxable sales of everything.
  final int totalRevenuePaise;

  bool get hasEstimate => costedRevenuePaise != 0;

  /// Share of sales the estimate covers (0 to 100).
  int get coveragePercent {
    if (totalRevenuePaise <= 0) return 100;
    final percent = costedRevenuePaise * 100 ~/ totalRevenuePaise;
    if (percent < 0) return 0;
    return percent > 100 ? 100 : percent;
  }
}

ProfitEstimate estimateProfit({
  required List<InvoiceItem> items,
  required List<CreditNoteItem> creditItems,
  required Map<String, int> costByProductId,
}) {
  var total = 0;
  var costed = 0;
  var cost = 0;

  void add(String? productId, int qtyMilli, int taxable, int sign) {
    total += sign * taxable;
    final unitCost = productId == null ? null : costByProductId[productId];
    if (unitCost == null) return;
    costed += sign * taxable;
    cost += sign * mulDivRound(qtyMilli, unitCost, 1000);
  }

  for (final i in items) {
    add(i.productId, i.qtyMilli, i.taxablePaise, 1);
  }
  for (final i in creditItems) {
    add(i.productId, i.qtyMilli, i.taxablePaise, -1);
  }

  return ProfitEstimate(
    profitPaise: costed - cost,
    costedRevenuePaise: costed,
    totalRevenuePaise: total,
  );
}
