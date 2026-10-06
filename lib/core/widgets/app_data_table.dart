import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/widgets/app_card.dart';

class AppColumn<T> {
  const AppColumn({
    required this.label,
    required this.cell,
    this.flex = 1,
    this.alignment = Alignment.centerLeft,
  });

  final String label;
  final Widget Function(BuildContext context, T item) cell;
  final int flex;
  final AlignmentGeometry alignment;
}

/// Lazy, scrollable table for large lists. Fills the height it is given, so
/// place it inside an `Expanded`.
class AppDataTable<T> extends StatelessWidget {
  const AppDataTable({
    required this.columns,
    required this.rows,
    this.controller,
    this.onRowTap,
    this.trailing,
    this.showLoadingRow = false,
    super.key,
  });

  static const _trailingWidth = 48.0;

  final List<AppColumn<T>> columns;
  final List<T> rows;
  final ScrollController? controller;
  final ValueChanged<T>? onRowTap;
  final Widget Function(BuildContext context, T item)? trailing;
  final bool showLoadingRow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final header = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          for (final c in columns)
            Expanded(
              flex: c.flex,
              child: Align(
                alignment: c.alignment,
                child: Text(
                  c.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (trailing != null) const SizedBox(width: _trailingWidth),
        ],
      ),
    );

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          header,
          const Divider(),
          Expanded(
            child: ListView.separated(
              controller: controller,
              itemCount: rows.length + (showLoadingRow ? 1 : 0),
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                if (index >= rows.length) {
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
                final item = rows[index];
                return InkWell(
                  onTap: onRowTap == null ? null : () => onRowTap!(item),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 56),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          for (final c in columns)
                            Expanded(
                              flex: c.flex,
                              child: Align(
                                alignment: c.alignment,
                                child: c.cell(context, item),
                              ),
                            ),
                          if (trailing != null)
                            SizedBox(
                              width: _trailingWidth,
                              child: trailing!(context, item),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
