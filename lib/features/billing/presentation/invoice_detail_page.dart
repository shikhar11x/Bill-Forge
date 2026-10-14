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
import 'package:billforge/features/billing/domain/invoice_document.dart';
import 'package:billforge/features/billing/presentation/widgets/invoice_list_items.dart';
import 'package:billforge/features/billing/presentation/widgets/share_invoice_dialog.dart';
import 'package:billforge/features/billing/presentation/widgets/totals_block.dart';
import 'package:billforge/features/customers/application/customer_providers.dart';
import 'package:billforge/features/payments/application/payment_providers.dart';
import 'package:billforge/features/payments/domain/outstanding.dart';
import 'package:billforge/features/payments/presentation/widgets/collect_payment_dialog.dart';
import 'package:billforge/features/shop/application/shop_providers.dart';

class InvoiceDetailPage extends ConsumerWidget {
  const InvoiceDetailPage({required this.invoiceId, super.key});

  final String invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(invoiceDetailProvider(invoiceId)).when(
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

  Future<void> _collect(BuildContext context, WidgetRef ref) async {
    final customerId = detail.invoice.customerId;
    if (customerId == null) return;
    final customer =
        await ref.read(customerRepositoryProvider).getById(customerId);
    if (customer == null || !context.mounted) {
      if (context.mounted) {
        AppToast.show(context, 'Customer not found.', type: ToastType.error);
      }
      return;
    }
    final open = await ref
        .read(paymentRepositoryProvider)
        .watchOpenInvoicesFor(customerId)
        .first;
    if (!context.mounted) return;
    final recorded = await CollectPaymentDialog.show(
      context,
      customer: customer,
      openInvoices: open,
      invoiceId: detail.invoice.id,
    );
    if (recorded == true && context.mounted) {
      AppToast.show(context, 'Payment recorded', type: ToastType.success);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final invoice = detail.invoice;
    final shop = shopOrNull(ref.watch(shopProfileProvider));
    final compact = MediaQuery.sizeOf(context).width < 600;
    final now = DateTime.now();

    void openPrint() => context.go(AppRoutes.invoicePreview(invoice.id));
    final VoidCallback? openShare = shop == null
        ? null
        : () => ShareInvoiceDialog.show(
              context,
              InvoiceDocument(shop: shop, detail: detail),
            );

    final rows = buildTotalsRows(
      discountPaise: invoice.discountPaise,
      taxablePaise: invoice.taxablePaise,
      cgstPaise: invoice.cgstPaise,
      sgstPaise: invoice.sgstPaise,
      igstPaise: invoice.igstPaise,
      roundOffPaise: invoice.roundOffPaise,
    );

    final dueDate = invoice.dueDate;
    final overdue = isOverdue(invoice, now);
    final dueText = dueDate == null
        ? null
        : overdue
            ? 'Due ${formatDate(dueDate)} · overdue by ${daysOverdue(invoice, now)} day${daysOverdue(invoice, now) == 1 ? '' : 's'}'
            : 'Due ${formatDate(dueDate)}';

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
                if (!invoice.isDraft) ...[
                  const SizedBox(width: AppSpacing.sm),
                  if (compact) ...[
                    IconButton(
                      tooltip: 'Share',
                      icon: const Icon(Icons.share_outlined),
                      onPressed: openShare,
                    ),
                    IconButton(
                      tooltip: 'Print / PDF',
                      icon: const Icon(Icons.print_outlined),
                      onPressed: openPrint,
                    ),
                  ] else ...[
                    AppButton(
                      label: 'Share',
                      icon: Icons.share_outlined,
                      variant: AppButtonVariant.secondary,
                      onPressed: openShare,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      label: 'Print / PDF',
                      icon: Icons.print_outlined,
                      onPressed: openPrint,
                    ),
                  ],
                ],
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
            if (!invoice.isDraft && invoice.duePaise > 0)
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Balance due ${formatPaise(invoice.duePaise)}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                          if (dueText != null)
                            Text(
                              dueText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: overdue ? AppColors.danger : muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (invoice.customerId != null)
                      AppButton(
                        label: 'Collect payment',
                        icon: Icons.payments_outlined,
                        onPressed: () => _collect(context, ref),
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