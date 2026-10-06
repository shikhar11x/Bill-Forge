import 'package:flutter/material.dart';

import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_empty_state.dart';

class AppErrorState extends StatelessWidget {
  const AppErrorState({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.error_outline_rounded,
      title: 'Something went wrong',
      message: message,
      action: onRetry == null
          ? null
          : AppButton(
              label: 'Try again',
              variant: AppButtonVariant.secondary,
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
    );
  }
}
