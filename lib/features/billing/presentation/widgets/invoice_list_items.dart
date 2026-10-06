import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/utils/date_format.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/widgets/app_badge.dart';
import 'package:billforge/core/widgets/app_card.dart';
import 'package:billforge/features/billing/domain/invoice.dart';

class InvoiceStatusBadge extends StatelessWidget {
  const InvoiceStatusBadge({required this.invoice, super.key});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    if (invoice.isDraft) {
      return const AppBadge(label: 'Draft');
    }
    return switch (invoice.paymentStatus) {
      PaymentStatus.paid => const AppBadge(
        label: 'Paid',
        tone: BadgeTone.success,
      ),
      PaymentStatus.partial => const AppBadge(
        label: 'Partial',
        tone: BadgeTone.warning,
      ),
      PaymentStatus.unpaid => const AppBadge(
        label: 'Unpaid',
        tone: BadgeTone.danger,
      ),
    };
  }
}

/// "INV-0001", or "Draft bill" before it is issued.
String invoiceTitle(Invoice invoice) => invoice.invoiceNumber ?? 'Draft bill';

DateTime invoiceDate(Invoice invoice) => invoice.issuedAt ?? invoice.updatedAt;

/// Mobile list item.
class InvoiceCard extends StatelessWidget {
  const InvoiceCard({required this.invoice, required this.onTap, super.key});

  final Invoice invoice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invoiceTitle(invoice), style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${invoice.customerName ?? 'Walk-in customer'} · ${formatDateTime(invoiceDate(invoice))}',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatPaise(invoice.grandTotalPaise),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              InvoiceStatusBadge(invoice: invoice),
            ],
          ),
        ],
      ),
    );
  }
}
