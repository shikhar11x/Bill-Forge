import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/theme/app_colors.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/utils/app_logger.dart';
import 'package:billforge/core/utils/async_value_x.dart';
import 'package:billforge/core/utils/date_format.dart';
import 'package:billforge/core/utils/quantity.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_card.dart';
import 'package:billforge/core/widgets/app_empty_state.dart';
import 'package:billforge/core/widgets/app_error_state.dart';
import 'package:billforge/core/widgets/app_toast.dart';
import 'package:billforge/features/inventory/application/inventory_providers.dart';
import 'package:billforge/features/inventory/domain/inventory_queries.dart';
import 'package:billforge/features/inventory/domain/movement_type.dart';
import 'package:billforge/features/inventory/domain/stock_movement.dart';
import 'package:billforge/features/inventory/presentation/widgets/adjust_stock_dialog.dart';
import 'package:billforge/features/products/application/product_providers.dart';
import 'package:billforge/features/products/domain/product.dart';
import 'package:billforge/features/products/presentation/widgets/product_list_items.dart';

class StockHistoryPage extends ConsumerStatefulWidget {
  const StockHistoryPage({required this.productId, super.key});

  final String productId;

  @override
  ConsumerState<StockHistoryPage> createState() => _StockHistoryPageState();
}

class _StockHistoryPageState extends ConsumerState<StockHistoryPage> {
  final _scroll = ScrollController();
  int _limit = kMovementPageSize;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients || _scroll.position.extentAfter > 400) return;
    final items = ref
        .read(stockMovementsProvider((widget.productId, _limit)))
        .dataOrNull;
    if (items != null && items.length >= _limit) {
      setState(() => _limit += kMovementPageSize);
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.inventory);
    }
  }

  Future<void> _adjust(Product product) async {
    final changed = await AdjustStockDialog.show(context, product);
    if (changed == true && mounted) {
      ref.invalidate(productByIdProvider(widget.productId));
      AppToast.show(context, 'Stock updated', type: ToastType.success);
    }
  }

  void _openSource(StockMovement m) {
    final id = m.refId;
    if (id == null) return;
    if (m.refType == StockRef.invoice) context.push(AppRoutes.invoice(id));
    if (m.refType == StockRef.purchase) context.push(AppRoutes.purchase(id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productAsync = ref.watch(productByIdProvider(widget.productId));

    return productAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (error, stack) => AppErrorState(
        message: const StorageFailure().message,
        onRetry: () => ref.invalidate(productByIdProvider(widget.productId)),
      ),
      data: (product) {
        if (product == null) {
          return AppEmptyState(
            icon: Icons.search_off_rounded,
            title: 'Product not found',
            action: AppButton(
              label: 'Back to inventory',
              variant: AppButtonVariant.secondary,
              onPressed: () => context.go(AppRoutes.inventory),
            ),
          );
        }

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
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
                        onPressed: _back,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          product.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current stock',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              StockLabel(product: product),
                            ],
                          ),
                        ),
                        AppButton(
                          label: 'Adjust stock',
                          variant: AppButtonVariant.secondary,
                          onPressed: product.trackStock
                              ? () => _adjust(product)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: _history(product)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _history(Product product) {
    final args = (widget.productId, _limit);
    final async = ref.watch(stockMovementsProvider(args));
    final items = async.dataOrNull;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    if (items == null) {
      if (async.hasError) {
        AppLogger.error(
          'Could not load stock history',
          error: async.error,
          stackTrace: async.stackTrace,
        );
        return AppErrorState(
          message: const StorageFailure().message,
          onRetry: () => ref.invalidate(stockMovementsProvider(args)),
        );
      }
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (items.isEmpty) {
      return AppEmptyState(
        icon: Icons.history_rounded,
        title: 'No stock movements yet',
        message: product.trackStock
            ? 'Purchases, sales and adjustments will be listed here.'
            : 'Stock tracking is off for this product.',
      );
    }

    final unit = product.unit.symbol;
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        controller: _scroll,
        itemCount: items.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (context, i) {
          final m = items[i];
          final color = m.isIncrease ? AppColors.success : AppColors.danger;
          final sign = m.isIncrease ? '+' : '';
          final subtitle = [
            formatDateTime(m.createdAt),
            if (m.note != null) m.note!,
          ].join(' · ');
          return ListTile(
            onTap: m.refId == null ? null : () => _openSource(m),
            title: Text(m.title),
            subtitle: Text(
              subtitle,
              style: TextStyle(color: muted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$sign${formatMilli(m.qtyMilli)} $unit',
                  style: theme.textTheme.titleSmall?.copyWith(color: color),
                ),
                Text(
                  'Balance ${formatMilli(m.balanceAfterMilli)} $unit',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}