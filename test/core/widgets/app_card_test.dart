import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/app/theme/app_theme.dart';
import 'package:billforge/core/widgets/app_card.dart';

Widget host(Widget child) => MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('a tappable card calls onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(AppCard(onTap: () => taps++, child: const Text('open'))),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('hovering a card does not get in the way of taps',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(AppCard(onTap: () => taps++, child: const Text('open'))),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(5, 5));
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('open')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a plain card just shows its content', (tester) async {
    await tester.pumpWidget(host(const AppCard(child: Text('info'))));
    expect(find.text('info'), findsOneWidget);
    expect(find.byType(InkWell), findsNothing);
  });
}