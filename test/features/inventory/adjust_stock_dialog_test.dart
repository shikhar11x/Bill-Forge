import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/app/theme/app_theme.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/features/inventory/application/inventory_providers.dart';
import 'package:billforge/features/inventory/domain/movement_type.dart';
import 'package:billforge/features/inventory/presentation/widgets/adjust_stock_dialog.dart';

import '../../support/fakes.dart';
import '../../support/inventory_fakes.dart';

void main() {
  late FakeStockRepository repo;

  setUp(() => repo = FakeStockRepository());

  Future<void> openDialog(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [stockRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => AdjustStockDialog.show(
                  context,
                  sampleProduct(stockMilli: 10000),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('set-to records the difference and closes', (tester) async {
    await openDialog(tester);
    await tester.enterText(find.byType(TextFormField).first, '15');
    await tester.pump();
    expect(find.text('New stock: 15 pcs'), findsOneWidget);

    await tester.tap(find.text('Save adjustment'));
    await tester.pumpAndSettle();

    expect(repo.calls, hasLength(1));
    expect(repo.calls.single.productId, 'p1');
    expect(repo.calls.single.deltaMilli, 5000);
    expect(repo.calls.single.reason, AdjustmentReason.recount);
    expect(find.byType(AdjustStockDialog), findsNothing);
  });

  testWidgets('remove with a reason records a negative change', (tester) async {
    await openDialog(tester);
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '3');

    await tester.tap(find.byType(DropdownButtonFormField<AdjustmentReason>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Damaged').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save adjustment'));
    await tester.pumpAndSettle();

    expect(repo.calls.single.deltaMilli, -3000);
    expect(repo.calls.single.reason, AdjustmentReason.damaged);
  });

  testWidgets('removing more than the stock is blocked', (tester) async {
    await openDialog(tester);
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '11');
    await tester.tap(find.text('Save adjustment'));
    await tester.pumpAndSettle();

    expect(
      find.text('Cannot remove more than the current stock'),
      findsOneWidget,
    );
    expect(repo.calls, isEmpty);
  });

  testWidgets('a repository conflict is shown inside the dialog', (
    tester,
  ) async {
    repo.failure = const ConflictFailure('Stock cannot go below zero.');
    await openDialog(tester);
    await tester.enterText(find.byType(TextFormField).first, '5');
    await tester.tap(find.text('Save adjustment'));
    await tester.pumpAndSettle();

    expect(find.text('Stock cannot go below zero.'), findsOneWidget);
    expect(find.byType(AdjustStockDialog), findsOneWidget);
  });
}
