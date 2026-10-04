import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_spacing.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 32, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.sm + size / 16),
      ),
      child: Text(
        'B',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.5,
        ),
      ),
    );
  }
}