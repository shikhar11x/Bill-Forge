import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/motion/app_motion.dart';

/// Tilts its child in perspective towards the mouse, with a soft highlight
/// and a glow underneath. Does nothing on touch screens or when motion is
/// reduced. Taps and scrolling pass straight through.
class TiltCard extends StatefulWidget {
  const TiltCard({
    required this.child,
    this.maxTilt = 0.06,
    this.radius = AppRadius.lg,
    super.key,
  });

  final Widget child;

  /// Largest rotation in radians (about 3.4 degrees at the default).
  final double maxTilt;

  /// Matches the child's corner radius so the glow and highlight fit.
  final double radius;

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> {
  Offset _pos = Offset.zero;
  bool _hover = false;

  void _onHover(PointerHoverEvent event) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.isEmpty) return;
    final size = box.size;
    final dx = ((event.localPosition.dx / size.width) * 2 - 1)
        .clamp(-1.0, 1.0)
        .toDouble();
    final dy = ((event.localPosition.dy / size.height) * 2 - 1)
        .clamp(-1.0, 1.0)
        .toDouble();
    setState(() {
      _hover = true;
      _pos = Offset(dx, dy);
    });
  }

  void _onExit(PointerExitEvent event) => setState(() {
        _hover = false;
        _pos = Offset.zero;
      });

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return widget.child;

    final primary = Theme.of(context).colorScheme.primary;
    final radius = BorderRadius.circular(widget.radius);

    return MouseRegion(
      onHover: _onHover,
      onExit: _onExit,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: _hover ? 1 : 0),
        duration: AppMotion.medium,
        curve: AppMotion.standard,
        builder: (context, depth, child) => TweenAnimationBuilder<Offset>(
          tween: Tween<Offset>(begin: Offset.zero, end: _pos),
          duration: AppMotion.fast,
          curve: Curves.easeOut,
          builder: (context, p, _) {
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.0014)
              ..rotateX(-p.dy * widget.maxTilt)
              ..rotateY(p.dx * widget.maxTilt);
            return Transform(
              alignment: Alignment.center,
              transform: transform,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.22 * depth),
                      blurRadius: 26 * depth,
                      offset: Offset(-p.dx * 8, 10 - p.dy * 6),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.passthrough,
                  children: [
                    child!,
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: radius,
                            gradient: RadialGradient(
                              center: Alignment(p.dx, p.dy),
                              radius: 0.9,
                              colors: [
                                Colors.white.withValues(alpha: 0.07 * depth),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        child: widget.child,
      ),
    );
  }
}