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
import 'package:billforge/features/billing/presentation/billing_page.dart';
import 'package:billforge/features/billing/presentation/invoice_detail_page.dart';
import 'package:billforge/features/billing/presentation/invoice_preview_page.dart';
import 'package:billforge/features/billing/presentation/pos_page.dart';
import 'package:billforge/features/customers/presentation/customer_form_page.dart';
import 'package:billforge/features/customers/presentation/customers_page.dart';
import 'package:billforge/features/dashboard/presentation/dashboard_page.dart';
import 'package:billforge/features/inventory/presentation/inventory_page.dart';
import 'package:billforge/features/inventory/presentation/purchase_detail_page.dart';
import 'package:billforge/features/inventory/presentation/purchase_form_page.dart';
import 'package:billforge/features/inventory/presentation/stock_history_page.dart';
import 'package:billforge/features/payments/presentation/customer_account_page.dart';
import 'package:billforge/features/payments/presentation/customer_statement_page.dart';
import 'package:billforge/features/payments/presentation/outstanding_page.dart';
import 'package:billforge/features/products/presentation/product_form_page.dart';
import 'package:billforge/features/products/presentation/products_page.dart';
import 'package:billforge/features/settings/presentation/settings_page.dart';
import 'package:billforge/features/shared/presentation/coming_soon_page.dart';
import 'package:billforge/features/shop/application/shop_providers.dart';
import 'package:billforge/features/shop/domain/shop_profile.dart';
import 'package:billforge/features/shop/presentation/shop_setup_page.dart';

Page<void> _noTransition(GoRouterState state, Widget child) =>
    NoTransitionPage<void>(key: state.pageKey, child: child);

GoRoute _shellRoute(String path, Widget child) => GoRoute(
  path: path,
  pageBuilder: (context, state) => _noTransition(state, child),
);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    refresh.value++;
  });
  ref.listen<AsyncValue<ShopProfile?>>(shopProfileProvider, (previous, next) {
    refresh.value++;
  });

  const authPaths = {
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.onboarding,
  };
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
          final shopAsync = ref.read(shopProfileProvider);
          if (shopAsync is! AsyncData<ShopProfile?>) {
            return location == AppRoutes.splash ? null : AppRoutes.splash;
          }
          if (shopAsync.value == null) {
            return location == AppRoutes.onboarding
                ? null
                : AppRoutes.onboarding;
          }
          return authPaths.contains(location) ? AppRoutes.dashboard : null;
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
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) =>
            const ShopSetupPage(mode: SetupMode.create),
      ),
      GoRoute(
        path: AppRoutes.shopEdit,
        builder: (context, state) => const ShopSetupPage(mode: SetupMode.edit),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          _shellRoute(AppRoutes.dashboard, const DashboardPage()),
          GoRoute(
            path: AppRoutes.billing,
            pageBuilder: (context, state) =>
                _noTransition(state, const BillingPage()),
            routes: [
              // 'new' must stay above ':id' so it isn't read as an invoice id.
              GoRoute(
                path: 'new',
                pageBuilder: (context, state) =>
                    _noTransition(state, const PosPage()),
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _noTransition(
                    state,
                    InvoiceDetailPage(key: ValueKey(id), invoiceId: id),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'preview',
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return _noTransition(
                        state,
                        InvoicePreviewPage(key: ValueKey(id), invoiceId: id),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.products,
            pageBuilder: (context, state) =>
                _noTransition(state, const ProductsPage()),
            routes: [
              GoRoute(
                path: 'new',
                pageBuilder: (context, state) =>
                    _noTransition(state, const ProductFormPage()),
              ),
              GoRoute(
                path: ':id/edit',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _noTransition(
                    state,
                    ProductFormPage(key: ValueKey(id), productId: id),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.customers,
            pageBuilder: (context, state) =>
                _noTransition(state, const CustomersPage()),
            routes: [
              // Static paths ('new', 'outstanding') must stay above ':id'.
              GoRoute(
                path: 'new',
                pageBuilder: (context, state) =>
                    _noTransition(state, const CustomerFormPage()),
              ),
              GoRoute(
                path: 'outstanding',
                pageBuilder: (context, state) =>
                    _noTransition(state, const OutstandingPage()),
              ),
              GoRoute(
                path: ':id/edit',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _noTransition(
                    state,
                    CustomerFormPage(key: ValueKey(id), customerId: id),
                  );
                },
              ),
              GoRoute(
                path: ':id/statement',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _noTransition(
                    state,
                    CustomerStatementPage(key: ValueKey(id), customerId: id),
                  );
                },
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _noTransition(
                    state,
                    CustomerAccountPage(key: ValueKey(id), customerId: id),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.inventory,
            pageBuilder: (context, state) =>
                _noTransition(state, const InventoryPage()),
            routes: [
              // 'purchases/new' must stay above 'purchases/:id'.
              GoRoute(
                path: 'purchases/new',
                pageBuilder: (context, state) =>
                    _noTransition(state, const PurchaseFormPage()),
              ),
              GoRoute(
                path: 'purchases/:id',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _noTransition(
                    state,
                    PurchaseDetailPage(key: ValueKey(id), purchaseId: id),
                  );
                },
              ),
              GoRoute(
                path: 'stock/:productId',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['productId']!;
                  return _noTransition(
                    state,
                    StockHistoryPage(key: ValueKey(id), productId: id),
                  );
                },
              ),
            ],
          ),
          _shellRoute(
            AppRoutes.reports,
            const ComingSoonPage(
              title: 'Reports',
              icon: Icons.insert_chart_rounded,
            ),
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
