import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/responsive/responsive_builder.dart';
import 'package:billforge/core/utils/app_logger.dart';
import 'package:billforge/core/utils/async_value_x.dart';
import 'package:billforge/core/utils/date_format.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_card.dart';
import 'package:billforge/core/widgets/app_data_table.dart';
import 'package:billforge/core/widgets/app_empty_state.dart';
import 'package:billforge/core/widgets/app_error_state.dart';
import 'package:billforge/core/widgets/app_search_field.dart';
import 'package:billforge/core/widgets/app_skeleton.dart';
import 'package:billforge/features/inventory/application/inventory_providers.dart';
import 'package:billforge/features/inventory/domain/purchase.dart';

class PurchasesTab extends ConsumerStatefulWidget {
  const PurchasesTab({super.key});

  @override
  ConsumerState<PurchasesTab> createState() => _PurchasesTabState();
}

class _PurchasesTabState extends ConsumerState<PurchasesTab> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _search.text = ref.read(purchaseQueryProvider).search;
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients || _scroll.position.extentAfter > 400) return;
    final items = ref.read(purchasesProvider).dataOrNull;
    final limit = ref.read(purchaseQueryProvider).limit;
    if (items != null && items.length >= limit) {
      ref.read(purchaseQueryProvider.notifier).loadMore();
    }
  }

  void _new() => context.push(AppRoutes.purchaseNew);

  void _open(Purchase purchase) =>
      context.push(AppRoutes.purchase(purchase.id));

  @override
  Widget build(BuildContext context) {
    ref.listen(purchasesProvider, (previous, next) {
      if (next.hasError) {
        AppLogger.error(
          'Could not load purchases',
          error: next.error,
          stackTrace: next.stackTrace,
        );
      }
    });

    final notifier = ref.read(purchaseQueryProvider.notifier);

    return ResponsiveBuilder(
      builder: (context, size) {
        final search = AppSearchField(
          controller: _search,
          hint: 'Search by supplier or bill number',
          onChanged: notifier.setSearch,
        );
        final add = AppButton(
          label: 'New purchase',
          icon: Icons.add_rounded,
          expanded: size.isMobile,
          onPressed: _new,
        );
        final toolbar = size.isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  search,
                  const SizedBox(height: AppSpacing.md),
                  add,
                ],
              )
            : Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: AppSpacing.md),
                  add,
                ],
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            toolbar,
            const SizedBox(height: AppSpacing.lg),
            Expanded(child: _content(size.isMobile)),
          ],
        );
      },
    );
  }

  Widget _content(bool mobile) {
    final async = ref.watch(purchasesProvider);
    final query = ref.watch(purchaseQueryProvider);
    final items = async.dataOrNull;

    if (items == null) {
      if (async.hasError) {
        return AppErrorState(
          message: const StorageFailure().message,
          onRetry: () => ref.invalidate(purchasesProvider),
        );
      }
      return const AppListSkeleton();
    }

    if (items.isEmpty) {
      if (query.search.trim().isNotEmpty) {
        return AppEmptyState(
          icon: Icons.search_off_rounded,
          title: 'No purchases found',
          message: 'Try a different search.',
          action: AppButton(
            label: 'Clear search',
            variant: AppButtonVariant.secondary,
            onPressed: () {
              _search.clear();
              ref.read(purchaseQueryProvider.notifier).setSearch('');
            },
          ),
        );
      }
      return AppEmptyState(
        icon: Icons.local_shipping_outlined,
        title: 'No purchases yet',
        message: 'Record stock you buy from suppliers to keep counts accurate.',
        action: AppButton(
          label: 'New purchase',
          icon: Icons.add_rounded,
          onPressed: _new,
        ),
      );
    }

    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final loadingMore = async.isLoading;

    if (mobile) {
      return ListView.separated(
        controller: _scroll,
        itemCount: items.length + (loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) {
          if (i >= items.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final p = items[i];
          return AppCard(
            onTap: () => _open(p),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.supplierName ?? 'No supplier',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        [
                          formatDate(p.purchasedAt),
                          if (p.billNumber != null) 'Bill ${p.billNumber}',
                        ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatPaise(p.totalPaise),
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
          );
        },
      );
    }

    return AppDataTable<Purchase>(
      controller: _scroll,
      rows: items,
      showLoadingRow: loadingMore,
      onRowTap: _open,
      columns: [
        AppColumn<Purchase>(
          label: 'Date',
          flex: 2,
          cell: (context, p) => Text(formatDate(p.purchasedAt)),
        ),
        AppColumn<Purchase>(
          label: 'Supplier',
          flex: 3,
          cell: (context, p) => Text(
            p.supplierName ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppColumn<Purchase>(
          label: 'Bill number',
          flex: 2,
          cell: (context, p) => Text(p.billNumber ?? '—'),
        ),
        AppColumn<Purchase>(
          label: 'Total',
          flex: 2,
          alignment: Alignment.centerRight,
          cell: (context, p) => Text(formatPaise(p.totalPaise)),
        ),
      ],
    );
  }
}
