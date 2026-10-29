import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/motion/app_motion.dart';
import 'package:billforge/core/motion/reveal.dart';
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
import 'package:billforge/core/widgets/tilt_card.dart';
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

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

String _countText(int n) => '$n';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(authControllerProvider).user?.name ?? '';
    final firstName = name.split(' ').first;

    final now = DateTime.now();
    final range30 = ReportPreset.last30Days.range(now)!;
    final dataAsync = ref.watch(reportDataProvider(range30));
    final data = dataAsync.dataOrNull;
    final summary = data == null
        ? null
        : buildSalesSummary(data.slice(ReportRange.between(now, now)));

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Reveal(
            child: _Hero(firstName: firstName, summary: summary, now: now),
          ),
          const SizedBox(height: AppSpacing.xl),
          _Stats(summary: summary),
          const SizedBox(height: AppSpacing.xl),
          if (data == null)
            dataAsync.hasError
                ? SizedBox(
                    height: 260,
                    child: AppErrorState(
                      message: const StorageFailure().message,
                      onRetry: () => ref.invalidate(reportDataProvider(range30)),
                    ),
                  )
                : const SizedBox(height: 260, child: AppListSkeleton(itemCount: 5))
          else
            _Panels(data: data, now: now),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

String _summaryLine(SalesSummary? s) {
  if (s == null) return "Loading today's numbers…";
  if (s.orders == 0 && s.netPaise == 0) {
    return 'No sales yet today. Ready to make the first bill?';
  }
  return '${s.orders} bill${s.orders == 1 ? '' : 's'} and '
      '${formatPaise(s.netPaise)} in sales so far today.';
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.firstName,
    required this.summary,
    required this.now,
  });

  final String firstName;
  final SalesSummary? summary;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final hsl = HSLColor.fromColor(accent);
    final second = hsl
        .withHue((hsl.hue + 40) % 360)
        .withLightness((hsl.lightness * 0.8).clamp(0.2, 0.7).toDouble())
        .toColor();
    const radius = AppRadius.lg + 4;

    final title = theme.textTheme.headlineSmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
    );
    final body = theme.textTheme.bodyMedium?.copyWith(
      color: Colors.white.withValues(alpha: 0.88),
    );

    return TiltCard(
      maxTilt: 0.02,
      radius: radius,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent, second],
            ),
          ),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              const Positioned(right: -50, top: -60, child: _HeroOrb(size: 220, alpha: 0.10)),
              const Positioned(right: 70, bottom: -90, child: _HeroOrb(size: 180, alpha: 0.07)),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstName.isEmpty
                          ? 'Welcome back'
                          : 'Welcome back, $firstName',
                      style: title,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${_weekdays[now.weekday - 1]}, ${formatDate(now)}',
                      style: body,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(_summaryLine(summary), style: body),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.sm,
                      children: [
                        FilledButton.icon(
                          onPressed: () => context.go(AppRoutes.billingNew),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('New bill'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF14171F),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.go(AppRoutes.productNew),
                          icon: const Icon(Icons.category_outlined, size: 18),
                          label: const Text('Add product'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A translucent circle that eases into place once.
class _HeroOrb extends StatelessWidget {
  const _HeroOrb({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: AppMotion.of(context, const Duration(milliseconds: 900)),
      curve: AppMotion.standard,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.7 + 0.3 * t, child: child),
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: alpha),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat cards
// ---------------------------------------------------------------------------

class _Stats extends ConsumerWidget {
  const _Stats({required this.summary});

  final SalesSummary? summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStock = ref.watch(lowStockCountProvider).dataOrNull;
    final pending = ref.watch(openInvoicesProvider).dataOrNull == null
        ? null
        : ref.watch(outstandingReportProvider).totalPaise;
    final s = summary;
    final profit = (s != null && s.profit.hasEstimate)
        ? s.profit.profitPaise
        : null;

    final stats = [
      AppStatCard(
        label: "Today's sales",
        value: s == null ? '—' : formatPaise(s.netPaise),
        icon: Icons.trending_up_rounded,
        caption: s == null ? null : 'Net of returns',
        animateTo: s?.netPaise,
        format: formatPaise,
      ),
      AppStatCard(
        label: 'Orders today',
        value: s == null ? '—' : '${s.orders}',
        icon: Icons.receipt_long_outlined,
        animateTo: s?.orders,
        format: _countText,
      ),
      AppStatCard(
        label: "Today's est. profit",
        value: profit == null ? '—' : formatPaise(profit),
        icon: Icons.savings_outlined,
        caption: 'Estimate from purchase prices',
        animateTo: profit,
        format: formatPaise,
      ),
      AppStatCard(
        label: 'Pending payments',
        value: pending == null ? '—' : formatPaise(pending),
        icon: Icons.schedule_rounded,
        animateTo: pending,
        format: formatPaise,
      ),
      AppStatCard(
        label: 'Low-stock items',
        value: lowStock == null ? '—' : '$lowStock',
        icon: Icons.warning_amber_rounded,
        animateTo: lowStock,
        format: _countText,
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
          children: [
            for (var i = 0; i < stats.length; i++)
              SizedBox(
                width: width,
                child: Reveal(index: i + 1, child: TiltCard(child: stats[i])),
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Panels
// ---------------------------------------------------------------------------

class _Panels extends StatelessWidget {
  const _Panels({required this.data, required this.now});

  final ReportData data;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final sales = Reveal(index: 5, child: _SalesCard(data: data, now: now));
    final top = Reveal(index: 6, child: _TopProductsCard(data: data));
    final mix = Reveal(index: 7, child: _PaymentMixCard(data: data));
    const recent = Reveal(index: 8, child: _RecentCard());

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
    final trailing = this.trailing;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.titleMedium),
              ),
              if (trailing != null) trailing,
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