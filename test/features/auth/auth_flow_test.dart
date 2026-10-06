import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/app/app.dart';
import 'package:billforge/app/config/env.dart';
import 'package:billforge/core/widgets/app_button.dart';

void main() {
  testWidgets('splash -> login -> validation -> shop onboarding', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
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
        ],
        child: const BillForgeApp(),
      ),
    );

    // Splash resolves to the login page.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(AppButton), findsOneWidget);

    // Empty submit shows validation errors.
    await tester.tap(find.byType(AppButton));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);

    // Valid submit reaches shop onboarding for a new account.
    await tester.enterText(find.byType(TextFormField).at(0), 'owner@shop.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');

    await tester.tap(find.byType(AppButton));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Set up your shop'), findsOneWidget);
  });
}
