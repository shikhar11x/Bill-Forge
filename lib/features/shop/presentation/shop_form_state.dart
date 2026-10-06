import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:billforge/app/theme/app_colors.dart';
import 'package:billforge/features/shop/domain/business_type.dart';
import 'package:billforge/features/shop/domain/gst_registration.dart';
import 'package:billforge/features/shop/domain/shop_profile.dart';

/// Draft values for the setup wizard. Text lives in controllers so values
/// survive moving between steps; the rest notifies listeners.
class ShopFormState extends ChangeNotifier {
  ShopFormState([ShopProfile? existing])
    : name = TextEditingController(text: existing?.name),
      phone = TextEditingController(text: existing?.phone),
      email = TextEditingController(text: existing?.email),
      addressLine1 = TextEditingController(text: existing?.addressLine1),
      addressLine2 = TextEditingController(text: existing?.addressLine2),
      city = TextEditingController(text: existing?.city),
      pincode = TextEditingController(text: existing?.pincode),
      gstin = TextEditingController(text: existing?.gstin),
      defaultGstRate = TextEditingController(
        text: (existing == null || existing.defaultGstRate == 0)
            ? '18'
            : '${existing.defaultGstRate}',
      ),
      invoicePrefix = TextEditingController(
        text: existing?.invoicePrefix ?? 'INV',
      ),
      nextInvoiceNumber = TextEditingController(
        text: '${existing?.nextInvoiceNumber ?? 1}',
      ),
      invoiceFooter = TextEditingController(text: existing?.invoiceFooter),
      paymentInstructions = TextEditingController(
        text: existing?.paymentInstructions,
      ),
      businessType = existing?.businessType,
      state = existing?.state,
      gstRegistration =
          existing?.gstRegistration ?? GstRegistration.unregistered,
      pricesIncludeTax = existing?.pricesIncludeTax ?? true,
      logo = existing?.logo,
      primaryColorValue =
          existing?.primaryColorValue ?? AppColors.defaultAccent.toARGB32();

  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController email;
  final TextEditingController addressLine1;
  final TextEditingController addressLine2;
  final TextEditingController city;
  final TextEditingController pincode;
  final TextEditingController gstin;
  final TextEditingController defaultGstRate;
  final TextEditingController invoicePrefix;
  final TextEditingController nextInvoiceNumber;
  final TextEditingController invoiceFooter;
  final TextEditingController paymentInstructions;

  BusinessType? businessType;
  String? state;
  GstRegistration gstRegistration;
  bool pricesIncludeTax;
  Uint8List? logo;
  int primaryColorValue;

  void setBusinessType(BusinessType? v) {
    businessType = v;
    notifyListeners();
  }

  void setState(String? v) {
    state = v;
    notifyListeners();
  }

  void setGstRegistration(GstRegistration v) {
    gstRegistration = v;
    notifyListeners();
  }

  void setPricesIncludeTax(bool v) {
    pricesIncludeTax = v;
    notifyListeners();
  }

  void setLogo(Uint8List? v) {
    logo = v;
    notifyListeners();
  }

  void setPrimaryColor(int v) {
    primaryColorValue = v;
    notifyListeners();
  }

  String? _optional(TextEditingController c) {
    final text = c.text.trim();
    return text.isEmpty ? null : text;
  }

  /// Call only after every step has validated.
  ShopProfile toProfile({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return ShopProfile(
      id: id,
      name: name.text.trim(),
      businessType: businessType!,
      phone: phone.text.replaceAll(RegExp(r'[\s-]'), ''),
      email: _optional(email),
      addressLine1: addressLine1.text.trim(),
      addressLine2: _optional(addressLine2),
      city: city.text.trim(),
      state: state!,
      pincode: pincode.text.trim(),
      gstRegistration: gstRegistration,
      gstin: gstRegistration.hasGstin ? gstin.text.trim().toUpperCase() : null,
      defaultGstRate: gstRegistration.chargesTax
          ? int.parse(defaultGstRate.text.trim())
          : 0,
      pricesIncludeTax: pricesIncludeTax,
      invoicePrefix: invoicePrefix.text.trim().toUpperCase(),
      nextInvoiceNumber: int.parse(nextInvoiceNumber.text.trim()),
      invoiceFooter: _optional(invoiceFooter),
      paymentInstructions: _optional(paymentInstructions),
      logo: logo,
      primaryColorValue: primaryColorValue,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  void dispose() {
    for (final c in [
      name,
      phone,
      email,
      addressLine1,
      addressLine2,
      city,
      pincode,
      gstin,
      defaultGstRate,
      invoicePrefix,
      nextInvoiceNumber,
      invoiceFooter,
      paymentInstructions,
    ]) {
      c.dispose();
    }
    super.dispose();
  }
}
