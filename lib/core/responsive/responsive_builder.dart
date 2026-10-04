import 'package:flutter/widgets.dart';

import 'package:billforge/core/responsive/breakpoints.dart';

/// Rebuilds when the available width crosses a breakpoint.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({required this.builder, super.key});

  final Widget Function(BuildContext context, ScreenSize size) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          builder(context, Breakpoints.fromWidth(constraints.maxWidth)),
    );
  }
}