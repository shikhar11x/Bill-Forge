import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/inventory/presentation/purchase_form_state.dart';
import 'package:billforge/features/products/domain/product_unit.dart';
import '../../support/fakes.dart';
import '../../support/inventory_fakes.dart';

void main() {
  PurchaseFormState makeForm() {
    final form = PurchaseFormState(now: DateTime(2026, 6, 1));
    addTearDown(form.dispose);
    return form;
  }

  test('adding a product prefills its last purchase price', () {
    final form = makeForm();
    form.addProduct(sampleProduct().copyWith(purchasePricePaise: 8050));
    expect(form.lines.single.qty.text, '1');
    expect(form.lines.single.cost.text, '80.50');
  });

  test('a product can only be added once', () {
    final form = makeForm();
    final product = sampleProduct();
    expect(form.addProduct(product), isTrue);
    expect(form.addProduct(product), isFalse);
    expect(form.lines, hasLength(1));
  });

  test('totals follow the typed quantities and costs', () {
    final form = makeForm()
      ..addProduct(sampleProduct(id: 'a'))
      ..addProduct(sampleProduct(id: 'b').copyWith(unit: ProductUnit.kilogram));
    form.lines[0]
      ..qty.text = '10'
      ..cost.text = '8';
    form.lines[1]
      ..qty.text = '2.5'
      ..cost.text = '120';

    expect(form.lines[0].totalPaise, 8000);
    expect(form.lines[1].totalPaise, 30000);
    expect(form.totalPaise, 38000);
  });

  test('an unfinished line counts as zero', () {
    final form = makeForm()..addProduct(sampleProduct());
    form.lines.single.cost.text = '';
    expect(form.lines.single.totalPaise, isNull);
    expect(form.totalPaise, 0);
  });

  test('removing a line updates the total', () {
    final form = makeForm()..addProduct(sampleProduct());
    form.lines.single
      ..qty.text = '2'
      ..cost.text = '5';
    expect(form.totalPaise, 1000);
    form.removeLine(form.lines.single);
    expect(form.lines, isEmpty);
    expect(form.totalPaise, 0);
  });

  test('toDetail builds the purchase with snapshots and totals', () {
    final form = makeForm()
      ..setSupplier(sampleSupplier())
      ..addProduct(sampleProduct());
    form.lines.single
      ..qty.text = '10'
      ..cost.text = '8';
    form.billNumber.text = ' B-77 ';
    form.note.text = '';

    final detail = form.toDetail(id: 'pur_1', now: DateTime(2026, 6, 1, 10));
    final purchase = detail.purchase;
    expect(purchase.supplierId, 's1');
    expect(purchase.supplierName, 'Metro Wholesale');
    expect(purchase.billNumber, 'B-77');
    expect(purchase.note, isNull);
    expect(purchase.totalPaise, 8000);
    expect(purchase.purchasedAt, DateTime(2026, 6, 1));

    final item = detail.items.single;
    expect(item.id, 'pur_1-1');
    expect(item.productName, 'Parle-G Biscuits');
    expect(item.qtyMilli, 10000);
    expect(item.unitCostPaise, 800);
    expect(item.totalPaise, 8000);
  });
}