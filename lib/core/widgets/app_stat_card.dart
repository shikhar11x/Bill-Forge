import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/widgets/app_card.dart';

class AppStatCard extends StatelessWidget {
  const AppStatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.caption,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
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
              Icon(icon, size: 18, color: muted),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
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
