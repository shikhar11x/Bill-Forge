import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/theme/app_spacing.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({required this.location, super.key});

  final String location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Page not found', style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                location,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: () => context.go(AppRoutes.dashboard),
                child: const Text('Back to dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
