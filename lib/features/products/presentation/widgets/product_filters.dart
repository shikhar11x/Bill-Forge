import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/utils/async_value_x.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_dropdown.dart';
import 'package:billforge/features/products/application/product_providers.dart';
import 'package:billforge/features/products/domain/category.dart';
import 'package:billforge/features/products/domain/product_query.dart';
import 'package:billforge/features/products/presentation/widgets/category_dialogs.dart';

const _allCategories = '__all__';

/// Category, stock and archive filters. Laid out as a wrapping row inline,
/// or as a column inside a bottom sheet ([inSheet]).
class ProductFilterControls extends ConsumerWidget {
  const ProductFilterControls({this.inSheet = false, super.key});

  final bool inSheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(productQueryProvider);
    final notifier = ref.read(productQueryProvider.notifier);
    final categories =
        ref.watch(categoriesProvider).dataOrNull ?? const <Category>[];
    final names = {for (final c in categories) c.id: c.name};
    final selected = names.containsKey(query.categoryId)
        ? query.categoryId!
        : _allCategories;
    final hasFilters =
        query.categoryId != null ||
        query.stockFilter != StockFilter.all ||
        query.showArchived;

    final children = <Widget>[
      SizedBox(
        width: inSheet ? null : 240,
        child: AppDropdown<String>(
          key: ValueKey('category-$selected-${categories.length}'),
          label: 'Category',
          value: selected,
          items: [_allCategories, ...names.keys],
          itemLabel: (id) =>
              id == _allCategories ? 'All categories' : (names[id] ?? ''),
          onChanged: (v) =>
              notifier.setCategory(v == null || v == _allCategories ? null : v),
        ),
      ),
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stock',
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<StockFilter>(
            showSelectedIcon: false,
            expandedInsets: inSheet ? EdgeInsets.zero : null,
            segments: const [
              ButtonSegment(value: StockFilter.all, label: Text('All')),
              ButtonSegment(
                value: StockFilter.low,
                label: Text('Low'),
                tooltip: 'Low-stock products',
              ),
              ButtonSegment(
                value: StockFilter.out,
                label: Text('Out'),
                tooltip: 'Out-of-stock products',
              ),
            ],
            selected: {query.stockFilter},
            onSelectionChanged: (s) => notifier.setStockFilter(s.first),
          ),
        ],
      ),
      FilterChip(
        label: const Text('Archived'),
        selected: query.showArchived,
        onSelected: notifier.setShowArchived,
      ),
      if (hasFilters)
        TextButton(
          onPressed: notifier.clearFilters,
          child: const Text('Clear filters'),
        ),
      if (inSheet)
        AppButton(
          label: 'Manage categories',
          variant: AppButtonVariant.secondary,
          icon: Icons.label_outline_rounded,
          expanded: true,
          onPressed: () => ManageCategoriesDialog.show(context),
        ),
    ];

    if (inSheet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.lg,
        children: children,
      );
    }
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.md,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: children,
    );
  }
}
