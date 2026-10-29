import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/core/widgets/tilt_card.dart';

Widget host({bool reduced = false}) => MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 100,
                child: TiltCard(
                  child: ColoredBox(color: Colors.blue, child: Text('tilt me')),
                ),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('follows the mouse and settles back when it leaves',
      (tester) async {
    await tester.pumpWidget(host());
    expect(
      find.descendant(
        of: find.byType(TiltCard),
        matching: find.byType(Transform),
      ),
      findsWidgets,
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(5, 5));
    addTearDown(gesture.removePointer);

    await gesture.moveTo(tester.getCenter(find.text('tilt me')) + const Offset(40, -20));
    await tester.pumpAndSettle();
    expect(find.text('tilt me'), findsOneWidget);

    await gesture.moveTo(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('tilt me'), findsOneWidget);
  });

  testWidgets('reduced motion leaves the child untouched', (tester) async {
    await tester.pumpWidget(host(reduced: true));
    expect(
      find.descendant(
        of: find.byType(TiltCard),
        matching: find.byType(Transform),
      ),
      findsNothing,
    );
    expect(find.text('tilt me'), findsOneWidget);
  });
}