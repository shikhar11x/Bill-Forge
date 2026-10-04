import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = variant == AppButtonVariant.secondary
        ? scheme.onSurface
        : scheme.onPrimary;

    // While loading we keep the normal look but ignore taps.
    final VoidCallback? handler =
        isLoading ? () {} : onPressed;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        else if (icon != null)
          Icon(icon, size: 18),
        if (isLoading || icon != null) const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

    final button = switch (variant) {
      AppButtonVariant.primary =>
        FilledButton(onPressed: handler, child: content),
      AppButtonVariant.secondary =>
        OutlinedButton(onPressed: handler, child: content),
      AppButtonVariant.danger => FilledButton(
          onPressed: handler,
          style: FilledButton.styleFrom(backgroundColor: scheme.error),
          child: content,
        ),
    };

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}