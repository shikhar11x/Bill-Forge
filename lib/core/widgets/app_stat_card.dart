import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/widgets/animated_count.dart';
import 'package:billforge/core/widgets/app_card.dart';

class AppStatCard extends StatelessWidget {
  const AppStatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.caption,
    this.animateTo,
    this.format,
    super.key,
  });

  final String label;

  /// What is shown, and what screen readers announce.
  final String value;
  final IconData icon;
  final String? caption;

  /// When both are set, the number counts up to [animateTo] shown through
  /// [format]. Leave them out to show [value] as plain text.
  final int? animateTo;
  final String Function(int value)? format;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final valueStyle = theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final format = this.format;
    final target = animateTo;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: 18, color: scheme.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (target != null && format != null)
            Semantics(
              label: value,
              child: ExcludeSemantics(
                child: AnimatedCount(
                  value: target,
                  format: format,
                  style: valueStyle,
                ),
              ),
            )
          else
            Text(value, style: valueStyle),
          if (caption != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              caption!,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ],
      ),
    );
  }
}