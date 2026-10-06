import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/features/billing/application/bill_state.dart';
import 'package:billforge/features/billing/application/billing_providers.dart';
import 'package:billforge/features/billing/domain/bill_calculator.dart';
import 'package:billforge/features/billing/domain/cart_line.dart';
import 'package:billforge/features/billing/domain/discount.dart';
import 'package:billforge/features/billing/domain/shop_tax_context.dart';
import 'package:billforge/features/customers/application/customer_providers.dart';
import 'package:billforge/features/customers/domain/customer.dart';
import 'package:billforge/features/products/application/product_providers.dart';
import 'package:billforge/features/products/domain/product.dart';
import 'package:billforge/features/shop/application/shop_providers.dart';

class BillController extends Notifier<BillState> {
  @override
  BillState build() => const BillState();

  CartLine? _find(String productId) {
    for (final line in state.lines) {
      if (line.productId == productId) return line;
    }
    return null;
  }

  void addProduct(Product product) {
    if (_find(product.id) == null) {
      state = state.copyWith(
        lines: [...state.lines, CartLine.fromProduct(product)],
      );
    } else {
      increment(product.id);
    }
  }

  void increment(String productId) => _changeQty(productId, 1000);

  /// Going below one unit removes the line.
  void decrement(String productId) => _changeQty(productId, -1000);

  void _changeQty(String productId, int delta) {
    final line = _find(productId);
    if (line == null) return;
    setQuantity(productId, line.qtyMilli + delta);
  }

  void setQuantity(String productId, int qtyMilli) {
    if (qtyMilli <= 0) {
      removeLine(productId);
      return;
    }
    final clamped = qtyMilli > kMaxQtyMilli ? kMaxQtyMilli : qtyMilli;
    updateLine(_find(productId)?.copyWith(qtyMilli: clamped));
  }

  /// Replaces the line with the same product id.
  void updateLine(CartLine? updated) {
    if (updated == null) return;
    state = state.copyWith(
      lines: [
        for (final l in state.lines)
          l.productId == updated.productId ? updated : l,
      ],
    );
  }

  void removeLine(String productId) {
    state = state.copyWith(
      lines: [
        for (final l in state.lines)
          if (l.productId != productId) l,
      ],
    );
  }

  void setCustomer(Customer? customer) =>
      state = state.copyWith(customer: customer);

  void setBillDiscount(Discount discount) =>
      state = state.copyWith(billDiscount: discount);

  void clear() => state = const BillState();

  /// Loads a saved draft into the cart. False when it can't be loaded.
  Future<bool> loadDraft(String invoiceId) async {
    final detail = await ref
        .read(invoiceRepositoryProvider)
        .getDetail(invoiceId);
    if (detail == null || !detail.invoice.isDraft) return false;

    final products = ref.read(productRepositoryProvider);
    final lines = <CartLine>[];
    for (final item in detail.items) {
      final productId = item.productId;
      final product = productId == null
          ? null
          : await products.getById(productId);
      lines.add(
        CartLine(
          productId: productId ?? item.id,
          name: item.name,
          hsnCode: item.hsnCode,
          unit: item.unit,
          unitPricePaise: item.unitPricePaise,
          qtyMilli: item.qtyMilli,
          discount: item.discount,
          gstRatePercent: product?.gstRatePercent ?? item.gstRatePercent,
          trackStock: product?.trackStock ?? false,
          stockMilli: product?.stockMilli ?? 0,
        ),
      );
    }

    Customer? customer;
    final customerId = detail.invoice.customerId;
    if (customerId != null) {
      customer = await ref.read(customerRepositoryProvider).getById(customerId);
    }

    state = BillState(
      lines: lines,
      customer: customer,
      billDiscount: detail.invoice.billDiscount,
      draftId: invoiceId,
      draftCreatedAt: detail.invoice.createdAt,
    );
    return true;
  }
}

final billControllerProvider = NotifierProvider<BillController, BillState>(
  BillController.new,
);

final shopTaxContextProvider = Provider<ShopTaxContext>((ref) {
  final shop = shopOrNull(ref.watch(shopProfileProvider));
  if (shop == null) {
    return const ShopTaxContext(
      shopState: '',
      pricesIncludeTax: true,
      chargesTax: false,
    );
  }
  return ShopTaxContext.fromShop(shop);
});

final billTotalsProvider = Provider<BillTotals>((ref) {
  final bill = ref.watch(billControllerProvider);
  final shop = ref.watch(shopTaxContextProvider);
  return calculateBill(
    lines: bill.lines,
    billDiscount: bill.billDiscount,
    interState: shop.isInterState(bill.customer),
    pricesIncludeTax: shop.pricesIncludeTax,
    chargesTax: shop.chargesTax,
  );
});
