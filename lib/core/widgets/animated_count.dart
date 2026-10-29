import 'package:flutter/material.dart';

import 'package:billforge/core/motion/app_motion.dart';

/// A number that counts up from zero when it first appears, and glides to a
/// new value whenever it changes.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    required this.value,
    required this.format,
    this.style,
    this.duration = AppMotion.count,
    super.key,
  });

  final int value;

  /// Turns the in-between number into text, e.g. `formatPaise`.
  final String Function(int value) format;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: AppMotion.of(context, duration),
      curve: AppMotion.standard,
      builder: (context, current, _) => Text(
        format(current),
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}