import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/theme/app_colors.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/utils/async_value_x.dart';
import 'package:billforge/core/utils/date_format.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/widgets/app_badge.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_card.dart';
import 'package:billforge/core/widgets/app_empty_state.dart';
import 'package:billforge/core/widgets/app_error_state.dart';
import 'package:billforge/core/widgets/app_stat_card.dart';
import 'package:billforge/core/widgets/app_toast.dart';
import 'package:billforge/core/widgets/page_container.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/customers/application/customer_providers.dart';
import 'package:billforge/features/customers/domain/customer.dart';
import 'package:billforge/features/customers/presentation/widgets/customer_list_items.dart';
import 'package:billforge/features/payments/application/payment_providers.dart';
import 'package:billforge/features/payments/domain/outstanding.dart';
import 'package:billforge/features/payments/presentation/widgets/collect_payment_dialog.dart';
import 'package:billforge/features/payments/presentation/widgets/customer_message_dialog.dart';
import 'package:billforge/features/shop/application/shop_providers.dart';

class CustomerAccountPage extends ConsumerWidget {
  const CustomerAccountPage({required this.customerId, super.key});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(customerByIdProvider(customerId))
        .when(
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (error, stack) => AppErrorState(
            message: const StorageFailure().message,
            onRetry: () => ref.invalidate(customerByIdProvider(customerId)),
          ),
          data: (customer) => customer == null
              ? AppEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Customer not found',
                  action: AppButton(
                    label: 'Back to customers',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.go(AppRoutes.customers),
                  ),
                )
              : _AccountView(customer: customer),
        );
  }
}

class _AccountView extends ConsumerWidget {
  const _AccountView({required this.customer});

  final Customer customer;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.customers);
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    await context.push(AppRoutes.customerEdit(customer.id));
    ref.invalidate(customerByIdProvider(customer.id));
  }

  Future<void> _collect(BuildContext context, List<Invoice> open) async {
    final recorded = await CollectPaymentDialog.show(
      context,
      customer: customer,
      openInvoices: open,
    );
    if (recorded == true && context.mounted) {
      AppToast.show(context, 'Payment recorded', type: ToastType.success);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final openAsync = ref.watch(customerOpenInvoicesProvider(customer.id));
    final open = openAsync.dataOrNull ?? const <Invoice>[];
    final receipts =
        ref.watch(customerReceiptsProvider(customer.id)).dataOrNull ?? const [];
    final now = DateTime.now();
    // Reminders need the shop, so keep it loaded while this page is open.
    ref.watch(shopProfileProvider);

    final outstanding = open.fold<int>(0, (s, i) => s + i.duePaise);
    final overdue = open
        .where((i) => isOverdue(i, now))
        .fold<int>(0, (s, i) => s + i.duePaise);
    final limit = customer.creditLimitPaise;

    final stats = [
      AppStatCard(
        label: 'Outstanding',
        value: formatPaise(outstanding),
        icon: Icons.account_balance_wallet_outlined,
      ),
      AppStatCard(
        label: 'Overdue',
        value: formatPaise(overdue),
        icon: Icons.schedule_rounded,
      ),
      AppStatCard(
        label: 'Credit limit',
        value: limit == null
            ? 'No limit'
            : formatPaise(limit, showDecimals: false),
        icon: Icons.credit_score_outlined,
        caption: limit == null
            ? null
            : '${formatPaise(limit - outstanding < 0 ? 0 : limit - outstanding)} available',
      ),
    ];

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
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => _back(context),
                ),
                const SizedBox(width: AppSpacing.sm),
                CustomerAvatar(name: customer.name),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (customer.phone != null)
                        Text(
                          customer.phone!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: muted,
                          ),
                        ),
                    ],
                  ),
                ),
                AppButton(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => _edit(context, ref),
                ),
              ],
            ),
            LayoutBuilder(
              builder: (context, box) {
                const gap = AppSpacing.lg;
                final columns = box.maxWidth >= 640
                    ? 3
                    : (box.maxWidth >= 420 ? 2 : 1);
                final width = (box.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final s in stats) SizedBox(width: width, child: s),
                  ],
                );
              },
            ),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                AppButton(
                  label: 'Collect payment',
                  icon: Icons.payments_outlined,
                  onPressed: open.isEmpty
                      ? null
                      : () => _collect(context, open),
                ),
                AppButton(
                  label: 'Send reminder',
                  icon: Icons.chat_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: open.isEmpty
                      ? null
                      : () => showReminderDialog(
                          context,
                          ref,
                          customer: customer,
                          openInvoices: open,
                        ),
                ),
                AppButton(
                  label: 'Statement',
                  icon: Icons.receipt_long_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: () =>
                      context.push(AppRoutes.customerStatement(customer.id)),
                ),
              ],
            ),
            _Section(
              title: 'Open invoices',
              child: open.isEmpty
                  ? const AppCard(
                      child: Text(
                        'No pending invoices. This customer is paid up.',
                      ),
                    )
                  : AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < open.length; i++) ...[
                            if (i > 0) const Divider(),
                            _OpenInvoiceTile(invoice: open[i], now: now),
                          ],
                        ],
                      ),
                    ),
            ),
            _Section(
              title: 'Recent payments',
              child: receipts.isEmpty
                  ? const AppCard(child: Text('No payments collected yet.'))
                  : AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < receipts.length; i++) ...[
                            if (i > 0) const Divider(),
                            ListTile(
                              title: Text(receipts[i].method.label),
                              subtitle: Text(
                                [
                                  formatDateTime(receipts[i].receivedAt),
                                  if (receipts[i].note != null)
                                    receipts[i].note!,
                                ].join(' · '),
                                style: TextStyle(color: muted),
                              ),
                              trailing: Text(
                                '+${formatPaise(receipts[i].amountPaise)}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenInvoiceTile extends StatelessWidget {
  const _OpenInvoiceTile({required this.invoice, required this.now});

  final Invoice invoice;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final overdue = isOverdue(invoice, now);
    final due = invoice.dueDate;

    return ListTile(
      onTap: () => context.push(AppRoutes.invoice(invoice.id)),
      title: Row(
        children: [
          Flexible(child: Text(invoice.invoiceNumber ?? 'Bill')),
          if (overdue) ...[
            const SizedBox(width: AppSpacing.sm),
            const AppBadge(label: 'Overdue', tone: BadgeTone.danger),
          ],
        ],
      ),
      subtitle: Text(
        [
          formatDate(invoice.issuedAt ?? invoice.createdAt),
          if (due != null) 'due ${formatDate(due)}',
        ].join(' · '),
        style: TextStyle(color: muted),
      ),
      trailing: Text(
        formatPaise(invoice.duePaise),
        style: theme.textTheme.titleSmall?.copyWith(
          color: overdue ? AppColors.danger : AppColors.warning,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}
