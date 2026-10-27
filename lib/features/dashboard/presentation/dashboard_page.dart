import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/utils/async_value_x.dart';
import 'package:billforge/core/utils/date_format.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/widgets/app_bar_chart.dart';
import 'package:billforge/core/widgets/app_card.dart';
import 'package:billforge/core/widgets/app_empty_state.dart';
import 'package:billforge/core/widgets/app_error_state.dart';
import 'package:billforge/core/widgets/app_skeleton.dart';
import 'package:billforge/core/widgets/app_stat_card.dart';
import 'package:billforge/core/widgets/page_container.dart';
import 'package:billforge/features/auth/application/auth_controller.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/presentation/widgets/invoice_list_items.dart';
import 'package:billforge/features/inventory/application/inventory_providers.dart';
import 'package:billforge/features/payments/application/payment_providers.dart';
import 'package:billforge/features/reports/application/report_providers.dart';
import 'package:billforge/features/reports/domain/payment_report.dart';
import 'package:billforge/features/reports/domain/product_report.dart';
import 'package:billforge/features/reports/domain/report_data.dart';
import 'package:billforge/features/reports/domain/report_range.dart';
import 'package:billforge/features/reports/domain/sales_report.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name = ref.watch(authControllerProvider).user?.name ?? '';
    final firstName = name.split(' ').first;

    final now = DateTime.now();
    final range30 = ReportPreset.last30Days.range(now)!;
    final dataAsync = ref.watch(reportDataProvider(range30));

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            firstName.isEmpty ? 'Welcome back' : 'Welcome back, $firstName',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "Here's what's happening in your shop today.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _Stats(data: dataAsync.dataOrNull, now: now),
          const SizedBox(height: AppSpacing.xl),
          if (dataAsync.dataOrNull == null)
            dataAsync.hasError
                ? SizedBox(
                    height: 260,
                    child: AppErrorState(
                      message: const StorageFailure().message,
                      onRetry: () =>
                          ref.invalidate(reportDataProvider(range30)),
                    ),
                  )
                : const SizedBox(
                    height: 260,
                    child: AppListSkeleton(itemCount: 5),
                  )
          else
            _Panels(data: dataAsync.requireValue, now: now),
        ],
      ),
    );
  }
}

class _Stats extends ConsumerWidget {
  const _Stats({required this.data, required this.now});

  final ReportData? data;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStock = ref.watch(lowStockCountProvider).dataOrNull;
    final pending = ref.watch(openInvoicesProvider).dataOrNull == null
        ? null
        : ref.watch(outstandingReportProvider).totalPaise;

    final d = data;
    final today = d?.slice(ReportRange.between(now, now));
    final summary = today == null ? null : buildSalesSummary(today);

    final stats = [
      AppStatCard(
        label: "Today's sales",
        value: summary == null ? '—' : formatPaise(summary.netPaise),
        icon: Icons.trending_up_rounded,
        caption: summary == null ? null : 'Net of returns',
      ),
      AppStatCard(
        label: 'Orders today',
        value: summary == null ? '—' : '${summary.orders}',
        icon: Icons.receipt_long_outlined,
      ),
      AppStatCard(
        label: "Today's est. profit",
        value: (summary == null || !summary.profit.hasEstimate)
            ? '—'
            : formatPaise(summary.profit.profitPaise),
        icon: Icons.savings_outlined,
        caption: 'Estimate from purchase prices',
      ),
      AppStatCard(
        label: 'Pending payments',
        value: pending == null ? '—' : formatPaise(pending),
        icon: Icons.schedule_rounded,
      ),
      AppStatCard(
        label: 'Low-stock items',
        value: lowStock == null ? '—' : '$lowStock',
        icon: Icons.warning_amber_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, box) {
        const gap = AppSpacing.lg;
        final columns = box.maxWidth >= 1000
            ? 5
            : (box.maxWidth >= 700 ? 3 : (box.maxWidth >= 420 ? 2 : 1));
        final width = (box.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final s in stats) SizedBox(width: width, child: s)],
        );
      },
    );
  }
}

