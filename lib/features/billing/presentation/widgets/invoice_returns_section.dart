import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/theme/app_colors.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/utils/async_value_x.dart';
import 'package:billforge/core/utils/date_format.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_card.dart';
import 'package:billforge/core/widgets/app_toast.dart';
import 'package:billforge/features/billing/application/billing_providers.dart';
import 'package:billforge/features/billing/application/credit_note_providers.dart';
import 'package:billforge/features/billing/domain/credit_note.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/presentation/widgets/cancel_invoice_dialog.dart';

/// Return and cancel actions plus the credit notes of one invoice.
class InvoiceReturnsSection extends ConsumerWidget {
  const InvoiceReturnsSection({required this.invoice, super.key});

  final Invoice invoice;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final cancelled = await CancelInvoiceDialog.show(context, invoice);
    if (cancelled != true) return;
    ref.invalidate(invoiceDetailProvider(invoice.id));
    if (context.mounted) {
      AppToast.show(context, 'Invoice cancelled', type: ToastType.success);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final notes =
        ref.watch(creditNotesForInvoiceProvider(invoice.id)).dataOrNull ??
        const <CreditNote>[];

    final issued = invoice.status == InvoiceStatus.issued;
    final canReturn = issued && invoice.creditedPaise < invoice.grandTotalPaise;
    final canCancel = issued && invoice.creditedPaise == 0;

    if (!issued && !invoice.isCancelled && notes.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          Text('Returns & credit notes', style: theme.textTheme.titleMedium),
          if (invoice.isCancelled)
            Text(
              'This invoice was cancelled.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.danger,
              ),
            )
          else if (invoice.creditedPaise > 0)
            Text(
              '${formatPaise(invoice.creditedPaise)} credited so far.',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          if (canReturn || canCancel)
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                if (canReturn)
                  AppButton(
                    label: 'Return items',
                    icon: Icons.assignment_return_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: () =>
                        context.go(AppRoutes.invoiceReturn(invoice.id)),
                  ),
                if (canCancel)
                  AppButton(
                    label: 'Cancel invoice',
                    icon: Icons.block_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _cancel(context, ref),
                  ),
              ],
            ),
          if (notes.isNotEmpty)
            Column(
              children: [
                for (final n in notes)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => context.go(AppRoutes.creditNote(n.id)),
                    title: Text(n.creditNoteNumber),
                    subtitle: Text(
                      '${formatDate(n.issuedAt)} · ${n.reason.label}',
                      style: TextStyle(color: muted),
                    ),
                    trailing: Text(
                      formatPaise(n.totalPaise),
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
