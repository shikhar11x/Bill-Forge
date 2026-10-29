import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/app/theme/app_theme.dart';
import 'package:billforge/core/widgets/app_empty_state.dart';

void main() {
  testWidgets('shows its title, message and action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: AppEmptyState(
            icon: Icons.inbox_outlined,
            title: 'Nothing here',
            message: 'Add something to get started.',
            action: TextButton(onPressed: () {}, child: const Text('Add')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Add something to get started.'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
  });

  testWidgets('a short parent scrolls instead of overflowing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: SizedBox(
            height: 60,
            child: AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'Nothing here',
              message: 'Add something to get started.',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}