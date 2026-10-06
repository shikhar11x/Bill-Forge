import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/utils/app_logger.dart';
import 'package:billforge/core/utils/async_value_x.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/utils/quantity.dart';
import 'package:billforge/core/widgets/app_badge.dart';
import 'package:billforge/core/widgets/app_card.dart';
import 'package:billforge/core/widgets/app_empty_state.dart';
import 'package:billforge/core/widgets/app_error_state.dart';
import 'package:billforge/core/widgets/app_search_field.dart';
import 'package:billforge/core/widgets/app_skeleton.dart';
import 'package:billforge/core/widgets/app_toast.dart';
import 'package:billforge/features/billing/application/bill_controller.dart';
import 'package:billforge/features/billing/application/billing_providers.dart';
import 'package:billforge/features/products/application/product_providers.dart';
import 'package:billforge/features/products/domain/product.dart';
import 'package:billforge/features/products/domain/product_query.dart';

class ProductPicker extends ConsumerStatefulWidget {
  const ProductPicker({this.autofocus = false, super.key});

  final bool autofocus;

  @override
  ConsumerState<ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends ConsumerState<ProductPicker> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  final _focus = FocusNode();

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
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients || _scroll.position.extentAfter > 400) return;
    final items = ref.read(billProductsProvider).dataOrNull;
    final limit = ref.read(billProductQueryProvider).limit;
    if (items != null && items.length >= limit) {
      ref.read(billProductQueryProvider.notifier).loadMore();
    }
  }

  void _add(Product product) =>
      ref.read(billControllerProvider.notifier).addProduct(product);

  /// Enter pressed: a scanner finished a code, or the user wants the top hit.
  Future<void> _submit(String value) async {
    final code = value.trim();
    if (code.isEmpty) {
      _focus.requestFocus();
      return;
    }
    try {
      final matches = await ref
          .read(productRepositoryProvider)
          .watchProducts(ProductQuery(search: code, limit: 5))
          .first;
      final lower = code.toLowerCase();
      Product? hit;
      for (final p in matches) {
        if ((p.barcode ?? '').toLowerCase() == lower ||
            (p.sku ?? '').toLowerCase() == lower) {
          hit = p;
          break;
        }
      }
      hit ??= matches.length == 1 ? matches.first : null;

      if (!mounted) return;
      if (hit == null) {
        AppToast.show(
          context,
          matches.isEmpty
              ? 'No product matches "$code"'
              : 'Several products match. Tap the one you want.',
        );
      } else {
        _add(hit);
        _search.clear();
        ref.read(billProductQueryProvider.notifier).setSearch('');
      }
    } catch (error, stack) {
      AppLogger.error('Product lookup failed', error: error, stackTrace: stack);
      if (!mounted) return;
      AppToast.show(
        context,
        const StorageFailure().message,
        type: ToastType.error,
      );
    }
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(billProductQueryProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSearchField(
          controller: _search,
          focusNode: _focus,
          autofocus: widget.autofocus,
          hint: 'Search or scan: name, SKU, barcode',
          onChanged: notifier.setSearch,
          onSubmitted: _submit,
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(child: _results()),
      ],
    );
  }

  Widget _results() {
    final async = ref.watch(billProductsProvider);
    final query = ref.watch(billProductQueryProvider);
    final items = async.dataOrNull;

    if (items == null) {
      if (async.hasError) {
        return AppErrorState(
          message: const StorageFailure().message,
          onRetry: () => ref.invalidate(billProductsProvider),
        );
      }
      return const AppListSkeleton();
    }

    if (items.isEmpty) {
      return query.search.trim().isEmpty
          ? const AppEmptyState(
              icon: Icons.category_outlined,
              title: 'No products yet',
              message: 'Add products in the Products section to start billing.',
            )
          : const AppEmptyState(
              icon: Icons.search_off_rounded,
              title: 'No products found',
              message: 'Try a different name, SKU or barcode.',
            );
    }

    return ListView.separated(
      controller: _scroll,
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) =>
          _ProductTile(product: items[i], onTap: () => _add(items[i])),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    Widget stock = const SizedBox.shrink();
    if (product.trackStock) {
      stock = product.isOutOfStock
          ? const AppBadge(label: 'Out of stock', tone: BadgeTone.danger)
          : Text(
              '${formatMilli(product.stockMilli)} ${product.unit.symbol} in stock',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            );
    }

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: theme.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.md,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${formatPaise(product.sellingPricePaise)} / ${product.unit.symbol}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    stock,
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Icon(
            Icons.add_circle_outline_rounded,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
