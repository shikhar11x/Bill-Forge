import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_colors.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/utils/quantity.dart';
import 'package:billforge/features/billing/domain/bill_calculator.dart';
import 'package:billforge/features/billing/domain/cart_line.dart';
import 'package:billforge/features/billing/domain/discount.dart';

class CartLineTile extends StatelessWidget {
  const CartLineTile({
    required this.line,
    required this.amounts,
    required this.onEdit,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    super.key,
  });

  final CartLine line;
  final LineAmounts amounts;
  final VoidCallback onEdit;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final detail = StringBuffer(
      '${formatPaise(line.unitPricePaise)} × ${formatMilli(line.qtyMilli)} ${line.unit.symbol}',
    );
    if (!line.discount.isNone) {
      detail.write(' · ${describeDiscount(line.discount)} off');
    }

    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    line.name,
                    style: theme.textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  formatPaise(amounts.totalPaise),
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              detail.toString(),
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            if (line.exceedsStock)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'Only ${formatMilli(line.stockMilli < 0 ? 0 : line.stockMilli)} ${line.unit.symbol} in stock',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                IconButton.outlined(
                  tooltip: 'Decrease quantity',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.remove_rounded, size: 18),
                  onPressed: onDecrement,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text(
                    formatMilli(line.qtyMilli),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                IconButton.outlined(
                  tooltip: 'Increase quantity',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  onPressed: onIncrement,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Remove item',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  onPressed: onRemove,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