class _Panels extends StatelessWidget {
  const _Panels({required this.data, required this.now});

  final ReportData data;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final sales = _SalesCard(data: data, now: now);
    final top = _TopProductsCard(data: data);
    final mix = _PaymentMixCard(data: data);
    const recent = _RecentCard();

    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth >= 900) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: sales),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: top),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: mix),
                  const SizedBox(width: AppSpacing.lg),
                  const Expanded(flex: 2, child: recent),
                ],
              ),
            ],
          );
        }
        return Column(
          children: [
            sales,
            const SizedBox(height: AppSpacing.lg),
            top,
            const SizedBox(height: AppSpacing.lg),
            mix,
            const SizedBox(height: AppSpacing.lg),
            recent,
          ],
        );
      },
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _SalesCard extends StatefulWidget {
  const _SalesCard({required this.data, required this.now});

  final ReportData data;
  final DateTime now;

  @override
  State<_SalesCard> createState() => _SalesCardState();
}

class _SalesCardState extends State<_SalesCard> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final now = widget.now;
    final range = ReportRange.between(
      DateTime(now.year, now.month, now.day - (_days - 1)),
      now,
    );
    final buckets = buildSalesBuckets(
      widget.data.slice(range),
      range,
      granularity: SalesGranularity.day,
    );

    return _CardShell(
      title: 'Sales overview',
      trailing: SegmentedButton<int>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: 7, label: Text('7 days')),
          ButtonSegment(value: 30, label: Text('30 days')),
        ],
        selected: {_days},
        onSelectionChanged: (s) => setState(() => _days = s.first),
      ),
      child: AppBarChart(
        emptyMessage: 'No sales yet',
        items: [
          for (final b in buckets)
            BarChartItem(
              label: bucketLabel(b, SalesGranularity.day),
              value: b.netPaise < 0 ? 0 : b.netPaise,
              tooltip:
                  '${bucketLabel(b, SalesGranularity.day)}: ${formatPaise(b.netPaise)}',
            ),
        ],
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard({required this.data});

  final ReportData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = buildProductRows(data).take(5).toList();

    return _CardShell(
      title: 'Top products (30 days)',
      child: rows.isEmpty
          ? const SizedBox(
              height: 160,
              child: AppEmptyState(
                icon: Icons.category_outlined,
                title: 'No sales yet',
              ),
            )
          : Column(
              children: [
                for (final r in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          formatPaise(r.revenuePaise),
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _PaymentMixCard extends StatelessWidget {
  const _PaymentMixCard({required this.data});

  final ReportData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = buildMethodRows(data);

    return _CardShell(
      title: 'Payments (30 days)',
      child: rows.isEmpty
          ? const SizedBox(
              height: 160,
              child: AppEmptyState(
                icon: Icons.payments_outlined,
                title: 'No payments yet',
              ),
            )
          : Column(
              children: [
                for (final r in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text(r.method.label)),
                        Text(
                          formatPaise(r.netPaise),
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _RecentCard extends ConsumerWidget {
  const _RecentCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final invoices = ref.watch(recentInvoicesProvider).dataOrNull;

    Widget body;
    if (invoices == null) {
      body = const SizedBox(height: 160, child: AppListSkeleton(itemCount: 3));
    } else if (invoices.isEmpty) {
      body = const SizedBox(
        height: 160,
        child: AppEmptyState(
          icon: Icons.swap_horiz_rounded,
          title: 'No transactions yet',
          message: 'New invoices will show up here.',
        ),
      );
    } else {
      body = Column(
        children: [
          for (final Invoice i in invoices)
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => context.go(AppRoutes.invoice(i.id)),
              title: Text(invoiceTitle(i)),
              subtitle: Text(
                '${i.customerName ?? 'Walk-in customer'} · ${formatDate(invoiceDate(i))}',
                style: TextStyle(color: muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatPaise(i.grandTotalPaise),
                    style: theme.textTheme.titleSmall,
                  ),
                  InvoiceStatusBadge(invoice: i),
                ],
              ),
            ),
        ],
      );
    }
    return _CardShell(title: 'Recent invoices', child: body);
  }
}
