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
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/widgets/app_bottom_sheet.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_data_table.dart';
import 'package:billforge/core/widgets/app_dialog.dart';
import 'package:billforge/core/widgets/app_empty_state.dart';
import 'package:billforge/core/widgets/app_error_state.dart';
import 'package:billforge/core/widgets/app_search_field.dart';
import 'package:billforge/core/widgets/app_skeleton.dart';
import 'package:billforge/core/widgets/app_toast.dart';
import 'package:billforge/app/theme/app_spacing.dart' as spacing;
import 'package:billforge/features/products/application/product_providers.dart';
import 'package:billforge/features/products/domain/product.dart';
import 'package:billforge/features/products/domain/product_query.dart';
import 'package:billforge/features/products/presentation/widgets/category_dialogs.dart';
import 'package:billforge/features/products/presentation/widgets/product_filters.dart';
import 'package:billforge/features/products/presentation/widgets/product_list_items.dart';
import 'package:billforge/features/shop/application/shop_providers.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    // Filters survive navigation; restore the search text with them.
    _search.text = ref.read(productQueryProvider).search;
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
    final items = ref.read(productsProvider).dataOrNull;
    final limit = ref.read(productQueryProvider).limit;
    // A full page means there may be more; a short page means we're done.
    if (items != null && items.length >= limit) {
      ref.read(productQueryProvider.notifier).loadMore();
    }
  }

  void _addProduct() => context.push(AppRoutes.productNew);

  void _edit(Product product) =>
      context.push(AppRoutes.productEdit(product.id));

  Future<void> _toggleArchive(Product product) async {
    final archive = !product.isArchived;
    if (archive) {
      final confirmed = await AppDialog.confirm(
        context,
        title: 'Archive "${product.name}"?',
        message: 'It will be hidden from product lists and billing. You can restore it from the Archived filter.',
        confirmLabel: 'Archive',
        destructive: true,
      );
      if (!confirmed) return;
    }
    try {
      await ref
          .read(productRepositoryProvider)
          .setArchived(product.id, archived: archive);
      if (!mounted) return;
      AppToast.show(
        context,
        archive ? 'Product archived' : 'Product restored',
        type: ToastType.success,
      );
    } catch (error, stack) {
      AppLogger.error('Archive failed', error: error, stackTrace: stack);
      if (!mounted) return;
      AppToast.show(
        context,
        const StorageFailure().message,
        type: ToastType.error,
      );
    }
  }

  void _resetAll() {
    _search.clear();
    ref.read(productQueryProvider.notifier).reset();
  }

  void _openFilters() {
    AppBottomSheet.show<void>(
      context,
      title: 'Filters',
      builder: (_) => const ProductFilterControls(inSheet: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(productsProvider, (previous, next) {
      if (next.hasError) {
        AppLogger.error(
          'Could not load products',
          error: next.error,
          stackTrace: next.stackTrace,
        );
      }
    });

    final query = ref.watch(productQueryProvider);
    final notifier = ref.read(productQueryProvider.notifier);
    final hasSheetFilters =
        query.categoryId != null ||
        query.stockFilter != StockFilter.all ||
        query.showArchived;

    return ResponsiveBuilder(
      builder: (context, size) {
        final wide = !size.isMobile;
        final toolbar = wide
            ? _wideToolbar(notifier)
            : _mobileToolbar(notifier, hasSheetFilters);

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: spacing.AppLayout.contentMaxWidth,
            ),
            child: Padding(
              padding: EdgeInsets.all(wide ? AppSpacing.xxl : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  toolbar,
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(child: _content(size)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _wideToolbar(ProductQueryNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppSearchField(
                controller: _search,
                hint: 'Search by name, SKU or barcode',
                onChanged: notifier.setSearch,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            AppButton(
              label: 'Categories',
              variant: AppButtonVariant.secondary,
              icon: Icons.label_outline_rounded,
              onPressed: () => ManageCategoriesDialog.show(context),
            ),
            const SizedBox(width: AppSpacing.md),
            AppButton(
              label: 'Add product',
              icon: Icons.add_rounded,
              onPressed: _addProduct,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const ProductFilterControls(),
      ],
    );
  }

  Widget _mobileToolbar(ProductQueryNotifier notifier, bool filtersActive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppSearchField(
                controller: _search,
                hint: 'Search products',
                onChanged: notifier.setSearch,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Badge(
              isLabelVisible: filtersActive,
              child: IconButton(
                tooltip: 'Filters',
                icon: const Icon(Icons.tune_rounded),
                onPressed: _openFilters,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Add product',
          icon: Icons.add_rounded,
          expanded: true,
          onPressed: _addProduct,
        ),
      ],
    );
  }

  Widget _content(ScreenSize size) {
    final async = ref.watch(productsProvider);
    final query = ref.watch(productQueryProvider);
    final items = async.dataOrNull;

    if (items == null) {
      if (async.hasError) {
        return AppErrorState(
          message: const StorageFailure().message,
          onRetry: () => ref.invalidate(productsProvider),
        );
      }
      return const AppListSkeleton();
    }

    if (items.isEmpty) {
      final filtered =
          query.search.trim().isNotEmpty ||
          query.categoryId != null ||
          query.stockFilter != StockFilter.all;
      if (query.showArchived && !filtered) {
        return const AppEmptyState(
          icon: Icons.archive_outlined,
          title: 'No archived products',
          message: 'Products you archive will appear here.',
        );
      }
      if (filtered || query.showArchived) {
        return AppEmptyState(
          icon: Icons.search_off_rounded,
          title: 'No products found',
          message: 'Try a different search or clear the filters.',
          action: AppButton(
            label: 'Clear search & filters',
            variant: AppButtonVariant.secondary,
            onPressed: _resetAll,
          ),
        );
      }
      return AppEmptyState(
        icon: Icons.category_outlined,
        title: 'Add your first product',
        message:
            'Products you add here are used for billing and stock tracking.',
        action: AppButton(
          label: 'Add product',
          icon: Icons.add_rounded,
          onPressed: _addProduct,
        ),
      );
    }

    final names = ref.watch(categoryNamesProvider);
    final loadingMore = async.isLoading;

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
          final product = items[i];
          return ProductCard(
            product: product,
            categoryName: names[product.categoryId],
            onTap: () => _edit(product),
            onToggleArchive: () => _toggleArchive(product),
          );
        },
      );
    }

    final showGst =
        shopOrNull(ref.watch(shopProfileProvider))
            ?.gstRegistration
            .chargesTax ??
        false;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return AppDataTable<Product>(
      controller: _scroll,
      rows: items,
      showLoadingRow: loadingMore,
      onRowTap: _edit,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        AppColumn<Product>(
          label: 'Category',
          flex: 2,
          cell: (context, p) => Text(
            names[p.categoryId] ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppColumn<Product>(
          label: 'Price',
          flex: 2,
          alignment: Alignment.centerRight,
          cell: (context, p) => Text(formatPaise(p.sellingPricePaise)),
        ),
        if (showGst)
          AppColumn<Product>(
            label: 'GST',
            flex: 1,
            alignment: Alignment.centerRight,
            cell: (context, p) => Text('${p.gstRatePercent}%'),
          ),
        AppColumn<Product>(
          label: 'Stock',
          flex: 2,
          alignment: Alignment.centerRight,
          cell: (context, p) => StockLabel(product: p),
        ),
      ],
      trailing: (context, p) => ProductMenu(
        product: p,
        onEdit: () => _edit(p),
        onToggleArchive: () => _toggleArchive(p),
      ),
    );
  }
}
