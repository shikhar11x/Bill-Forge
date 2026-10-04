import 'package:flutter/material.dart';

import 'package:billforge/app/router/app_routes.dart';

class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
    this.showInBottomNav = false,
    this.pinnedToBottom = false,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;

  /// Mobile bottom navigation fits 5 items.
  final bool showInBottomNav;

  /// Rendered at the bottom of the desktop/tablet sidebar.
  final bool pinnedToBottom;

  bool matches(String location) =>
      location == path || location.startsWith('$path/');
}

const shellDestinations = <ShellDestination>[
  ShellDestination(
    label: 'Dashboard',
    icon: Icons.space_dashboard_outlined,
    selectedIcon: Icons.space_dashboard_rounded,
    path: AppRoutes.dashboard,
    showInBottomNav: true,
  ),
  ShellDestination(
    label: 'Billing',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long_rounded,
    path: AppRoutes.billing,
    showInBottomNav: true,
  ),
  ShellDestination(
    label: 'Products',
    icon: Icons.category_outlined,
    selectedIcon: Icons.category_rounded,
    path: AppRoutes.products,
    showInBottomNav: true,
  ),
  ShellDestination(
    label: 'Customers',
    icon: Icons.people_outline_rounded,
    selectedIcon: Icons.people_rounded,
    path: AppRoutes.customers,
    showInBottomNav: true,
  ),
  ShellDestination(
    label: 'Inventory',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2_rounded,
    path: AppRoutes.inventory,
  ),
  ShellDestination(
    label: 'Reports',
    icon: Icons.insert_chart_outlined_rounded,
    selectedIcon: Icons.insert_chart_rounded,
    path: AppRoutes.reports,
  ),
  ShellDestination(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
    path: AppRoutes.settings,
    showInBottomNav: true,
    pinnedToBottom: true,
  ),
];