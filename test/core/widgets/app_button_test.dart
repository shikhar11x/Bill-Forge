import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/app/theme/app_theme.dart';
import 'package:billforge/core/widgets/app_button.dart';

Widget host(Widget child) => MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('pressing a button calls onPressed once', (tester) async {
    var presses = 0;
    await tester.pumpWidget(
      host(AppButton(label: 'Save', onPressed: () => presses++)),
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(presses, 1);
  });

  testWidgets('a button without a handler is disabled', (tester) async {
    await tester.pumpWidget(
      host(const AppButton(label: 'Save', onPressed: null)),
    );
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('a loading button shows a spinner and ignores taps',
      (tester) async {
    var presses = 0;
    await tester.pumpWidget(
      host(AppButton(label: 'Save', isLoading: true, onPressed: () => presses++)),
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(presses, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('the secondary variant is an outlined button', (tester) async {
    await tester.pumpWidget(
      host(
        AppButton(
          label: 'Cancel',
          variant: AppButtonVariant.secondary,
          onPressed: () {},
        ),
      ),
    );
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('an expanded button fills the available width', (tester) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 300,
          child: AppButton(label: 'Go', expanded: true, onPressed: () {}),
        ),
      ),
    );
    expect(tester.getSize(find.byType(AppButton)).width, 300);
  });
}