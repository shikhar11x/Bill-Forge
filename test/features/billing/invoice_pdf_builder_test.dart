import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/billing/data/pdf/invoice_pdf_builder.dart';
import 'package:billforge/features/billing/data/pdf/pdf_fonts.dart';
import 'package:billforge/features/billing/domain/cart_line.dart';
import 'package:billforge/features/billing/domain/discount.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/invoice_composer.dart';
import 'package:billforge/features/billing/domain/invoice_document.dart';
import 'package:billforge/features/billing/domain/invoice_template_options.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/billing/domain/shop_tax_context.dart';
import 'package:billforge/features/products/domain/product_unit.dart';
import 'package:billforge/features/shop/domain/gst_registration.dart';
import 'package:billforge/features/shop/domain/shop_profile.dart';

import '../../support/customer_fakes.dart';
import '../../support/fakes.dart';

InvoiceDocument makeDocument({
  required ShopProfile shop,
  bool interState = false,
}) {
  final context = ShopTaxContext.fromShop(shop);
  final composed = composeInvoice(
    id: 'inv_1',
    lines: const [
      CartLine(
        productId: 'p1',
        name: 'Basmati Rice 5 kg',
        hsnCode: '1006',
        unit: ProductUnit.piece,
        unitPricePaise: 45000,
        qtyMilli: 2000,
        discount: Discount(DiscountType.percent, 500),
        gstRatePercent: 5,
        trackStock: true,
        stockMilli: 10000,
      ),
      CartLine(
        productId: 'p2',
        name: 'Toor Dal',
        unit: ProductUnit.kilogram,
        unitPricePaise: 15000,
        qtyMilli: 2500,
        gstRatePercent: 5,
        trackStock: true,
        stockMilli: 10000,
      ),
    ],
    billDiscount: const Discount(DiscountType.amount, 1000),
    customer: sampleCustomer().copyWith(
      state: interState ? 'Delhi' : 'Haryana',
      gstin: '07AAPFU0939F1ZV',
    ),
    shop: context,
    createdAt: DateTime(2026, 6, 1),
    now: DateTime(2026, 6, 1, 14, 5),
  );
  final issued = composed.invoice.copyWith(
    invoiceNumber: 'INV-0042',
    status: InvoiceStatus.issued,
    paidPaise: 50000,
    issuedAt: DateTime(2026, 6, 1, 14, 5),
  );
  return InvoiceDocument(
    shop: shop,
    detail: InvoiceDetail(
      invoice: issued,
      items: composed.items,
      payments: [
        InvoicePayment(
          id: 'pay_1',
          invoiceId: 'inv_1',
          method: PaymentMethod.cash,
          amountPaise: 50000,
          paidAt: DateTime(2026, 6, 1, 14, 5),
        ),
      ],
    ),
  );
}

void main() {
  final fonts = PdfFonts.builtIn();

  final regularShop = sampleShop().copyWith(
    gstRegistration: GstRegistration.regular,
    gstin: '06AAPFU0939F1ZV',
    pricesIncludeTax: false,
    defaultGstRate: 5,
    email: 'shop@example.com',
    invoiceFooter: 'Thank you for shopping with us!',
    paymentInstructions: 'UPI: sharma@upi',
  );

  bool isPdf(Uint8List bytes) =>
      bytes.length > 4 &&
      bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46;

  for (final paper in InvoicePaper.values) {
    test('builds a PDF for a GST invoice on ${paper.label}', () async {
      final bytes = await buildInvoicePdf(
        document: makeDocument(shop: regularShop),
        options: InvoiceTemplateOptions(paper: paper),
        fonts: fonts,
      );
      expect(isPdf(bytes), isTrue);
    });
  }

  test('builds an inter-state (IGST) invoice', () async {
    final bytes = await buildInvoicePdf(
      document: makeDocument(shop: regularShop, interState: true),
      options: const InvoiceTemplateOptions(),
      fonts: fonts,
    );
    expect(isPdf(bytes), isTrue);
  });

  test('builds for unregistered and composition shops', () async {
    for (final registration in [
      GstRegistration.unregistered,
      GstRegistration.composition,
    ]) {
      final shop = sampleShop().copyWith(
        gstRegistration: registration,
        gstin: registration.hasGstin ? '06AAPFU0939F1ZV' : null,
      );
      for (final paper in InvoicePaper.values) {
        final bytes = await buildInvoicePdf(
          document: makeDocument(shop: shop),
          options: InvoiceTemplateOptions(paper: paper),
          fonts: fonts,
        );
        expect(isPdf(bytes), isTrue, reason: '$registration ${paper.label}');
      }
    }
  });

  test('builds with every optional section switched off', () async {
    final bytes = await buildInvoicePdf(
      document: makeDocument(shop: regularShop),
      options: const InvoiceTemplateOptions(
        showLogo: false,
        showHsn: false,
        showTaxSummary: false,
        showAmountInWords: false,
        showPaymentInstructions: false,
        showFooter: false,
        showSignature: false,
      ),
      fonts: fonts,
    );
    expect(isPdf(bytes), isTrue);
  });

  test('an unreadable or unsupported logo is skipped, not fatal', () async {
    final shop = regularShop.copyWith(
      logo: Uint8List.fromList([1, 2, 3, 4, 5]),
    );
    final bytes = await buildInvoicePdf(
      document: makeDocument(shop: shop),
      options: const InvoiceTemplateOptions(),
      fonts: fonts,
    );
    expect(isPdf(bytes), isTrue);

    // Looks like a PNG header but is not a valid image.
    final fake = regularShop.copyWith(
      logo: Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0, 0, 0, 0]),
    );
    final bytes2 = await buildInvoicePdf(
      document: makeDocument(shop: fake),
      options: const InvoiceTemplateOptions(),
      fonts: fonts,
    );
    expect(isPdf(bytes2), isTrue);
  });

  test('a long invoice flows onto extra A4 pages', () async {
    final document = makeDocument(shop: regularShop);
    final many = [
      for (var i = 0; i < 80; i++)
        document.items.first.copyWith(id: 'inv_1-$i', name: 'Item number $i'),
    ];
    final bytes = await buildInvoicePdf(
      document: InvoiceDocument(
        shop: regularShop,
        detail: InvoiceDetail(
          invoice: document.invoice,
          items: many,
          payments: document.payments,
        ),
      ),
      options: const InvoiceTemplateOptions(),
      fonts: fonts,
    );
    expect(isPdf(bytes), isTrue);
  });
}
