import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/motion/app_motion.dart';

/// A bordered surface. When it has an [onTap] it also lifts on hover and
/// presses in while clicked.
class AppCard extends StatefulWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final body = Padding(padding: widget.padding, child: widget.child);
    final onTap = widget.onTap;

    if (onTap == null) {
      return Card(clipBehavior: Clip.antiAlias, child: body);
    }

    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: body),
    );
    if (AppMotion.reduced(context)) return card;

    final primary = Theme.of(context).colorScheme.primary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _down = true),
        onPointerUp: (_) => setState(() => _down = false),
        onPointerCancel: (_) => setState(() => _down = false),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          transform: Matrix4.translationValues(0, _hover && !_down ? -2 : 0, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: AnimatedScale(
            scale: _down ? 0.985 : 1,
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            child: card,
          ),
        ),
      ),
    );
  }
}