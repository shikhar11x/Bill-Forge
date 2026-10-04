import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/app/config/env.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/app/theme/theme_providers.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/widgets/app_badge.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_card.dart';
import 'package:billforge/core/widgets/page_container.dart';
import 'package:billforge/features/auth/application/auth_controller.dart';
import 'package:billforge/features/auth/presentation/confirm_sign_out.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const _upcoming = <(IconData, String)>[
    (Icons.storefront_outlined, 'Shop profile'),
    (Icons.receipt_long_outlined, 'Invoice & tax'),
    (Icons.payments_outlined, 'Payments'),
    (Icons.print_outlined, 'Printer'),
    (Icons.chat_outlined, 'WhatsApp'),
    (Icons.group_outlined, 'Team & roles'),
    (Icons.lock_outline_rounded, 'Security'),
    (Icons.cloud_upload_outlined, 'Backup'),
    (Icons.workspace_premium_outlined, 'Subscription'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).user;
    final themeMode = ref.watch(themeModeProvider);
    final env = ref.watch(envProvider);

    return PageContainer(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(
              title: 'Account',
              child: AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.16),
                      child: Text(
                        initialsOf(user?.name ?? ''),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name ?? '', style: theme.textTheme.titleSmall),
                          Text(
                            user?.email ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    AppButton(
                      label: 'Sign out',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => confirmAndSignOut(context, ref),
                    ),
                  ],
                ),
              ),
            ),
            _Section(
              title: 'Appearance',
              child: AppCard(
                child: Row(
                  children: [
                    Expanded(child: Text('Theme', style: theme.textTheme.bodyLarge)),
                    SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                        ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                        ButtonSegment(value: ThemeMode.system, label: Text('System')),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (s) =>
                          ref.read(themeModeProvider.notifier).set(s.first),
                    ),
                  ],
                ),
              ),
            ),
            _Section(
              title: 'Shop configuration',
              child: AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < _upcoming.length; i++) ...[
                      if (i > 0) const Divider(),
                      ListTile(
                        enabled: false,
                        leading: Icon(_upcoming[i].$1),
                        title: Text(_upcoming[i].$2),
                        trailing: const AppBadge(label: 'Soon'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (!env.isProduction)
              _Section(
                title: 'About',
                child: AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Environment', style: theme.textTheme.bodyLarge),
                      ),
                      AppBadge(label: env.environment.name, tone: BadgeTone.warning),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}