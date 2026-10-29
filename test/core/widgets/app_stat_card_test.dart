import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/app/theme/app_theme.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/widgets/app_stat_card.dart';

Widget host(Widget child) => MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(body: Center(child: SizedBox(width: 280, child: child))),
    );

void main() {
  testWidgets('shows the label, value and caption', (tester) async {
    await tester.pumpWidget(
      host(
        const AppStatCard(
          label: 'Orders',
          value: '12',
          icon: Icons.receipt_long_outlined,
          caption: 'Today',
        ),
      ),
    );
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('counts up to animateTo and then shows the formatted value',
      (tester) async {
    await tester.pumpWidget(
      host(
        AppStatCard(
          label: 'Sales',
          value: formatPaise(250000),
          icon: Icons.trending_up_rounded,
          animateTo: 250000,
          format: formatPaise,
        ),
      ),
    );
    expect(find.text('₹0.00'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('₹2,500.00'), findsOneWidget);
  });

  testWidgets('the plain value is announced to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        AppStatCard(
          label: 'Sales',
          value: formatPaise(250000),
          icon: Icons.trending_up_rounded,
          animateTo: 250000,
          format: formatPaise,
        ),
      ),
    );
    expect(find.bySemanticsLabel('₹2,500.00'), findsOneWidget);
    handle.dispose();
  });
}