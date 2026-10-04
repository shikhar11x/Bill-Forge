import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/app/router/app_router.dart';
import 'package:billforge/app/theme/app_theme.dart';
import 'package:billforge/app/theme/theme_providers.dart';
import 'package:billforge/core/constants/app_constants.dart';

class BillForgeApp extends ConsumerWidget {
  const BillForgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final accent = ref.watch(brandAccentProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accent: accent),
      darkTheme: AppTheme.dark(accent: accent),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}