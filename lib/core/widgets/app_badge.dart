import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_colors.dart';
import 'package:billforge/app/theme/app_spacing.dart';

enum BadgeTone { neutral, accent, success, warning, danger }

class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    this.tone = BadgeTone.neutral,
    super.key,
  });

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (tone) {
      BadgeTone.neutral => scheme.onSurfaceVariant,
      BadgeTone.accent => scheme.primary,
      BadgeTone.success => AppColors.success,
      BadgeTone.warning => AppColors.warning,
      BadgeTone.danger => AppColors.danger,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
