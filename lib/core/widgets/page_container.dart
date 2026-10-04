import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/responsive/responsive_builder.dart';

/// Scrollable page body with responsive padding and a max content width.
class PageContainer extends StatelessWidget {
  const PageContainer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, size) {
        final padding = size.isMobile ? AppSpacing.lg : AppSpacing.xxl;
        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppLayout.contentMaxWidth),
              child: child,
            ),
          ),
        );
      },
    );
  }
}