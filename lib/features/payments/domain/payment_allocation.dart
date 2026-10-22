import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/features/billing/domain/invoice.dart';

class Allocation {
  const Allocation(this.invoiceId, this.amountPaise);

  final String invoiceId;
  final int amountPaise;
}

/// Spreads [amountPaise] over [openInvoices], oldest first (issue date, then
/// invoice number). Never allocates more than an invoice's balance.
List<Allocation> allocatePayment(int amountPaise, List<Invoice> openInvoices) {
  if (amountPaise <= 0) return const [];

  final sorted = [...openInvoices]
    ..sort((a, b) {
      final byDate = (a.issuedAt ?? a.createdAt).compareTo(
        b.issuedAt ?? b.createdAt,
      );
      return byDate != 0
          ? byDate
          : (a.invoiceNumber ?? '').compareTo(b.invoiceNumber ?? '');
    });

  var remaining = amountPaise;
  final result = <Allocation>[];
  for (final invoice in sorted) {
    if (remaining <= 0) break;
    final due = invoice.duePaise;
    if (due <= 0) continue;
    final take = remaining < due ? remaining : due;
    result.add(Allocation(invoice.id, take));
    remaining -= take;
  }
  return result;
}

/// A user-facing problem with the amount, or null when it is acceptable.
String? validateCollection({required int amountPaise, required int duePaise}) {
  if (amountPaise <= 0) return 'Amount must be more than zero';
  if (amountPaise > duePaise) {
    return 'Cannot be more than the ${formatPaise(duePaise)} due';
  }
  return null;
}
