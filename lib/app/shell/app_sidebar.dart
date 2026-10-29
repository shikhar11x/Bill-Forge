import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/app/shell/shell_destinations.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/constants/app_constants.dart';
import 'package:billforge/core/motion/app_motion.dart';
import 'package:billforge/features/shop/application/shop_providers.dart';
import 'package:billforge/features/shop/presentation/widgets/shop_logo.dart';

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

class _Brand extends ConsumerWidget {
  const _Brand({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = shopOrNull(ref.watch(shopProfileProvider));
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          mainAxisAlignment:
              collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            ShopLogo(shop: shop),
            if (!collapsed) ...[
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  shop?.name ?? AppConstants.appName,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
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
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = widget.selected;
    final collapsed = widget.collapsed;
    final destination = widget.destination;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    final background = selected
        ? scheme.primary.withValues(alpha: 0.14)
        : (_hover
            ? scheme.onSurface.withValues(alpha: 0.06)
            : Colors.transparent);
    final duration = AppMotion.of(context, AppMotion.fast);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Semantics(
        button: true,
        selected: selected,
        label: destination.label,
        child: Tooltip(
          message: collapsed ? destination.label : '',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              hoverColor: Colors.transparent,
              onTap: widget.onTap,
              onHover: (hovering) => setState(() => _hover = hovering),
              child: AnimatedContainer(
                duration: duration,
                curve: AppMotion.standard,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: collapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    // Accent bar that slides in beside the selected item.
                    AnimatedContainer(
                      duration: duration,
                      curve: AppMotion.standard,
                      width: selected && !collapsed ? 3 : 0,
                      height: 18,
                      margin: EdgeInsets.only(
                        right: selected && !collapsed ? AppSpacing.sm : 0,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    AnimatedScale(
                      scale: (_hover || selected) ? 1.1 : 1,
                      duration: duration,
                      curve: AppMotion.standard,
                      child: Icon(
                        selected ? destination.selectedIcon : destination.icon,
                        color: color,
                      ),
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