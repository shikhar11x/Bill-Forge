import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/utils/formatters.dart';

class TotalsRow {
  const TotalsRow(this.label, this.paise);

  final String label;
  final int paise;
}

/// Only rows that carry information are returned: no zero discount, no tax
/// lines for tax-free bills, no zero round-off.
List<TotalsRow> buildTotalsRows({
  required int discountPaise,
  required int taxablePaise,
  required int cgstPaise,
  required int sgstPaise,
  required int igstPaise,
  required int roundOffPaise,
}) {
  return [
    if (discountPaise > 0) TotalsRow('Discount', -discountPaise),
    if (cgstPaise + sgstPaise + igstPaise > 0) ...[
      TotalsRow('Taxable value', taxablePaise),
      if (igstPaise > 0)
        TotalsRow('IGST', igstPaise)
      else ...[
        TotalsRow('CGST', cgstPaise),
        TotalsRow('SGST', sgstPaise),
      ],
    ],
    if (roundOffPaise != 0) TotalsRow('Round off', roundOffPaise),
  ];
}

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
