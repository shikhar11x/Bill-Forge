import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/widgets/brand_mark.dart';
import 'package:billforge/features/shop/domain/shop_profile.dart';

/// Shop logo, falling back to a coloured initial, then the BillForge mark.
class ShopLogo extends StatelessWidget {
  const ShopLogo({required this.shop, this.size = 32, super.key});

  final ShopProfile? shop;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = shop;
    if (s == null) return BrandMark(size: size);

    final logo = s.logo;
    final fallback = BrandMark(
      size: size,
      label: initialsOf(s.name).substring(0, 1),
      color: Color(s.primaryColorValue),
    );
    if (logo == null) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm + size / 16),
      child: Image.memory(
        logo,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        semanticLabel: 'Shop logo',
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
