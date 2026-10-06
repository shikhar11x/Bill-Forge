import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/shell/app_sidebar.dart';
import 'package:billforge/app/shell/app_top_bar.dart';
import 'package:billforge/app/shell/notifications_button.dart';
import 'package:billforge/app/shell/profile_menu.dart';
import 'package:billforge/app/shell/shell_destinations.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/constants/app_constants.dart';
import 'package:billforge/core/responsive/responsive_builder.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  String get _title {
    for (final d in shellDestinations) {
      if (d.matches(location)) return d.label;
    }
    return AppConstants.appName;
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, size) {
        if (size.isMobile) {
          final bottom = [
            for (final d in shellDestinations)
              if (d.showInBottomNav) d,
          ];
          final selected = bottom.indexWhere((d) => d.matches(location));
          return Scaffold(
            appBar: AppBar(
              title: Text(_title),
              actions: const [
                NotificationsButton(),
                ProfileMenu(),
                SizedBox(width: AppSpacing.sm),
              ],
            ),
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selected < 0 ? 0 : selected,
              onDestinationSelected: (i) => context.go(bottom[i].path),
              destinations: [
                for (final d in bottom)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                  ),
              ],
            ),
          );
        }

        final selectedIndex = shellDestinations.indexWhere(
          (d) => d.matches(location),
        );
        return Scaffold(
          body: Row(
            children: [
              AppSidebar(
                collapsed: size.isTablet,
                selectedIndex: selectedIndex,
                onSelected: (i) => context.go(shellDestinations[i].path),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  children: [
                    AppTopBar(title: _title),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
