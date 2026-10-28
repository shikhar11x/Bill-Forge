import 'package:billforge/core/utils/date_format.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/utils/quantity.dart';
import 'package:billforge/features/billing/domain/credit_note.dart';
import 'package:billforge/features/shop/domain/shop_profile.dart';

/// A short WhatsApp message to go with the credit note PDF.
String buildCreditNoteMessage({
  required ShopProfile shop,
  required CreditNoteDetail detail,
  int maxItems = 6,
}) {
  final note = detail.creditNote;
  final name = note.customerName;

  final lines = <String>[
    '*${shop.name}*',
    'Credit note ${note.creditNoteNumber} · ${formatDate(note.issuedAt)}',
    'Against invoice ${note.invoiceNumber}',
    '',
    name == null ? 'Hello,' : 'Hello $name,',
    'We have issued a credit note for the items returned:',
    '',
  ];

  for (final item in detail.items.take(maxItems)) {
    lines.add(
      '• ${item.name} × ${formatMilli(item.qtyMilli)} ${item.unit.symbol} '
      '= ${formatPaise(item.totalPaise)}',
    );
  }
  final hidden = detail.items.length - maxItems;
  if (hidden > 0) lines.add('(+$hidden more item${hidden == 1 ? '' : 's'})');

  lines
    ..add('')
    ..add('Credit note total: *${formatPaise(note.totalPaise)}*');
  if (note.appliedPaise > 0) {
    lines.add(
      'Adjusted against your balance: ${formatPaise(note.appliedPaise)}',
    );
  }
  if (note.refundPaise > 0) {
    lines.add(
      'Refunded: ${formatPaise(note.refundPaise)} (${note.refundMethod?.label ?? 'Cash'})',
    );
  }

  lines
    ..add('')
    ..add('Phone: ${shop.phone}')
    ..add('Thank you.');
  return lines.join('\n');
}
