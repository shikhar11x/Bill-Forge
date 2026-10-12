import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/inventory/domain/purchase_math.dart';

void main() {
  test('line total is quantity x cost, rounded half up to a paisa', () {
    expect(purchaseLineTotal(1000, 12000), 12000);
    expect(purchaseLineTotal(2500, 12000), 30000);
    expect(purchaseLineTotal(1500, 333), 500);
    expect(purchaseLineTotal(1, 1), 0);
    expect(purchaseLineTotal(500, 1), 1);
    expect(purchaseLineTotal(0, 5000), 0);
  });

  test('the largest allowed line stays exact', () {
    final total = purchaseLineTotal(kMaxStockQtyMilli, kMaxUnitCostPaise);
    expect(total, 999999900000);
  });
}
