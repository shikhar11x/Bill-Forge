import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/shell/app_sidebar.dart';
import 'package:billforge/app/shell/shell_destinations.dart';
import 'package:billforge/core/constants/app_constants.dart';
import 'package:billforge/core/responsive/breakpoints.dart';
import 'package:billforge/core/responsive/responsive_builder.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  int get _selectedIndex {
    final index = shellDestinations.indexWhere(
      (d) => d.path == '/' ? location == '/' : location.startsWith(d.path),
    );
    return index < 0 ? 0 : index;
  }

  void _onSelected(BuildContext context, int index) =>
      context.go(shellDestinations[index].path);

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, size) {
        if (size.isMobile) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppConstants.appName)),
            body: child,
            // NavigationBar requires at least two destinations.
            bottomNavigationBar: shellDestinations.length >= 2
                ? NavigationBar(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (i) => _onSelected(context, i),
                    destinations: [
                      for (final d in shellDestinations)
                        NavigationDestination(
                          icon: Icon(d.icon),
                          selectedIcon: Icon(d.selectedIcon),
                          label: d.label,
                        ),
                    ],
                  )
                : null,
          );
        }

        return Scaffold(
          body: Row(
            children: [
              AppSidebar(
                collapsed: size.isTablet,
                selectedIndex: _selectedIndex,
                onSelected: (i) => _onSelected(context, i),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}