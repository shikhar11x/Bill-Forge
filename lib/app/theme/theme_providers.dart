import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/app/theme/app_colors.dart';
import 'package:billforge/features/shop/application/shop_providers.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark; // dark-first

  void set(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Brand accent, driven by the shop's chosen colour.
final brandAccentProvider = Provider<Color>((ref) {
  final shop = shopOrNull(ref.watch(shopProfileProvider));
  return shop == null ? AppColors.defaultAccent : Color(shop.primaryColorValue);
});
