import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/app/app.dart';
import 'package:billforge/app/config/env.dart';
import 'package:billforge/app/shell/app_sidebar.dart';

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
        ],
        child: const BillForgeApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('desktop width shows the full sidebar', (tester) async {
    await pumpApp(tester, const Size(1400, 900));
    expect(find.byType(AppSidebar), findsOneWidget);
    expect(find.text('desktop'), findsOneWidget);
  });

  testWidgets('tablet width shows the collapsed sidebar', (tester) async {
    await pumpApp(tester, const Size(800, 900));
    expect(find.byType(AppSidebar), findsOneWidget);
    expect(find.text('tablet'), findsOneWidget);
  });

  testWidgets('mobile width shows app bar and no sidebar', (tester) async {
    await pumpApp(tester, const Size(400, 800));
    expect(find.byType(AppSidebar), findsNothing);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('mobile'), findsOneWidget);
  });
}