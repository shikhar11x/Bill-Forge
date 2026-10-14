import 'package:billforge/core/utils/date_format.dart';
import 'package:billforge/features/payments/domain/customer_ledger.dart';

class StatementEntry {
  const StatementEntry({
    required this.date,
    required this.particulars,
    required this.debitPaise,
    required this.creditPaise,
    required this.balancePaise,
    this.invoiceId,
  });

  final DateTime date;
  final String particulars;

  /// Amount billed (increases what is owed).
  final int debitPaise;

  /// Amount received (reduces what is owed).
  final int creditPaise;

  /// Running balance after this entry.
  final int balancePaise;
  final String? invoiceId;
}

class Statement {
  const Statement({
    this.from,
    this.to,
    required this.openingPaise,
    required this.entries,
  });

  final DateTime? from;
  final DateTime? to;
  final int openingPaise;
  final List<StatementEntry> entries;

  int get billedPaise => entries.fold<int>(0, (s, e) => s + e.debitPaise);
  int get receivedPaise => entries.fold<int>(0, (s, e) => s + e.creditPaise);
  int get closingPaise =>
      entries.isEmpty ? openingPaise : entries.last.balancePaise;
}

enum StatementPeriod {
  all('All time'),
  thisMonth('This month'),
  last30Days('Last 30 days');

  const StatementPeriod(this.label);

  final String label;

  (DateTime?, DateTime?) range(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      StatementPeriod.all => (null, null),
      StatementPeriod.thisMonth => (DateTime(now.year, now.month, 1), today),
      StatementPeriod.last30Days => (
          DateTime(now.year, now.month, now.day - 29),
          today,
        ),
    };
  }
}

String statementPeriodLabel(Statement statement) {
  final from = statement.from;
  final to = statement.to;
  if (from == null || to == null) return 'All transactions';
  return '${formatDate(from)} to ${formatDate(to)}';
}

class _Raw {
  const _Raw({
    required this.date,
    required this.order,
    required this.key,
    required this.particulars,
    required this.debit,
    required this.credit,
    this.invoiceId,
  });

  final DateTime date;

  /// On the same instant: invoices first, then sale payments, then receipts.
  final int order;
  final String key;
  final String particulars;
  final int debit;
  final int credit;
  final String? invoiceId;
}

/// Builds a running-balance statement. [from] and [to] are whole days
/// (inclusive); entries before [from] only feed the opening balance.
Statement buildStatement({
  required CustomerLedger ledger,
  DateTime? from,
  DateTime? to,
}) {
  final numberById = {
    for (final i in ledger.invoices) i.id: i.invoiceNumber ?? 'Bill',
  };

  final raw = <_Raw>[
    for (final i in ledger.invoices)
      _Raw(
        date: i.issuedAt ?? i.createdAt,
        order: 0,
        key: i.id,
        particulars: 'Invoice ${i.invoiceNumber ?? ''}'.trim(),
        debit: i.grandTotalPaise,
        credit: 0,
        invoiceId: i.id,
      ),
    for (final p in ledger.payments)
      // Allocations of a receipt are shown through the receipt itself.
      if (p.receiptId == null)
        _Raw(
          date: p.paidAt,
          order: 1,
          key: p.id,
          particulars:
              'Paid at sale · ${p.method.label} (${numberById[p.invoiceId] ?? 'invoice'})',
          debit: 0,
          credit: p.amountPaise,
          invoiceId: p.invoiceId,
        ),
    for (final r in ledger.receipts)
      _Raw(
        date: r.receivedAt,
        order: 2,
        key: r.id,
        particulars:
            'Payment received · ${r.method.label}${r.note == null ? '' : ' (${r.note})'}',
        debit: 0,
        credit: r.amountPaise,
      ),
  ]..sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      final byOrder = a.order.compareTo(b.order);
      return byOrder != 0 ? byOrder : a.key.compareTo(b.key);
    });

  final start = from == null ? null : DateTime(from.year, from.month, from.day);
  final endExclusive =
      to == null ? null : DateTime(to.year, to.month, to.day + 1);

  var running = 0;
  var opening = 0;
  final entries = <StatementEntry>[];
  for (final r in raw) {
    if (endExclusive != null && !r.date.isBefore(endExclusive)) break;
    running += r.debit - r.credit;
    if (start != null && r.date.isBefore(start)) {
      opening = running;
      continue;
    }
    entries.add(
      StatementEntry(
        date: r.date,
        particulars: r.particulars,
        debitPaise: r.debit,
        creditPaise: r.credit,
        balancePaise: running,
        invoiceId: r.invoiceId,
      ),
    );
  }

  return Statement(from: from, to: to, openingPaise: opening, entries: entries);
}