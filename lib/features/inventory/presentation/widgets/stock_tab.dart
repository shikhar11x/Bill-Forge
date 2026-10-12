import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/responsive/breakpoints.dart';
import 'package:billforge/core/responsive/responsive_builder.dart';
import 'package:billforge/core/utils/app_logger.dart';
import 'package:billforge/core/utils/async_value_x.dart';
import 'package:billforge/core/utils/quantity.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_card.dart';
import 'package:billforge/core/widgets/app_data_table.dart';
import 'package:billforge/core/widgets/app_empty_state.dart';
import 'package:billforge/core/widgets/app_error_state.dart';
import 'package:billforge/core/widgets/app_search_field.dart';
import 'package:billforge/core/widgets/app_skeleton.dart';
import 'package:billforge/core/widgets/app_toast.dart';
import 'package:billforge/features/inventory/application/inventory_providers.dart';
import 'package:billforge/features/inventory/presentation/widgets/adjust_stock_dialog.dart';
import 'package:billforge/features/products/domain/product.dart';
import 'package:billforge/features/products/domain/product_query.dart';
import 'package:billforge/features/products/presentation/widgets/product_list_items.dart';

enum _StockAction { adjust, history }

class StockTab extends ConsumerStatefulWidget {
  const StockTab({super.key});

  @override
  ConsumerState<StockTab> createState() => _StockTabState();
}

class _StockTabState extends ConsumerState<StockTab> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _search.text = ref.read(inventoryQueryProvider).search;
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
    final items = ref.read(inventoryProductsProvider).dataOrNull;
    final limit = ref.read(inventoryQueryProvider).limit;
    if (items != null && items.length >= limit) {
      ref.read(inventoryQueryProvider.notifier).loadMore();
    }
  }

  Future<void> _adjust(Product product) async {
    final changed = await AdjustStockDialog.show(context, product);
    if (changed == true && mounted) {
      AppToast.show(context, 'Stock updated', type: ToastType.success);
    }
  }

  void _history(Product product) =>
      context.push(AppRoutes.stockHistory(product.id));

  void _onAction(Product product, _StockAction action) {
    switch (action) {
      case _StockAction.adjust:
        _adjust(product);
      case _StockAction.history:
        _history(product);
    }
  }

  Widget _menu(Product product) => PopupMenuButton<_StockAction>(
    tooltip: 'Stock actions',
    icon: const Icon(Icons.more_vert_rounded),
    onSelected: (a) => _onAction(product, a),
    itemBuilder: (context) => [
      PopupMenuItem(
        value: _StockAction.adjust,
        enabled: product.trackStock,
        child: const Text('Adjust stock'),
      ),
      const PopupMenuItem(
        value: _StockAction.history,
        child: Text('Stock history'),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    ref.listen(inventoryProductsProvider, (previous, next) {
      if (next.hasError) {
        AppLogger.error(
          'Could not load stock',
          error: next.error,
          stackTrace: next.stackTrace,
        );
      }
    });

    final query = ref.watch(inventoryQueryProvider);
    final notifier = ref.read(inventoryQueryProvider.notifier);

    return ResponsiveBuilder(
      builder: (context, size) {
        final search = AppSearchField(
          controller: _search,
          hint: 'Search by name, SKU or barcode',
          onChanged: notifier.setSearch,
        );
        final filter = SegmentedButton<StockFilter>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: StockFilter.attention,
              label: Text('Needs attention'),
            ),
            ButtonSegment(value: StockFilter.all, label: Text('All stock')),
          ],
          selected: {query.stockFilter},
          onSelectionChanged: (s) => notifier.setStockFilter(s.first),
        );

        final toolbar = size.isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  search,
                  const SizedBox(height: AppSpacing.md),
                  filter,
                ],
              )
            : Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: AppSpacing.md),
                  filter,
                ],
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            toolbar,
            const SizedBox(height: AppSpacing.lg),
            Expanded(child: _content(size)),
          ],
        );
      },
    );
  }

  Widget _content(ScreenSize size) {
    final async = ref.watch(inventoryProductsProvider);
    final query = ref.watch(inventoryQueryProvider);
    final items = async.dataOrNull;

    if (items == null) {
      if (async.hasError) {
        return AppErrorState(
          message: const StorageFailure().message,
          onRetry: () => ref.invalidate(inventoryProductsProvider),
        );
      }
      return const AppListSkeleton();
    }

    if (items.isEmpty) {
      final searching = query.search.trim().isNotEmpty;
      if (searching) {
        return AppEmptyState(
          icon: Icons.search_off_rounded,
          title: 'No products found',
          message: 'Try a different search.',
          action: AppButton(
            label: 'Clear search',
            variant: AppButtonVariant.secondary,
            onPressed: () {
              _search.clear();
              ref.read(inventoryQueryProvider.notifier).setSearch('');
            },
          ),
        );
      }
      if (query.stockFilter == StockFilter.attention) {
        return const AppEmptyState(
          icon: Icons.check_circle_outline_rounded,
          title: 'Stock looks good',
          message: 'No product is low or out of stock.',
        );
      }
      return const AppEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No products yet',
        message: 'Add products in the Products section first.',
      );
    }

    final loadingMore = async.isLoading;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    if (size.isMobile) {
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
            onTap: () => _history(p),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: theme.textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (p.sku != null)
                        Text(
                          p.sku!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      StockLabel(product: p),
                    ],
                  ),
                ),
                _menu(p),
              ],
            ),
          );
        },
      );
    }

    return AppDataTable<Product>(
      controller: _scroll,
      rows: items,
      showLoadingRow: loadingMore,
      onRowTap: _history,
      columns: [
        AppColumn<Product>(
          label: 'Product',
          flex: 4,
          cell: (context, p) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.name,
                style: theme.textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (p.sku != null)
                Text(
                  p.sku!,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
            ],
          ),
        ),
        AppColumn<Product>(
          label: 'Stock',
          flex: 2,
          alignment: Alignment.centerRight,
          cell: (context, p) => StockLabel(product: p),
        ),
        AppColumn<Product>(
          label: 'Alert at',
          flex: 2,
          alignment: Alignment.centerRight,
          cell: (context, p) => Text(
            p.trackStock
                ? '${formatMilli(p.lowStockThresholdMilli)} ${p.unit.symbol}'
                : '—',
          ),
        ),
      ],
      trailing: (context, p) => _menu(p),
    );
  }
}
