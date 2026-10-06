import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_spacing.dart';

/// Places fields side by side when there is room, stacked otherwise.
class AppFieldRow extends StatelessWidget {
  const AppFieldRow({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth >= 480) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.lg),
                Expanded(child: children[i]),
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.lg,
          children: children,
        );
      },
    );
  }
}
