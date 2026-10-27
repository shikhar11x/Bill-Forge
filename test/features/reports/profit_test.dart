import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/reports/domain/profit.dart';

import '../../support/report_fakes.dart';

void main() {
  test('profit is taxable value minus cost, with returns taken off', () {
    final estimate = estimateProfit(
      items: [
        rItem(id: 'a', productId: 'p1', qtyMilli: 2000, taxable: 100000),
        rItem(id: 'b', productId: 'p2', taxable: 50000), // no purchase price
      ],
      creditItems: [rCnItem(productId: 'p1', qtyMilli: 1000, taxable: 50000)],
      costByProductId: const {'p1': 20000},
    );

    // p1 revenue 100000-50000, cost 2 units - 1 unit = 20000.
    expect(estimate.profitPaise, 30000);
    expect(estimate.costedRevenuePaise, 50000);
    expect(estimate.totalRevenuePaise, 100000);
    expect(estimate.coveragePercent, 50);
    expect(estimate.hasEstimate, isTrue);
  });

  test('with no known costs there is no estimate', () {
    final estimate = estimateProfit(
      items: [rItem()],
      creditItems: const [],
      costByProductId: const {},
    );
    expect(estimate.hasEstimate, isFalse);
    expect(estimate.profitPaise, 0);
    expect(estimate.coveragePercent, 0);
  });

  test('items without a product are never costed', () {
    final estimate = estimateProfit(
      items: [rItem(productId: null)],
      creditItems: const [],
      costByProductId: const {'p1': 100},
    );
    expect(estimate.hasEstimate, isFalse);
  });

  test('no sales at all reads as fully covered', () {
    final estimate = estimateProfit(
      items: const [],
      creditItems: const [],
      costByProductId: const {},
    );
    expect(estimate.coveragePercent, 100);
    expect(estimate.hasEstimate, isFalse);
  });

  test('fractional quantities are costed exactly', () {
    final estimate = estimateProfit(
      items: [rItem(qtyMilli: 2500, taxable: 37500)],
      creditItems: const [],
      costByProductId: const {'p1': 10000},
    );
    // Cost 2.5 x 100.00 = 250.00; revenue 375.00.
    expect(estimate.profitPaise, 12500);
  });
}
