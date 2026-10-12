import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/utils/quantity.dart';
import 'package:billforge/core/widgets/app_empty_state.dart';
import 'package:billforge/core/widgets/app_error_state.dart';
import 'package:billforge/core/widgets/app_search_field.dart';
import 'package:billforge/features/inventory/application/inventory_providers.dart';
import 'package:billforge/features/products/domain/product.dart';

/// Pick one product. Resolves to null when closed without choosing.
class ProductSearchDialog extends ConsumerStatefulWidget {
  const ProductSearchDialog({super.key});

  static Future<Product?> show(BuildContext context) => showDialog<Product>(
        context: context,
        builder: (_) => const ProductSearchDialog(),
      );

  @override
  ConsumerState<ProductSearchDialog> createState() =>
      _ProductSearchDialogState();
}

class _ProductSearchDialogState extends ConsumerState<ProductSearchDialog> {
  final _controller = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final products = ref.watch(productSearchProvider(_search));

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Select product', style: theme.textTheme.titleMedium),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AppSearchField(
                controller: _controller,
                autofocus: true,
                hint: 'Search by name, SKU or barcode',
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            Flexible(
              child: products.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (error, stack) => AppErrorState(
                  message: const StorageFailure().message,
                  onRetry: () => ref.invalidate(productSearchProvider(_search)),
                ),
                data: (items) => items.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No products found',
                        message: 'Try a different search.',
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, i) {
                          final p = items[i];
                          return ListTile(
                            title: Text(p.name),
                            subtitle: Text(
                              p.trackStock
                                  ? '${formatMilli(p.stockMilli)} ${p.unit.symbol} in stock'
                                  : 'Stock not tracked',
                              style: TextStyle(color: muted),
                            ),
                            onTap: () => Navigator.of(context).pop(p),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}