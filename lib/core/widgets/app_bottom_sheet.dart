import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_spacing.dart';

abstract final class AppBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              Flexible(child: SingleChildScrollView(child: builder(ctx))),
            ],
          ),
        ),
      ),
    );
  }
}
