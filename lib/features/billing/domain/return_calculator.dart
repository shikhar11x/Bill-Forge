import 'package:billforge/core/utils/quantity.dart';
import 'package:billforge/features/billing/domain/bill_calculator.dart'
    show roundHalfUpDiv;
import 'package:billforge/features/billing/domain/credit_note.dart';
import 'package:billforge/features/billing/domain/invoice.dart';

/// (a x b) / c rounded half up. Uses BigInt because a line amount (up to about
/// 10^12 paise) times a quantity (up to 10^7) does not fit exactly in 64-bit or
/// web numbers.
int mulDivRound(int a, int b, int c) {
  final two = BigInt.from(2);
  final numerator = BigInt.from(a) * BigInt.from(b);
  final denominator = BigInt.from(c);
  return ((numerator * two + denominator) ~/ (denominator * two)).toInt();
}

/// One invoice line with what is still returnable.
class ReturnableLine {
  const ReturnableLine({
    required this.item,
    required this.remainingQtyMilli,
    required this.taxablePaise,
    required this.cgstPaise,
    required this.sgstPaise,
    required this.igstPaise,
    required this.totalPaise,
  });

  final InvoiceItem item;
  final int remainingQtyMilli;

  /// Remaining (not yet credited) amounts of the line.
  final int taxablePaise;
  final int cgstPaise;
  final int sgstPaise;
  final int igstPaise;
  final int totalPaise;

  bool get canReturn => remainingQtyMilli > 0;
}

/// Invoice lines minus whatever earlier credit notes already took back.
List<ReturnableLine> returnableLines(
  List<InvoiceItem> items,
  List<CreditNoteItem> previous,
) {
  final byItem = <String, List<CreditNoteItem>>{};
  for (final p in previous) {
    byItem.putIfAbsent(p.invoiceItemId, () => []).add(p);
  }

  int left(int original, Iterable<int> used) {
    final remaining = original - used.fold<int>(0, (s, v) => s + v);
    return remaining > 0 ? remaining : 0;
  }

  final lines = <ReturnableLine>[];
  for (final item in items) {
    final used = byItem[item.id] ?? const <CreditNoteItem>[];
    lines.add(
      ReturnableLine(
        item: item,
        remainingQtyMilli: left(item.qtyMilli, used.map((u) => u.qtyMilli)),
        taxablePaise: left(item.taxablePaise, used.map((u) => u.taxablePaise)),
        cgstPaise: left(item.cgstPaise, used.map((u) => u.cgstPaise)),
        sgstPaise: left(item.sgstPaise, used.map((u) => u.sgstPaise)),
        igstPaise: left(item.igstPaise, used.map((u) => u.igstPaise)),
        totalPaise: left(item.totalPaise, used.map((u) => u.totalPaise)),
      ),
    );
  }
  return lines;
}

/// Quantity (thousandths) for every line that can still be returned.
Map<String, int> selectAllRemaining(List<ReturnableLine> lines) => {
  for (final l in lines)
    if (l.canReturn) l.item.id: l.remainingQtyMilli,
};

class ReturnLinePlan {
  const ReturnLinePlan({
    required this.line,
    required this.qtyMilli,
    required this.taxablePaise,
    required this.cgstPaise,
    required this.sgstPaise,
    required this.igstPaise,
    required this.totalPaise,
  });

  final ReturnableLine line;
  final int qtyMilli;
  final int taxablePaise;
  final int cgstPaise;
  final int sgstPaise;
  final int igstPaise;
  final int totalPaise;
}

class ReturnPlan {
  const ReturnPlan({
    required this.lines,
    required this.subtotalPaise,
    required this.totalPaise,
    required this.roundOffPaise,
    required this.returnsEverything,
  });

  final List<ReturnLinePlan> lines;

  /// Sum of the line totals, before rounding.
  final int subtotalPaise;

  /// The credit note value.
  final int totalPaise;
  final int roundOffPaise;

  /// True when nothing is left to return on the invoice afterwards.
  final bool returnsEverything;

  int _sum(int Function(ReturnLinePlan l) pick) =>
      lines.fold<int>(0, (s, l) => s + pick(l));

  int get taxablePaise => _sum((l) => l.taxablePaise);
  int get cgstPaise => _sum((l) => l.cgstPaise);
  int get sgstPaise => _sum((l) => l.sgstPaise);
  int get igstPaise => _sum((l) => l.igstPaise);
}

class ReturnOutcome {
  const ReturnOutcome.ok(ReturnPlan this.plan) : error = null;
  const ReturnOutcome.failed(String this.error) : plan = null;

  final ReturnPlan? plan;
  final String? error;
}

/// Works out a credit note for the chosen quantities.
///
/// Each line is credited in proportion to the original; returning everything
/// that is left on a line takes the exact remainder, so repeated returns can
/// never add up to more or less than the invoice. A partial credit note is
/// rounded to the nearest rupee; the one that clears the whole invoice takes
/// exactly what is still creditable, which reverses the invoice round-off.
ReturnOutcome planReturn({
  required Invoice invoice,
  required List<ReturnableLine> lines,
  required Map<String, int> qtyByItemId,
}) {
  final chosen = <ReturnLinePlan>[];
  var everything = true;

  for (final line in lines) {
    final qty = qtyByItemId[line.item.id] ?? 0;
    if (qty <= 0) {
      if (line.canReturn) everything = false;
      continue;
    }
    if (qty > line.remainingQtyMilli) {
      return ReturnOutcome.failed(
        line.canReturn
            ? 'Only ${formatMilli(line.remainingQtyMilli)} ${line.item.unit.symbol} of "${line.item.name}" can be returned.'
            : '"${line.item.name}" has already been fully returned.',
      );
    }

    final full = qty == line.remainingQtyMilli;
    if (!full) everything = false;
    int part(int remaining) =>
        full ? remaining : mulDivRound(remaining, qty, line.remainingQtyMilli);

    chosen.add(
      ReturnLinePlan(
        line: line,
        qtyMilli: qty,
        taxablePaise: part(line.taxablePaise),
        cgstPaise: part(line.cgstPaise),
        sgstPaise: part(line.sgstPaise),
        igstPaise: part(line.igstPaise),
        totalPaise: part(line.totalPaise),
      ),
    );
  }

  if (chosen.isEmpty) {
    return const ReturnOutcome.failed('Select at least one item to return.');
  }

  final subtotal = chosen.fold<int>(0, (s, l) => s + l.totalPaise);
  final creditable = invoice.grandTotalPaise - invoice.creditedPaise;

  int total;
  if (everything) {
    total = creditable;
  } else {
    final rounded = roundHalfUpDiv(subtotal, 100) * 100;
    total = rounded > creditable ? creditable : rounded;
  }
  if (total < 0) total = 0;

  return ReturnOutcome.ok(
    ReturnPlan(
      lines: chosen,
      subtotalPaise: subtotal,
      totalPaise: total,
      roundOffPaise: total - subtotal,
      returnsEverything: everything,
    ),
  );
}

class Settlement {
  const Settlement({required this.appliedPaise, required this.refundPaise});

  /// Reduces what the customer still owes on the invoice.
  final int appliedPaise;

  /// Paid back to the customer.
  final int refundPaise;
}

/// A credit first clears what the invoice still owes; the rest is refunded.
Settlement settleCreditNote({
  required int totalPaise,
  required int invoiceDuePaise,
}) {
  final open = invoiceDuePaise < 0 ? 0 : invoiceDuePaise;
  final applied = totalPaise < open ? totalPaise : open;
  return Settlement(appliedPaise: applied, refundPaise: totalPaise - applied);
}
