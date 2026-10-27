import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/reports/domain/report_data.dart';
import 'package:billforge/features/reports/domain/report_range.dart';
import 'package:billforge/features/reports/domain/stock_report.dart';

import '../../support/fakes.dart';
import '../../support/report_fakes.dart';

void main() {
  final range = ReportRange.between(
    DateTime(2026, 6, 1),
    DateTime(2026, 6, 30),
  );

  final products = [
    // 10 units at cost ₹50.00, sells ₹80.00.
    sampleProduct(
      id: 'a',
      name: 'Amul Butter',
      sellingPricePaise: 8000,
      stockMilli: 10000,
    ).copyWith(purchasePricePaise: 5000),
    // 2 units, low, no purchase price.
    sampleProduct(
      id: 'b',
      name: 'Biscuits',
      sellingPricePaise: 10000,
      stockMilli: 2000,
      lowStockThresholdMilli: 5000,
    ),
    sampleProduct(id: 'c', name: 'Chips', stockMilli: 0),
    sampleProduct(id: 'd', name: 'Service', trackStock: false),
    // Negative stock counts as zero.
    sampleProduct(
      id: 'e',
      name: 'Eggs',
      stockMilli: -3000,
    ).copyWith(purchasePricePaise: 600),
  ];

  test('valuation', () {
    final v = buildValuation(products);
    expect(v.trackedProducts, 4);
    expect(v.untrackedProducts, 1);
    expect(v.costValuePaise, 50000);
    expect(v.retailValuePaise, 100000);
    expect(v.retailOfCostedPaise, 80000);
    expect(v.potentialMarginPaise, 30000);
    expect(v.lowStock, 1);
    expect(v.outOfStock, 2); // Chips and Eggs
    expect(v.missingCost, 1); // Biscuits
  });

  test('an empty catalogue values at zero', () {
    final v = buildValuation(const []);
    expect(v.costValuePaise, 0);
    expect(v.potentialMarginPaise, 0);
  });

  group('buildStockDocument', () {
    final data = ReportData(
      purchases: [
        rPurchase(id: 'u1', total: 30000),
        rPurchase(id: 'u2', total: 20000),
        rPurchase(id: 'u3', supplierName: null, total: 5000),
      ],
    );
    final doc = buildStockDocument(
      products: products,
      data: data,
      range: range,
    );

    String metric(String label) =>
        doc.metrics.firstWhere((m) => m.label == label).value.text;

    test('metrics', () {
      expect(metric('Stock value (at cost)'), '₹500.00');
      expect(metric('Stock value (at selling price)'), '₹1,000.00');
      expect(metric('Potential margin'), '₹300.00');
      expect(metric('Low-stock items'), '1');
      expect(metric('Out of stock'), '2');
      expect(metric('Purchases in period'), '₹550.00');
    });

    test('highest stock value lists costed products in stock', () {
      final rows = doc.sections[0].table.rows;
      expect(rows, hasLength(1));
      expect(rows.single.map((c) => c.text), [
        'Amul Butter',
        '10 pcs',
        '₹500.00',
        '₹800.00',
      ]);
    });

    test('purchases are grouped by supplier, biggest first', () {
      final table = doc.sections[1].table;
      expect(table.rows.map((r) => r.map((c) => c.text).toList()), [
        ['Metro Wholesale', '2', '₹500.00'],
        ['No supplier', '1', '₹50.00'],
      ]);
      expect(table.footer!.map((c) => c.text), ['Total', '3', '₹550.00']);
    });

    test('warns about products with no purchase price', () {
      expect(
        doc.notes.any(
          (n) => n.contains('1 product in stock has no purchase price'),
        ),
        isTrue,
      );
    });
  });
}
