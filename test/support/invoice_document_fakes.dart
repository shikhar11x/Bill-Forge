import 'package:billforge/features/billing/domain/cart_line.dart';
import 'package:billforge/features/billing/domain/discount.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/invoice_composer.dart';
import 'package:billforge/features/billing/domain/invoice_document.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/billing/domain/shop_tax_context.dart';
import 'package:billforge/features/products/domain/product_unit.dart';
import 'package:billforge/features/shop/domain/shop_profile.dart';
import 'customer_fakes.dart';
import 'fakes.dart';

/// An issued invoice for an unregistered shop (no tax):
///   Basmati Rice 5 kg  2 pcs x ₹450.00 = ₹900.00
///   Toor Dal           2.5 kg x ₹150.00 = ₹375.00
/// Total ₹1,275.00 (no round-off). By default ₹500.00 is paid.
InvoiceDocument makeInvoiceDocument({
  ShopProfile? shop,
  bool walkIn = false,
  int paidPaise = 50000,
  int extraItems = 0,
  String firstItemName = 'Basmati Rice 5 kg',
}) {
  final seller = shop ??
      sampleShop().copyWith(
        paymentInstructions: 'UPI: sharma@upi',
        invoiceFooter: 'Thank you!',
      );

  final lines = <CartLine>[
    CartLine(
      productId: 'p1',
      name: firstItemName,
      unit: ProductUnit.piece,
      unitPricePaise: 45000,
      qtyMilli: 2000,
      gstRatePercent: 0,
      trackStock: false,
      stockMilli: 0,
    ),
    const CartLine(
      productId: 'p2',
      name: 'Toor Dal',
      unit: ProductUnit.kilogram,
      unitPricePaise: 15000,
      qtyMilli: 2500,
      gstRatePercent: 0,
      trackStock: false,
      stockMilli: 0,
    ),
    for (var i = 0; i < extraItems; i++)
      CartLine(
        productId: 'x$i',
        name: 'Extra item $i',
        unit: ProductUnit.piece,
        unitPricePaise: 1000,
        qtyMilli: 1000,
        gstRatePercent: 0,
        trackStock: false,
        stockMilli: 0,
      ),
  ];

  final composed = composeInvoice(
    id: 'inv_1',
    lines: lines,
    billDiscount: const Discount.none(),
    customer: walkIn ? null : sampleCustomer(),
    shop: ShopTaxContext.fromShop(seller),
    createdAt: DateTime(2026, 6, 1),
    now: DateTime(2026, 6, 1, 14, 5),
  );
  final issued = composed.invoice.copyWith(
    invoiceNumber: 'INV-0042',
    status: InvoiceStatus.issued,
    paidPaise: paidPaise,
    issuedAt: DateTime(2026, 6, 1, 14, 5),
  );

  return InvoiceDocument(
    shop: seller,
    detail: InvoiceDetail(
      invoice: issued,
      items: composed.items,
      payments: paidPaise > 0
          ? [
              InvoicePayment(
                id: 'pay_1',
                invoiceId: 'inv_1',
                method: PaymentMethod.cash,
                amountPaise: paidPaise,
                paidAt: DateTime(2026, 6, 1, 14, 5),
              ),
            ]
          : const [],
    ),
  );
}