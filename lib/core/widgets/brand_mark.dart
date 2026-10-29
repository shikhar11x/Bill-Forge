import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_spacing.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 32, this.label = 'B', this.color, super.key});

  final double size;
  final String label;

  /// Defaults to the theme's primary colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fill = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.sm + size / 16),
        boxShadow: [
          BoxShadow(
            color: fill.withValues(alpha: 0.35),
            blurRadius: size / 2.5,
            offset: Offset(0, size / 8),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.5,
        ),
      ),
    );
  }
}