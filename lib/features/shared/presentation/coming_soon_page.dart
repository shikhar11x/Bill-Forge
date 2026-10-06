import 'package:flutter/material.dart';

import 'package:billforge/core/widgets/app_empty_state.dart';

class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({required this.title, required this.icon, super.key});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: icon,
      title: '$title is coming soon',
      message: 'This module is built in a later phase.',
    );
  }
}
