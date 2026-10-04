import 'package:flutter/material.dart';

import 'package:billforge/app/shell/shell_destinations.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/constants/app_constants.dart';
import 'package:billforge/core/widgets/brand_mark.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    required this.collapsed,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final bool collapsed;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  Widget _item(int i) => _SidebarItem(
        destination: shellDestinations[i],
        selected: i == selectedIndex,
        collapsed: collapsed,
        onTap: () => onSelected(i),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final main = [
      for (var i = 0; i < shellDestinations.length; i++)
        if (!shellDestinations[i].pinnedToBottom) i,
    ];
    final pinned = [
      for (var i = 0; i < shellDestinations.length; i++)
        if (shellDestinations[i].pinnedToBottom) i,
    ];

    return Container(
      width: collapsed ? AppLayout.sidebarCollapsedWidth : AppLayout.sidebarWidth,
      color: scheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Brand(collapsed: collapsed),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.sm),
                children: [for (final i in main) _item(i)],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(children: [for (final i in pinned) _item(i)]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          mainAxisAlignment:
              collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            const BrandMark(),
            if (!collapsed) ...[
              const SizedBox(width: AppSpacing.md),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Semantics(
        button: true,
        selected: selected,
        label: destination.label,
        child: Tooltip(
          message: collapsed ? destination.label : '',
          child: Material(
            color: selected
                ? scheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: collapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      color: color,
                    ),
                    if (!collapsed) ...[
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        destination.label,
                        style: TextStyle(
                          color: selected ? scheme.onSurface : color,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
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