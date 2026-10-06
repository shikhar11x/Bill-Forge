import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/features/shop/data/shop_mapper.dart';
import 'package:billforge/features/shop/domain/business_type.dart';
import 'package:billforge/features/shop/domain/gst_registration.dart';
import 'package:billforge/features/shop/domain/shop_profile.dart';

void main() {
  final created = DateTime(2026, 1, 1);

  ShopProfileRow row({
    String businessType = 'pharmacy',
    String gstRegistration = 'regular',
  }) => ShopProfileRow(
    id: 'shop_1',
    name: 'Health Plus',
    businessType: businessType,
    phone: '9876543210',
    email: null,
    addressLine1: '1 Market Road',
    addressLine2: null,
    city: 'Delhi',
    state: 'Delhi',
    pincode: '110001',
    gstRegistration: gstRegistration,
    gstin: '07AAPFU0939F1ZV',
    defaultGstRate: 12,
    pricesIncludeTax: true,
    currencyCode: 'INR',
    invoicePrefix: 'HP',
    nextInvoiceNumber: 5,
    invoiceFooter: null,
    paymentInstructions: null,
    logo: null,
    primaryColor: 0xFF22A06B,
    createdAt: created,
    updatedAt: created,
  );

  test('maps a row to the domain model', () {
    expect(
      shopFromRow(row()),
      ShopProfile(
        id: 'shop_1',
        name: 'Health Plus',
        businessType: BusinessType.pharmacy,
        phone: '9876543210',
        addressLine1: '1 Market Road',
        city: 'Delhi',
        state: 'Delhi',
        pincode: '110001',
        gstRegistration: GstRegistration.regular,
        gstin: '07AAPFU0939F1ZV',
        defaultGstRate: 12,
        invoicePrefix: 'HP',
        nextInvoiceNumber: 5,
        primaryColorValue: 0xFF22A06B,
        createdAt: created,
        updatedAt: created,
      ),
    );
  });

  test('unknown stored enum names fall back safely', () {
    final shop = shopFromRow(
      row(businessType: 'removed_type', gstRegistration: 'removed'),
    );
    expect(shop.businessType, BusinessType.other);
    expect(shop.gstRegistration, GstRegistration.unregistered);
  });

  test('maps the domain model to a companion', () {
    final companion = shopToCompanion(shopFromRow(row()));
    expect(companion.name.value, 'Health Plus');
    expect(companion.businessType.value, 'pharmacy');
    expect(companion.gstRegistration.value, 'regular');
    expect(companion.email.value, isNull);
    expect(companion.primaryColor.value, 0xFF22A06B);
  });
}
