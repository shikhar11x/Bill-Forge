import 'package:billforge/features/billing/domain/invoice.dart';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _utcDay(DateTime d) => DateTime.utc(d.year, d.month, d.day);

DateTime _issued(Invoice i) => i.issuedAt ?? i.createdAt;

/// Overdue means a due date before today (an invoice due today is not yet
/// overdue) and money still owed.
bool isOverdue(Invoice invoice, DateTime now) {
  final due = invoice.dueDate;
  if (due == null || invoice.duePaise <= 0) return false;
  return _day(due).isBefore(_day(now));
}

int daysOverdue(Invoice invoice, DateTime now) => isOverdue(invoice, now)
    ? _utcDay(now).difference(_utcDay(invoice.dueDate!)).inDays
    : 0;

class OutstandingEntry {
  const OutstandingEntry({
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.openInvoices,
    required this.outstandingPaise,
    required this.overduePaise,
    required this.oldestIssuedAt,
  });

  final String customerId;
  final String customerName;
  final String? customerPhone;
  final int openInvoices;
  final int outstandingPaise;
  final int overduePaise;
  final DateTime oldestIssuedAt;
}

class OutstandingReport {
  const OutstandingReport({
    required this.entries,
    required this.totalPaise,
    required this.overduePaise,
  });

  static const empty = OutstandingReport(
    entries: [],
    totalPaise: 0,
    overduePaise: 0,
  );

  /// Largest balance first.
  final List<OutstandingEntry> entries;
  final int totalPaise;
  final int overduePaise;
}

/// Groups open invoices by customer. Invoices without a customer, drafts and
/// fully paid invoices are ignored. Name and phone come from the newest
/// invoice's snapshot.
OutstandingReport buildOutstandingReport(
  List<Invoice> openInvoices, {
  required DateTime now,
}) {
  final byCustomer = <String, List<Invoice>>{};
  for (final invoice in openInvoices) {
    final id = invoice.customerId;
    if (id == null || invoice.isDraft || invoice.duePaise <= 0) continue;
    byCustomer.putIfAbsent(id, () => []).add(invoice);
  }

  final entries = <OutstandingEntry>[];
  for (final group in byCustomer.entries) {
    final invoices = [...group.value]
      ..sort((a, b) => _issued(a).compareTo(_issued(b)));
    final latest = invoices.last;
    entries.add(
      OutstandingEntry(
        customerId: group.key,
        customerName: latest.customerName ?? 'Customer',
        customerPhone: latest.customerPhone,
        openInvoices: invoices.length,
        outstandingPaise: invoices.fold<int>(0, (s, i) => s + i.duePaise),
        overduePaise: invoices
            .where((i) => isOverdue(i, now))
            .fold<int>(0, (s, i) => s + i.duePaise),
        oldestIssuedAt: _issued(invoices.first),
      ),
    );
  }

  entries.sort((a, b) {
    final byAmount = b.outstandingPaise.compareTo(a.outstandingPaise);
    return byAmount != 0
        ? byAmount
        : a.customerName.toLowerCase().compareTo(b.customerName.toLowerCase());
  });

  return OutstandingReport(
    entries: entries,
    totalPaise: entries.fold<int>(0, (s, e) => s + e.outstandingPaise),
    overduePaise: entries.fold<int>(0, (s, e) => s + e.overduePaise),
  );
}
