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
import 'package:billforge/core/widgets/app_bottom_sheet.dart';

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

  /// Destinations that don't fit in the bottom bar live behind "More".
  void _showMore(BuildContext context, List<ShellDestination> more) {
    AppBottomSheet.show<void>(
      context,
      title: 'More',
      builder: (sheetContext) => Column(
        children: [
          for (final d in more)
            ListTile(
              leading: Icon(d.icon),
              title: Text(d.label),
              selected: d.matches(location),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.go(d.path);
              },
            ),
        ],
      ),
    );
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
          final more = [
            for (final d in shellDestinations)
              if (!d.showInBottomNav) d,
          ];
          final selectedBottom = bottom.indexWhere((d) => d.matches(location));
          final inMore = more.any((d) => d.matches(location));
          final selected = selectedBottom >= 0
              ? selectedBottom
              : (inMore ? bottom.length : 0);

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
              selectedIndex: selected,
              onDestinationSelected: (i) => i == bottom.length
                  ? _showMore(context, more)
                  : context.go(bottom[i].path),
              destinations: [
                for (final d in bottom)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                  ),
                const NavigationDestination(
                  icon: Icon(Icons.more_horiz_rounded),
                  label: 'More',
                ),
              ],
            ),
          );
        }

        final selectedIndex =
            shellDestinations.indexWhere((d) => d.matches(location));
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