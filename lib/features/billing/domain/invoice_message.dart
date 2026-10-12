import 'package:billforge/core/utils/date_format.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/utils/quantity.dart';
import 'package:billforge/features/billing/domain/invoice_document.dart';

const _maxNameLength = 40;

String _shorten(String name) => name.length <= _maxNameLength
    ? name
    : '${name.substring(0, _maxNameLength - 1).trimRight()}…';

/// The default WhatsApp message for an issued invoice. Kept short on purpose:
/// at most [maxItems] item lines, with the rest summarised.
String buildInvoiceMessage(InvoiceDocument d, {int maxItems = 6}) {
  final invoice = d.invoice;
  final shop = d.shop;
  final number = invoice.invoiceNumber;
  final customerName = invoice.customerName;

  final lines = <String>[
    '*${shop.name}*',
    '${d.title}${number == null ? '' : ' $number'} · ${formatDate(d.date)}',
    '',
    customerName == null ? 'Hello,' : 'Hello $customerName,',
    'Thank you for shopping with us. Here are your bill details:',
    '',
  ];

  for (final item in d.items.take(maxItems)) {
    lines.add(
      '• ${_shorten(item.name)} × ${formatMilli(item.qtyMilli)} '
      '${item.unit.symbol} = ${formatPaise(item.totalPaise)}',
    );
  }
  final hidden = d.items.length - maxItems;
  if (hidden > 0) {
    lines.add('(+$hidden more item${hidden == 1 ? '' : 's'})');
  }

  lines
    ..add('')
    ..add('Total: *${formatPaise(invoice.grandTotalPaise)}*');
  if (invoice.paidPaise > 0) {
    lines.add('Paid: ${formatPaise(invoice.paidPaise)}');
  }
  if (invoice.duePaise > 0) {
    lines.add('Balance due: *${formatPaise(invoice.duePaise)}*');
    final payment = shop.paymentInstructions;
    if (payment != null) {
      lines
        ..add('')
        ..add('Pay via:')
        ..add(payment);
    }
  }

  lines
    ..add('')
    ..add('Phone: ${shop.phone}');
  final footer = shop.invoiceFooter;
  if (footer != null) lines.add(footer);

  return lines.join('\n');
}
