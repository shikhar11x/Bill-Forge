import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/features/auth/application/auth_controller.dart';
import 'package:billforge/features/auth/presentation/confirm_sign_out.dart';

enum _ProfileAction { settings, signOut }

class ProfileMenu extends ConsumerWidget {
  const ProfileMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).user;
    final name = user?.name ?? 'Account';

    return PopupMenuButton<_ProfileAction>(
      tooltip: 'Account menu',
      position: PopupMenuPosition.under,
      offset: const Offset(0, AppSpacing.sm),
      onSelected: (action) {
        switch (action) {
          case _ProfileAction.settings:
            context.go(AppRoutes.settings);
          case _ProfileAction.signOut:
            confirmAndSignOut(context, ref);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<_ProfileAction>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: theme.textTheme.titleSmall),
              if (user != null)
                Text(
                  user.email,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _ProfileAction.settings,
          child: _MenuRow(icon: Icons.settings_outlined, label: 'Settings'),
        ),
        const PopupMenuItem(
          value: _ProfileAction.signOut,
          child: _MenuRow(icon: Icons.logout_rounded, label: 'Sign out'),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.16),
          child: Text(
            initialsOf(name),
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: AppSpacing.md),
        Text(label),
      ],
    );
  }
}
