import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/motion/app_motion.dart';

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
    final VoidCallback? handler = isLoading ? () {} : onPressed;

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

    final enabled = handler != null;
    final glow = switch (variant) {
      AppButtonVariant.primary => scheme.primary,
      AppButtonVariant.danger => scheme.error,
      AppButtonVariant.secondary => null,
    };

    // A soft coloured glow makes primary actions look raised.
    Widget result = (enabled && glow != null)
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: button,
          )
        : button;

    if (expanded) result = SizedBox(width: double.infinity, child: result);
    return _PressScale(enabled: enabled, child: result);
  }
}

/// Shrinks its child slightly while a pointer is held down on it.
class _PressScale extends StatefulWidget {
  const _PressScale({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || AppMotion.reduced(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        child: widget.child,
      ),
    );
  }
}