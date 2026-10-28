import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/widgets/app_bar_chart.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_card.dart';
import 'package:billforge/core/widgets/app_stat_card.dart';
import 'package:billforge/features/reports/domain/report_models.dart';

/// Renders any [ReportDocument]: summary cards, chart, tables and notes, with
/// export buttons.
class ReportView extends StatelessWidget {
  const ReportView({
    required this.document,
    required this.onCopyCsv,
    required this.onSharePdf,
    super.key,
  });

  final ReportDocument document;
  final VoidCallback onCopyCsv;
  final VoidCallback onSharePdf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xl,
      children: [
        Wrap(
          alignment: WrapAlignment.end,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            AppButton(
              label: 'Copy CSV',
              icon: Icons.copy_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: onCopyCsv,
            ),
            AppButton(
              label: 'Share PDF',
              icon: Icons.picture_as_pdf_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: onSharePdf,
            ),
          ],
        ),
        if (document.metrics.isNotEmpty)
          LayoutBuilder(
            builder: (context, box) {
              const gap = AppSpacing.lg;
              final columns = box.maxWidth >= 900
                  ? 4
                  : (box.maxWidth >= 600 ? 3 : (box.maxWidth >= 420 ? 2 : 1));
              final width = (box.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final m in document.metrics)
                    SizedBox(
                      width: width,
                      child: AppStatCard(
                        label: m.label,
                        value: m.value.text,
                        icon: Icons.bar_chart_rounded,
                      ),
                    ),
                ],
              );
            },
          ),
        if (document.chart.isNotEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (document.chartTitle != null) ...[
                  Text(
                    document.chartTitle!,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                AppBarChart(
                  items: [
                    for (final p in document.chart)
                      BarChartItem(
                        label: p.label,
                        value: p.valuePaise,
                        tooltip: p.tooltip,
                      ),
                  ],
                  emptyMessage: 'No sales in this period',
                ),
              ],
            ),
          ),
        for (final section in document.sections)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(section.title, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              ReportTableView(table: section.table),
            ],
          ),
        if (document.notes.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xs,
            children: [
              for (final note in document.notes)
                Text(
                  note,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
            ],
          ),
      ],
    );
  }
}

class ReportTableView extends StatelessWidget {
  const ReportTableView({required this.table, this.maxRows = 200, super.key});

  final ReportTable table;

  /// Longer tables are cut on screen. The exports always contain every row.
  final int maxRows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    if (table.rows.isEmpty) {
      return AppCard(
        child: Text(
          'No data for this period.',
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
      );
    }

    final shown = table.rows.take(maxRows).toList();
    final hidden = table.rows.length - shown.length;
    final footer = table.footer;

    Widget row(List<String> texts, {TextStyle? style, Color? background}) =>
        Container(
          color: background,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              for (var i = 0; i < texts.length; i++)
                Expanded(
                  flex: i == 0 ? 3 : 2,
                  child: Align(
                    alignment: table.columns[i].numeric
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Text(
                      texts[i],
                      style: style,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        );

    return AppCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, box) {
          final minWidth = math.max(520.0, table.columns.length * 110.0);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: math.max(box.maxWidth, minWidth),
              child: Column(
                children: [
                  row(
                    [for (final c in table.columns) c.label],
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Divider(),
                  for (final r in shown) ...[
                    row([
                      for (final c in r) c.text,
                    ], style: theme.textTheme.bodyMedium),
                    const Divider(),
                  ],
                  if (hidden > 0)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        '$hidden more rows are included when you export.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                    ),
                  if (footer != null)
                    row(
                      [for (final c in footer) c.text],
                      style: theme.textTheme.titleSmall,
                      background: theme.colorScheme.surfaceContainerHighest,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
