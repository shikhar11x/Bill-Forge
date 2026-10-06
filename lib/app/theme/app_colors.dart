import 'package:flutter/material.dart';

abstract final class AppColors {
  /// Default brand accent. Shops will override this later.
  static const defaultAccent = Color(0xFF3F6FF0);

  static const success = Color(0xFF3FB68B);
  static const warning = Color(0xFFE5A83B);
  static const danger = Color(0xFFEF5B5B);
}

@immutable
class AppPalette {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  static const dark = AppPalette(
    background: Color(0xFF0B0D12),
    surface: Color(0xFF12151C),
    surfaceRaised: Color(0xFF181C25),
    border: Color(0xFF252A36),
    textPrimary: Color(0xFFE8EAF0),
    textSecondary: Color(0xFF9AA1B2),
  );

  static const light = AppPalette(
    background: Color(0xFFF6F7F9),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF0F2F5),
    border: Color(0xFFE1E4EA),
    textPrimary: Color(0xFF14171F),
    textSecondary: Color(0xFF5C6475),
  );
}
