import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/theme/app_colors.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/responsive/responsive_builder.dart';
import 'package:billforge/core/utils/app_logger.dart';
// import 'package:billforge/core/utils/async_value_x.dart';
import 'package:billforge/core/utils/date_format.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/widgets/app_card.dart';
import 'package:billforge/core/widgets/app_data_table.dart';
import 'package:billforge/core/widgets/app_empty_state.dart';
import 'package:billforge/core/widgets/app_error_state.dart';
import 'package:billforge/core/widgets/app_skeleton.dart';
import 'package:billforge/core/widgets/app_stat_card.dart';
import 'package:billforge/core/widgets/app_toast.dart';
import 'package:billforge/features/customers/application/customer_providers.dart';
import 'package:billforge/features/payments/application/payment_providers.dart';
import 'package:billforge/features/shop/application/shop_providers.dart';
import 'package:billforge/features/payments/domain/outstanding.dart';
import 'package:billforge/features/payments/presentation/widgets/customer_message_dialog.dart';

class OutstandingPage extends ConsumerWidget {
  const OutstandingPage({super.key});

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.customers);
    }
  }

  Future<void> _remind(
    BuildContext context,
    WidgetRef ref,
    OutstandingEntry entry,
  ) async {
    try {
      // The report uses invoice snapshots; reminders use the current record.
      final customer = await ref
          .read(customerRepositoryProvider)
          .getById(entry.customerId);
      final open = await ref
          .read(paymentRepositoryProvider)
          .watchOpenInvoicesFor(entry.customerId)
          .first;
      if (customer == null || !context.mounted) return;
      await showReminderDialog(
        context,
        ref,
        customer: customer,
        openInvoices: open,
      );
    } catch (error, stack) {
      AppLogger.error('Reminder failed', error: error, stackTrace: stack);
      if (!context.mounted) return;
      AppToast.show(
        context,
        const StorageFailure().message,
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final async = ref.watch(openInvoicesProvider);
    final report = ref.watch(outstandingReportProvider);
    // Reminders need the shop, so keep it loaded while this page is open.
    ref.watch(shopProfileProvider);

    Widget body() {
      if (!async.hasValue) {
        if (async.hasError) {
          AppLogger.error(
            'Could not load outstanding balances',
            error: async.error,
            stackTrace: async.stackTrace,
          );
          return AppErrorState(
            message: const StorageFailure().message,
            onRetry: () => ref.invalidate(openInvoicesProvider),
          );
        }
        return const AppListSkeleton();
      }
      if (report.entries.isEmpty) {
        return const AppEmptyState(
          icon: Icons.check_circle_outline_rounded,
          title: 'No pending payments',
          message: 'Everyone is paid up.',
        );
      }

      return ResponsiveBuilder(
        builder: (context, size) {
          if (size.isMobile) {
            return ListView.separated(
              itemCount: report.entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, i) {
                final e = report.entries[i];
                return AppCard(
                  onTap: () =>
                      context.push(AppRoutes.customerAccount(e.customerId)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.customerName,
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              '${e.openInvoices} open invoice${e.openInvoices == 1 ? '' : 's'}'
                              '${e.overduePaise > 0 ? ' · ${formatPaise(e.overduePaise)} overdue' : ''}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: e.overduePaise > 0
                                    ? AppColors.danger
                                    : muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatPaise(e.outstandingPaise),
                        style: theme.textTheme.titleSmall,
                      ),
                      IconButton(
                        tooltip: 'Send reminder',
                        icon: const Icon(Icons.chat_outlined),
                        onPressed: () => _remind(context, ref, e),
                      ),
                    ],
                  ),
                );
              },
            );
          }

          return AppDataTable<OutstandingEntry>(
            rows: report.entries,
            onRowTap: (e) =>
                context.push(AppRoutes.customerAccount(e.customerId)),
            columns: [
              AppColumn<OutstandingEntry>(
                label: 'Customer',
                flex: 4,
                cell: (context, e) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.customerName, style: theme.textTheme.titleSmall),
                    if (e.customerPhone != null)
                      Text(
                        e.customerPhone!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                  ],
                ),
              ),
              AppColumn<OutstandingEntry>(
                label: 'Open invoices',
                flex: 2,
                alignment: Alignment.centerRight,
                cell: (context, e) => Text('${e.openInvoices}'),
              ),
              AppColumn<OutstandingEntry>(
                label: 'Oldest unpaid',
                flex: 2,
                alignment: Alignment.centerRight,
                cell: (context, e) => Text(formatDate(e.oldestIssuedAt)),
              ),
              AppColumn<OutstandingEntry>(
                label: 'Overdue',
                flex: 2,
                alignment: Alignment.centerRight,
                cell: (context, e) => Text(
                  e.overduePaise == 0 ? '—' : formatPaise(e.overduePaise),
                  style: TextStyle(
                    color: e.overduePaise == 0 ? null : AppColors.danger,
                  ),
                ),
              ),
              AppColumn<OutstandingEntry>(
                label: 'Outstanding',
                flex: 2,
                alignment: Alignment.centerRight,
                cell: (context, e) => Text(
                  formatPaise(e.outstandingPaise),
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
            trailing: (context, e) => IconButton(
              tooltip: 'Send reminder',
              icon: const Icon(Icons.chat_outlined),
              onPressed: () => _remind(context, ref, e),
            ),
          );
        },
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.contentMaxWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.lg,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => _back(context),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Outstanding balances',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
                      SizedBox(
                        width: width,
                        child: AppStatCard(
                          label: 'Total outstanding',
                          value: formatPaise(report.totalPaise),
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: AppStatCard(
                          label: 'Overdue',
                          value: formatPaise(report.overduePaise),
                          icon: Icons.schedule_rounded,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: AppStatCard(
                          label: 'Customers owing',
                          value: '${report.entries.length}',
                          icon: Icons.people_outline_rounded,
                        ),
                      ),
                    ],
                  );
                },
              ),
              Expanded(child: body()),
            ],
          ),
        ),
      ),
    );
  }
}
