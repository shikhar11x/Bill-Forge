import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/motion/app_motion.dart';

class BarChartItem {
  const BarChartItem({required this.label, required this.value, this.tooltip});

  final String label;

  /// Bar height is proportional to this. Negative values are drawn as zero.
  final int value;
  final String? tooltip;
}

/// A simple bar chart: one bar per item, scaled to the tallest bar. The bars
/// grow in one after another whenever the data changes. Labels are thinned
/// out when there are many bars. Hover or long-press shows the tooltip.
class AppBarChart extends StatelessWidget {
  const AppBarChart({
    required this.items,
    this.height = 160,
    this.emptyMessage = 'No data for this period',
    super.key,
  });

  final List<BarChartItem> items;
  final double height;
  final String emptyMessage;

  /// 0 to 1: how far bar [index] has grown at overall [progress]. Each bar
  /// starts a little after the one before it.
  static double _grown({
    required double progress,
    required int index,
    required int count,
  }) {
    final start = count <= 1 ? 0.0 : 0.4 * index / count;
    final local = ((progress - start) / 0.6).clamp(0.0, 1.0).toDouble();
    return Curves.easeOutCubic.transform(local);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tallest = items.fold<int>(0, (m, i) => math.max(m, i.value));

    if (items.isEmpty || tallest <= 0) {
      return SizedBox(
        height: height + 24,
        child: Center(
          child: Text(
            emptyMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final labelEvery = math.max(1, (items.length / 8).ceil());
    // A new key replays the growth when the data changes.
    final signature = Object.hashAll([
      items.length,
      ...items.map((i) => i.value),
    ]);

    return Semantics(
      label: 'Bar chart with ${items.length} bars',
      child: SizedBox(
        height: height + 24,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(signature),
          tween: Tween<double>(begin: 0, end: 1),
          duration: AppMotion.of(context, const Duration(milliseconds: 700)),
          builder: (context, progress, _) => Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Tooltip(
                      message: items[i].tooltip ?? items[i].label,
                      child: Column(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: items[i].value <= 0
                                    ? 0
                                    : math.max(0.02, items[i].value / tallest) *
                                        _grown(
                                          progress: progress,
                                          index: i,
                                          count: items.length,
                                        ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        scheme.primary,
                                        scheme.primary.withValues(alpha: 0.55),
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(AppRadius.sm),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          SizedBox(
                            height: 16,
                            child: i % labelEvery == 0
                                ? FittedBox(
                                    child: Text(
                                      items[i].label,
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}