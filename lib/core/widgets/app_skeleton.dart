import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_spacing.dart';

/// Pulsing placeholder block. Holds still when the OS asks to reduce motion.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({this.width, this.height = 14, super.key});

  final double? width;
  final double height;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final Animation<double> _opacity = Tween<double>(
    begin: 0.35,
    end: 0.8,
  ).animate(_controller);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
    );
  }
}

/// A list of skeleton rows used while a list loads for the first time.
class AppListSkeleton extends StatelessWidget {
  const AppListSkeleton({this.itemCount = 8, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, _) => const Row(
          children: [
            Expanded(flex: 4, child: AppSkeleton(height: 18)),
            SizedBox(width: AppSpacing.xl),
            Expanded(flex: 2, child: AppSkeleton(height: 18)),
            SizedBox(width: AppSpacing.xl),
            Expanded(flex: 2, child: AppSkeleton(height: 18)),
          ],
        ),
      ),
    );
  }
}
