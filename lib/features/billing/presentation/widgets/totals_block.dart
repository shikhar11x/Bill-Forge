import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/features/billing/domain/totals_rows.dart';

export 'package:billforge/features/billing/domain/totals_rows.dart';

class TotalsBlock extends StatelessWidget {
  const TotalsBlock({required this.rows, required this.totalPaise, super.key});

  final List<TotalsRow> rows;
  final int totalPaise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    row.label,
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                ),
                Text(formatPaise(row.paise), style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        if (rows.isNotEmpty) const Divider(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(child: Text('Total', style: theme.textTheme.titleMedium)),
            Text(
              formatPaise(totalPaise),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}