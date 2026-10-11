import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/shop/domain/gst_registration.dart';
import 'package:billforge/features/shop/domain/shop_profile.dart';

/// Everything needed to print an invoice: the seller and the stored invoice.
class InvoiceDocument {
  const InvoiceDocument({required this.shop, required this.detail});

  final ShopProfile shop;
  final InvoiceDetail detail;

  Invoice get invoice => detail.invoice;
  List<InvoiceItem> get items => detail.items;
  List<InvoicePayment> get payments => detail.payments;

  bool get chargesTax => shop.gstRegistration.chargesTax;

  String get title => switch (shop.gstRegistration) {
        GstRegistration.regular => 'Tax Invoice',
        GstRegistration.composition => 'Bill of Supply',
        GstRegistration.unregistered => 'Invoice',
      };

  String? get declaration => shop.gstRegistration == GstRegistration.composition
      ? 'Composition taxable person, not eligible to collect tax on supplies.'
      : null;

  DateTime get date => invoice.issuedAt ?? invoice.updatedAt;

  List<String> get sellerAddressLines => [
        shop.addressLine1,
        if (shop.addressLine2 != null) shop.addressLine2!,
        '${shop.city}, ${shop.state} - ${shop.pincode}',
      ];
}