import 'package:flutter/material.dart';

import 'package:billforge/core/motion/app_motion.dart';

/// Fades and lifts its child into place once, after a short delay of
/// `index * step`. Use it for cards and sections that appear together so they
/// arrive one after another. At most 10 steps of delay are used.
class Reveal extends StatefulWidget {
  const Reveal({
    required this.child,
    this.index = 0,
    this.step = const Duration(milliseconds: 60),
    this.rise = 14,
    super.key,
  });

  final Widget child;
  final int index;
  final Duration step;

  /// How far (in logical pixels) the child travels upwards while appearing.
  final double rise;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _progress;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final steps = widget.index < 0 ? 0 : (widget.index > 10 ? 10 : widget.index);
    final delayMs = widget.step.inMilliseconds * steps;
    final totalMs = delayMs + AppMotion.slow.inMilliseconds;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );
    // The delay is part of the curve, so no Timer is needed.
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(delayMs / totalMs, 1, curve: AppMotion.standard),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _progress,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, (1 - _progress.value) * widget.rise),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}