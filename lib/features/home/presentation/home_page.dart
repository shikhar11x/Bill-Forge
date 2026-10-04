import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/app/config/env.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/constants/app_constants.dart';
import 'package:billforge/core/responsive/responsive_builder.dart';

/// Temporary landing page that proves the foundation works.
/// Replaced by the real dashboard shell in Phase 1.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = ref.watch(envProvider);
    final theme = Theme.of(context);

    return ResponsiveBuilder(
      builder: (context, size) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AppConstants.appName,
                        style: theme.textTheme.headlineMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AppConstants.tagline,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const Divider(),
                    const SizedBox(height: AppSpacing.lg),
                    _InfoRow(label: 'Environment', value: env.environment.name),
                    _InfoRow(label: 'API base URL', value: env.apiBaseUrl),
                    _InfoRow(label: 'Layout', value: size.name),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Foundation ready. Resize the window to see the layout adapt.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}