import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_colors.dart';
import 'package:billforge/app/theme/app_spacing.dart';

enum ToastType { info, success, error }

abstract final class AppToast {
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
  }) {
    final (icon, color) = switch (type) {
      ToastType.info => (
        Icons.info_outline_rounded,
        Theme.of(context).colorScheme.primary,
      ),
      ToastType.success => (
        Icons.check_circle_outline_rounded,
        AppColors.success,
      ),
      ToastType.error => (Icons.error_outline_rounded, AppColors.danger),
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}
