import 'package:flutter/material.dart';

import 'package:billforge/app/shell/notifications_button.dart';
import 'package:billforge/app/shell/profile_menu.dart';
import 'package:billforge/app/theme/app_spacing.dart';

/// Desktop/tablet header. Mobile uses a regular AppBar instead.
class AppTopBar extends StatelessWidget {
  const AppTopBar({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: Row(
        children: [
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.titleLarge),
          ),
          const Spacer(),
          const NotificationsButton(),
          const SizedBox(width: AppSpacing.sm),
          const ProfileMenu(),
        ],
      ),
    );
  }
}