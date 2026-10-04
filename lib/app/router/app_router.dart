import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/router/not_found_page.dart';
import 'package:billforge/app/shell/app_shell.dart';
import 'package:billforge/features/home/presentation/home_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: kDebugMode,
    errorBuilder: (context, state) => NotFoundPage(location: state.uri.toString()),
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
        ],
      ),
    ],
  );
});