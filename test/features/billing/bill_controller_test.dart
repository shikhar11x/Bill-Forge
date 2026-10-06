import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/billing/application/bill_controller.dart';
import 'package:billforge/features/billing/domain/cart_line.dart';
import 'package:billforge/features/billing/domain/discount.dart';
import 'package:billforge/features/shop/application/shop_providers.dart';
import 'package:billforge/features/shop/domain/gst_registration.dart';

import '../../support/fakes.dart';

void main() {
  ProviderContainer makeContainer({bool regular = false}) {
    final shop = regular
        ? sampleShop().copyWith(
            gstRegistration: GstRegistration.regular,
            pricesIncludeTax: false,
            defaultGstRate: 18,
          )
        : sampleShop();
    final container = ProviderContainer(
      overrides: [
        shopProfileProvider.overrideWith((ref) => Stream.value(shop)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('adding the same product twice raises its quantity', () {
    final container = makeContainer();
    final controller = container.read(billControllerProvider.notifier);
    final product = sampleProduct();

    controller
      ..addProduct(product)
      ..addProduct(product);

    final lines = container.read(billControllerProvider).lines;
    expect(lines, hasLength(1));
    expect(lines.single.qtyMilli, 2000);
  });

  test('decrementing below one unit removes the line', () {
    final container = makeContainer();
    final controller = container.read(billControllerProvider.notifier)
      ..addProduct(sampleProduct());

    controller.decrement('p1');
    expect(container.read(billControllerProvider).isEmpty, isTrue);
  });

  test('quantity is clamped to the maximum', () {
    final container = makeContainer();
    final controller = container.read(billControllerProvider.notifier)
      ..addProduct(sampleProduct())
      ..setQuantity('p1', 999999999);

    expect(
      container.read(billControllerProvider).lines.single.qtyMilli,
      kMaxQtyMilli,
    );
    controller.setQuantity('p1', 0);
    expect(container.read(billControllerProvider).isEmpty, isTrue);
  });

  test('updateLine only changes the matching product', () {
    final container = makeContainer();
    final controller = container.read(billControllerProvider.notifier)
      ..addProduct(sampleProduct(id: 'a', name: 'A'))
      ..addProduct(sampleProduct(id: 'b', name: 'B'));

    final a = container.read(billControllerProvider).lines.first;
    controller.updateLine(a.copyWith(unitPricePaise: 4200));

    final lines = container.read(billControllerProvider).lines;
    expect(lines[0].unitPricePaise, 4200);
    expect(lines[1].unitPricePaise, 1000);
  });

  test('totals follow the cart for an unregistered shop', () async {
    final container = makeContainer();
    await container.read(shopProfileProvider.future);
    container.read(billControllerProvider.notifier)
      ..addProduct(sampleProduct(sellingPricePaise: 5500))
      ..addProduct(sampleProduct(id: 'b', sellingPricePaise: 4500));

    expect(container.read(billTotalsProvider).grandTotalPaise, 10000);
  });

  test('totals add GST for a regular taxpayer', () async {
    final container = makeContainer(regular: true);
    await container.read(shopProfileProvider.future);
    container
        .read(billControllerProvider.notifier)
        .addProduct(
          sampleProduct(sellingPricePaise: 10000).copyWith(gstRatePercent: 18),
        );

    final totals = container.read(billTotalsProvider);
    expect(totals.taxPaise, 1800);
    expect(totals.grandTotalPaise, 11800);
  });

  test('bill discount and clear', () async {
    final container = makeContainer();
    await container.read(shopProfileProvider.future);
    final controller = container.read(billControllerProvider.notifier)
      ..addProduct(sampleProduct(sellingPricePaise: 10000))
      ..setBillDiscount(const Discount(DiscountType.percent, 1000));

    expect(container.read(billTotalsProvider).grandTotalPaise, 9000);

    controller.clear();
    expect(container.read(billControllerProvider).isEmpty, isTrue);
    expect(container.read(billControllerProvider).billDiscount.isNone, isTrue);
  });
}
