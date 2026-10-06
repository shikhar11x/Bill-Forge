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
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.sm + size / 16),
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
