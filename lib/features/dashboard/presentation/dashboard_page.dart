import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/widgets/app_card.dart';
import 'package:billforge/core/widgets/app_empty_state.dart';
import 'package:billforge/core/widgets/app_stat_card.dart';
import 'package:billforge/core/widgets/page_container.dart';
import 'package:billforge/features/auth/application/auth_controller.dart';

/// Layout shell only. Real numbers arrive with the billing/reports phases.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name = ref.watch(authControllerProvider).user?.name ?? '';
    final firstName = name.split(' ').first;

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const _StatGrid(),
          const SizedBox(height: AppSpacing.xl),
          const _Panels(),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid();

  @override
  Widget build(BuildContext context) {
    final stats = [
      AppStatCard(
        label: "Today's sales",
        value: formatInr(0),
        icon: Icons.trending_up_rounded,
      ),
      const AppStatCard(
        label: 'Orders',
        value: '0',
        icon: Icons.receipt_long_outlined,
      ),
      AppStatCard(
        label: 'Pending payments',
        value: formatInr(0),
        icon: Icons.schedule_rounded,
      ),
      const AppStatCard(
        label: 'Low-stock items',
        value: '0',
        icon: Icons.warning_amber_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, box) {
        const gap = AppSpacing.lg;
        final columns = box.maxWidth >= 900 ? 4 : (box.maxWidth >= 420 ? 2 : 1);
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
  const _Panels();

  @override
  Widget build(BuildContext context) {
    const sales = _Panel(
      title: 'Sales overview',
      icon: Icons.show_chart_rounded,
      emptyTitle: 'No sales yet',
      emptyMessage:
          'Your sales trend will appear here once you create invoices.',
    );
    const recent = _Panel(
      title: 'Recent transactions',
      icon: Icons.swap_horiz_rounded,
      emptyTitle: 'No transactions yet',
      emptyMessage: 'New invoices and payments will show up here.',
    );

    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth >= 900) {
          return const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: sales),
              SizedBox(width: AppSpacing.lg),
              Expanded(child: recent),
            ],
          );
        }
        return const Column(
          children: [
            sales,
            SizedBox(height: AppSpacing.lg),
            recent,
          ],
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.icon,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final String title;
  final IconData icon;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 220,
            child: AppEmptyState(
              icon: icon,
              title: emptyTitle,
              message: emptyMessage,
            ),
          ),
        ],
      ),
    );
  }
}
