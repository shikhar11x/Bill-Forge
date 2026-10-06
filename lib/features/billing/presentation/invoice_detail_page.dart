import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/theme/app_colors.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/utils/date_format.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/utils/quantity.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_card.dart';
import 'package:billforge/core/widgets/app_empty_state.dart';
import 'package:billforge/core/widgets/app_error_state.dart';
import 'package:billforge/core/widgets/app_toast.dart';
import 'package:billforge/core/widgets/page_container.dart';
import 'package:billforge/features/billing/application/bill_controller.dart';
import 'package:billforge/features/billing/application/billing_providers.dart';
import 'package:billforge/features/billing/domain/discount.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/presentation/widgets/invoice_list_items.dart';
import 'package:billforge/features/billing/presentation/widgets/totals_block.dart';

class InvoiceDetailPage extends ConsumerWidget {
  const InvoiceDetailPage({required this.invoiceId, super.key});

  final String invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(invoiceDetailProvider(invoiceId))
        .when(
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (error, stack) => AppErrorState(
            message: const StorageFailure().message,
            onRetry: () => ref.invalidate(invoiceDetailProvider(invoiceId)),
          ),
          data: (detail) => detail == null
              ? AppEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Invoice not found',
                  action: AppButton(
                    label: 'Back to billing',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.go(AppRoutes.billing),
                  ),
                )
              : _DetailView(detail: detail),
        );
  }
}

class _DetailView extends ConsumerWidget {
  const _DetailView({required this.detail});

  final InvoiceDetail detail;

  Future<void> _continueEditing(BuildContext context, WidgetRef ref) async {
    final loaded = await ref
        .read(billControllerProvider.notifier)
        .loadDraft(detail.invoice.id);
    if (!context.mounted) return;
    if (loaded) {
      context.go(AppRoutes.billingNew);
    } else {
      AppToast.show(
        context,
        'That draft no longer exists.',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final invoice = detail.invoice;

    final rows = buildTotalsRows(
      discountPaise: invoice.discountPaise,
      taxablePaise: invoice.taxablePaise,
      cgstPaise: invoice.cgstPaise,
      sgstPaise: invoice.sgstPaise,
      igstPaise: invoice.igstPaise,
      roundOffPaise: invoice.roundOffPaise,
    );

    return PageContainer(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.xl,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Back to billing',
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.go(AppRoutes.billing),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    invoiceTitle(invoice),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                InvoiceStatusBadge(invoice: invoice),
              ],
            ),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xs,
                children: [
                  Text(
                    invoice.customerName ?? 'Walk-in customer',
                    style: theme.textTheme.titleMedium,
                  ),
                  if (invoice.customerPhone != null)
                    Text(
                      invoice.customerPhone!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  if (invoice.customerGstin != null)
                    Text(
                      'GSTIN ${invoice.customerGstin}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  Text(
                    '${formatDateTime(invoiceDate(invoice))} · Place of supply: ${invoice.placeOfSupply}',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            if (invoice.isDraft)
              AppCard(
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'This bill is a draft and has not been issued.',
                      ),
                    ),
                    AppButton(
                      label: 'Continue editing',
                      onPressed: () => _continueEditing(context, ref),
                    ),
                  ],
                ),
              ),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < detail.items.length; i++) ...[
                    if (i > 0) const Divider(),
                    _ItemRow(item: detail.items[i]),
                  ],
                ],
              ),
            ),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TotalsBlock(rows: rows, totalPaise: invoice.grandTotalPaise),
                  if (detail.payments.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(),
                    const SizedBox(height: AppSpacing.sm),
                    for (final p in detail.payments)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${p.method.label} · ${formatDateTime(p.paidAt)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: muted,
                                ),
                              ),
                            ),
                            Text(formatPaise(p.amountPaise)),
                          ],
                        ),
                      ),
                  ],
                  if (!invoice.isDraft && invoice.duePaise > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Due (on credit)',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                        Text(
                          formatPaise(invoice.duePaise),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final InvoiceItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final detail = StringBuffer(
      '${formatMilli(item.qtyMilli)} ${item.unit.symbol} × ${formatPaise(item.unitPricePaise)}',
    );
    if (!item.discount.isNone) {
      detail.write(' · ${describeDiscount(item.discount)} off');
    }
    if (item.gstRatePercent > 0) detail.write(' · GST ${item.gstRatePercent}%');
    if (item.hsnCode != null) detail.write(' · HSN ${item.hsnCode}');

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  detail.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(formatPaise(item.totalPaise), style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}
