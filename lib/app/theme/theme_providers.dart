import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/app/theme/app_colors.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark; // dark-first

  void set(ThemeMode mode) => state = mode;
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// Brand accent. Will be driven by shop branding settings in Phase 2.
class BrandAccentNotifier extends Notifier<Color> {
  @override
  Color build() => AppColors.defaultAccent;

  void set(Color color) => state = color;
}

final brandAccentProvider =
    NotifierProvider<BrandAccentNotifier, Color>(BrandAccentNotifier.new);