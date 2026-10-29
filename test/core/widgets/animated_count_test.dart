import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/widgets/animated_count.dart';

Widget host(int value, {bool reduced = false}) => MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: Scaffold(
            body: AnimatedCount(value: value, format: formatPaise),
          ),
        ),
      ),
    );

void main() {
  testWidgets('counts up from zero to the value', (tester) async {
    await tester.pumpWidget(host(100000));
    expect(find.text('₹0.00'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('₹1,000.00'), findsOneWidget);
  });

  testWidgets('glides to a new value when it changes', (tester) async {
    await tester.pumpWidget(host(100000));
    await tester.pumpAndSettle();

    await tester.pumpWidget(host(50000));
    await tester.pumpAndSettle();
    expect(find.text('₹500.00'), findsOneWidget);
  });

  testWidgets('reduced motion shows the value without counting',
      (tester) async {
    await tester.pumpWidget(host(100000, reduced: true));
    await tester.pump();
    expect(find.text('₹1,000.00'), findsOneWidget);
  });
}