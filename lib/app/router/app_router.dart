import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/router/not_found_page.dart';
import 'package:billforge/app/shell/app_shell.dart';
import 'package:billforge/features/auth/application/auth_controller.dart';
import 'package:billforge/features/auth/domain/auth_state.dart';
import 'package:billforge/features/auth/presentation/login_page.dart';
import 'package:billforge/features/auth/presentation/register_page.dart';
import 'package:billforge/features/auth/presentation/splash_page.dart';
import 'package:billforge/features/dashboard/presentation/dashboard_page.dart';
import 'package:billforge/features/settings/presentation/settings_page.dart';
import 'package:billforge/features/shared/presentation/coming_soon_page.dart';

GoRoute _shellRoute(String path, Widget child) => GoRoute(
      path: path,
      pageBuilder: (context, state) =>
          NoTransitionPage<void>(key: state.pageKey, child: child),
    );

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    refresh.value++;
  });

  const publicPaths = {AppRoutes.login, AppRoutes.register};

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    debugLogDiagnostics: kDebugMode,
    errorBuilder: (context, state) =>
        NotFoundPage(location: state.uri.toString()),
    redirect: (context, state) {
      final status = ref.read(authControllerProvider).status;
      final location = state.matchedLocation;
      switch (status) {
        case AuthStatus.unknown:
          return location == AppRoutes.splash ? null : AppRoutes.splash;
        case AuthStatus.unauthenticated:
          return publicPaths.contains(location) ? null : AppRoutes.login;
        case AuthStatus.authenticated:
          final onAuthPage =
              location == AppRoutes.splash || publicPaths.contains(location);
          return onAuthPage ? AppRoutes.dashboard : null;
      }
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          _shellRoute(AppRoutes.dashboard, const DashboardPage()),
          _shellRoute(
            AppRoutes.billing,
            const ComingSoonPage(title: 'Billing', icon: Icons.receipt_long_rounded),
          ),
          _shellRoute(
            AppRoutes.products,
            const ComingSoonPage(title: 'Products', icon: Icons.category_rounded),
          ),
          _shellRoute(
            AppRoutes.customers,
            const ComingSoonPage(title: 'Customers', icon: Icons.people_rounded),
          ),
          _shellRoute(
            AppRoutes.inventory,
            const ComingSoonPage(title: 'Inventory', icon: Icons.inventory_2_rounded),
          ),
          _shellRoute(
            AppRoutes.reports,
            const ComingSoonPage(title: 'Reports', icon: Icons.insert_chart_rounded),
          ),
          _shellRoute(AppRoutes.settings, const SettingsPage()),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});