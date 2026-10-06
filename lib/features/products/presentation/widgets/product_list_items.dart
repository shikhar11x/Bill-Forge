import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/utils/quantity.dart';
import 'package:billforge/core/widgets/app_badge.dart';
import 'package:billforge/core/widgets/app_card.dart';
import 'package:billforge/features/products/domain/product.dart';

class StockLabel extends StatelessWidget {
  const StockLabel({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    if (!product.trackStock) {
      return Text('Not tracked', style: TextStyle(color: muted));
    }
    final quantity =
        '${formatMilli(product.stockMilli)} ${product.unit.symbol}';
    if (product.isOutOfStock) {
      return const AppBadge(label: 'Out of stock', tone: BadgeTone.danger);
    }
    if (product.isLowStock) {
      return AppBadge(label: 'Low · $quantity', tone: BadgeTone.warning);
    }
    return Text(quantity);
  }
}

enum _MenuAction { edit, toggleArchive }

class ProductMenu extends StatelessWidget {
  const ProductMenu({
    required this.product,
    required this.onEdit,
    required this.onToggleArchive,
    super.key,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onToggleArchive;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MenuAction>(
      tooltip: 'Product actions',
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (action) {
        switch (action) {
          case _MenuAction.edit:
            onEdit();
          case _MenuAction.toggleArchive:
            onToggleArchive();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _MenuAction.edit,
          child: _MenuRow(icon: Icons.edit_outlined, label: 'Edit'),
        ),
        PopupMenuItem(
          value: _MenuAction.toggleArchive,
          child: _MenuRow(
            icon: product.isArchived
                ? Icons.unarchive_outlined
                : Icons.archive_outlined,
            label: product.isArchived ? 'Restore' : 'Archive',
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: AppSpacing.md),
        Text(label),
      ],
    );
  }
}

/// Mobile list item.
class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    required this.categoryName,
    required this.onTap,
    required this.onToggleArchive,
    super.key,
  });

  final Product product;
  final String? categoryName;
  final VoidCallback onTap;
  final VoidCallback onToggleArchive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final subtitle = [
      categoryName,
      product.sku,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

    return AppCard(
      onTap: onTap,
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
                  product.name,
                  style: theme.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.md,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      formatPaise(product.sellingPricePaise),
                      style: theme.textTheme.titleSmall,
                    ),
                    StockLabel(product: product),
                  ],
                ),
              ],
            ),
          ),
          ProductMenu(
            product: product,
            onEdit: onTap,
            onToggleArchive: onToggleArchive,
          ),
        ],
      ),
    );
  }
}
