import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:billforge/features/shop/application/shop_providers.dart';

import '../support/fakes.dart';

import 'package:billforge/app/app.dart';
import 'package:billforge/app/config/env.dart';
import 'package:billforge/app/shell/app_sidebar.dart';
import 'package:billforge/features/auth/application/auth_controller.dart';
import 'package:billforge/features/auth/domain/auth_state.dart';

class _SignedInController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(
    AuthUser(name: 'Test Owner', email: 'owner@example.com'),
  );
}

void main() {
  Future<void> pumpApp(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          envProvider.overrideWithValue(
            const Env(
              environment: AppEnvironment.development,
              apiBaseUrl: 'http://localhost:3000',
            ),
          ),
          authControllerProvider.overrideWith(_SignedInController.new),
          shopProfileProvider.overrideWith((ref) => Stream.value(sampleShop())),
        ],
        child: const BillForgeApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('desktop: full sidebar and dashboard', (tester) async {
    await pumpApp(tester, const Size(1400, 900));
    expect(find.byType(AppSidebar), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.textContaining('Welcome back'), findsOneWidget);
  });

  testWidgets('tablet: sidebar present', (tester) async {
    await pumpApp(tester, const Size(800, 900));
    expect(find.byType(AppSidebar), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('mobile: bottom navigation, no sidebar', (tester) async {
    await pumpApp(tester, const Size(400, 800));
    expect(find.byType(AppSidebar), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('notifications panel opens with empty state', (tester) async {
    await pumpApp(tester, const Size(1400, 900));
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text("You're all caught up"), findsOneWidget);
  });
}
