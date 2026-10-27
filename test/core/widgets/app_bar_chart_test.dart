import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/app/theme/app_theme.dart';
import 'package:billforge/core/widgets/app_bar_chart.dart';

void main() {
  Future<void> pump(WidgetTester tester, List<BarChartItem> items) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: AppBarChart(items: items, emptyMessage: 'Nothing here'),
            ),
          ),
        ),
      );

  testWidgets('draws one bar with a tooltip per item', (tester) async {
    await pump(tester, const [
      BarChartItem(label: 'Mon', value: 100, tooltip: 'Mon: ₹1.00'),
      BarChartItem(label: 'Tue', value: 300, tooltip: 'Tue: ₹3.00'),
      BarChartItem(label: 'Wed', value: 0),
    ]);

    expect(find.byType(Tooltip), findsNWidgets(3));
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Nothing here'), findsNothing);
  });

  testWidgets('shows the empty message with no items or all zeros', (
    tester,
  ) async {
    await pump(tester, const []);
    expect(find.text('Nothing here'), findsOneWidget);

    await pump(tester, const [BarChartItem(label: 'Mon', value: 0)]);
    expect(find.text('Nothing here'), findsOneWidget);
  });

  testWidgets('long series show only some labels', (tester) async {
    await pump(tester, [
      for (var i = 1; i <= 30; i++) BarChartItem(label: 'D$i', value: i),
    ]);
    expect(find.byType(Tooltip), findsNWidgets(30));
    expect(find.text('D1'), findsOneWidget);
    expect(find.text('D2'), findsNothing);
  });
}
