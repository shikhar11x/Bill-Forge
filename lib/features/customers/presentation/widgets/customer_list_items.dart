import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/widgets/app_card.dart';
import 'package:billforge/features/customers/domain/customer.dart';

class CustomerAvatar extends StatelessWidget {
  const CustomerAvatar({required this.name, this.radius = 18, super.key});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: radius,
        backgroundColor: primary.withValues(alpha: 0.16),
        child: Text(
          initialsOf(name),
          style: TextStyle(
            color: primary,
            fontSize: radius * 0.7,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

enum _MenuAction { edit, toggleArchive }

class CustomerMenu extends StatelessWidget {
  const CustomerMenu({
    required this.customer,
    required this.onEdit,
    required this.onToggleArchive,
    super.key,
  });

  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onToggleArchive;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MenuAction>(
      tooltip: 'Customer actions',
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (action) {
        switch (action) {
          case _MenuAction.edit:
            onEdit();
          case _MenuAction.toggleArchive:
            onToggleArchive();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _MenuAction.edit,
          child: _MenuRow(icon: Icons.edit_outlined, label: 'Edit'),
        ),
        PopupMenuItem(
          value: _MenuAction.toggleArchive,
          child: _MenuRow(
            icon: customer.isArchived
                ? Icons.unarchive_outlined
                : Icons.archive_outlined,
            label: customer.isArchived ? 'Restore' : 'Archive',
          ),
        ),
      ],
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

/// Mobile list item.
class CustomerCard extends StatelessWidget {
  const CustomerCard({
    required this.customer,
    required this.onTap,
    required this.onToggleArchive,
    super.key,
  });

  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onToggleArchive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final subtitle = [
      customer.phone,
      customer.locationLabel,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    final limit = customer.creditLimitPaise;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          CustomerAvatar(name: customer.name),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: theme.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (limit != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Credit limit ${formatPaise(limit, showDecimals: false)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ],
            ),
          ),
          CustomerMenu(
            customer: customer,
            onEdit: onTap,
            onToggleArchive: onToggleArchive,
          ),
        ],
      ),
    );
  }
}
