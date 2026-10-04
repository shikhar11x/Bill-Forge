import 'package:flutter/material.dart';

import 'package:billforge/app/router/app_routes.dart';

class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
}

/// Single placeholder for now. Phase 1 adds the real destinations.
const shellDestinations = <ShellDestination>[
  ShellDestination(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    path: AppRoutes.home,
  ),
];