import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/core/motion/reveal.dart';

Widget host(Widget child, {bool reduced = false}) => MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    );

double opacityOf(WidgetTester tester, Finder reveal) => tester
    .widget<FadeTransition>(
      find.descendant(of: reveal, matching: find.byType(FadeTransition)),
    )
    .opacity
    .value;

void main() {
  testWidgets('starts hidden, then fades fully in', (tester) async {
    await tester.pumpWidget(host(const Reveal(child: Text('hello'))));
    final reveal = find.byType(Reveal);

    expect(opacityOf(tester, reveal), 0);
    await tester.pumpAndSettle();
    expect(opacityOf(tester, reveal), 1);
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('later items start later', (tester) async {
    await tester.pumpWidget(
      host(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Reveal(key: ValueKey('first'), child: Text('one')),
            Reveal(key: ValueKey('late'), index: 5, child: Text('two')),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(opacityOf(tester, find.byKey(const ValueKey('first'))), greaterThan(0));
    expect(opacityOf(tester, find.byKey(const ValueKey('late'))), 0);

    await tester.pumpAndSettle();
    expect(opacityOf(tester, find.byKey(const ValueKey('late'))), 1);
  });

  testWidgets('reduced motion shows the child at once', (tester) async {
    await tester.pumpWidget(
      host(const Reveal(child: Text('hello')), reduced: true),
    );
    expect(opacityOf(tester, find.byType(Reveal)), 1);
  });
}