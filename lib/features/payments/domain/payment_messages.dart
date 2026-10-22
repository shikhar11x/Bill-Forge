import 'package:billforge/core/utils/date_format.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/payments/domain/outstanding.dart';
import 'package:billforge/features/payments/domain/statement.dart';
import 'package:billforge/features/shop/domain/shop_profile.dart';

/// A friendly WhatsApp reminder listing what is pending, oldest first.
String buildReminderMessage({
  required ShopProfile shop,
  required String customerName,
  required List<Invoice> openInvoices,
  required DateTime now,
  int maxInvoices = 6,
}) {
  final invoices = [...openInvoices]
    ..sort(
      (a, b) =>
          (a.issuedAt ?? a.createdAt).compareTo(b.issuedAt ?? b.createdAt),
    );
  final total = invoices.fold<int>(0, (s, i) => s + i.duePaise);

  final lines = <String>[
    '*${shop.name}*',
    'Payment reminder',
    '',
    'Hello $customerName,',
    'This is a friendly reminder that ${formatPaise(total)} is pending on your account:',
    '',
  ];

  for (final invoice in invoices.take(maxInvoices)) {
    final due = invoice.dueDate;
    final String suffix;
    if (isOverdue(invoice, now)) {
      final days = daysOverdue(invoice, now);
      suffix = ' (overdue by $days day${days == 1 ? '' : 's'})';
    } else if (due != null) {
      suffix = ' (due ${formatDate(due)})';
    } else {
      suffix = '';
    }
    lines.add(
      '• ${invoice.invoiceNumber ?? 'Bill'} · '
      '${formatDate(invoice.issuedAt ?? invoice.createdAt)} · '
      '${formatPaise(invoice.duePaise)}$suffix',
    );
  }
  final hidden = invoices.length - maxInvoices;
  if (hidden > 0) {
    lines.add('(+$hidden more invoice${hidden == 1 ? '' : 's'})');
  }

  lines
    ..add('')
    ..add('Total due: *${formatPaise(total)}*');

  final payment = shop.paymentInstructions;
  if (payment != null) {
    lines
      ..add('')
      ..add('Pay via:')
      ..add(payment);
  }

  lines
    ..add('')
    ..add('Phone: ${shop.phone}')
    ..add('Thank you.');
  return lines.join('\n');
}

/// A short summary to send along with the statement PDF.
String buildStatementMessage({
  required ShopProfile shop,
  required String customerName,
  required Statement statement,
}) {
  return [
    '*${shop.name}*',
    'Statement of account',
    '',
    'Hello $customerName,',
    'Here is your account summary (${statementPeriodLabel(statement)}):',
    '',
    'Opening balance: ${formatPaise(statement.openingPaise)}',
    'Billed: ${formatPaise(statement.billedPaise)}',
    'Received: ${formatPaise(statement.receivedPaise)}',
    'Balance due: *${formatPaise(statement.closingPaise)}*',
    '',
    'Phone: ${shop.phone}',
    'Thank you.',
  ].join('\n');
}
