import 'package:drift/drift.dart' show Value;

import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/features/shop/domain/business_type.dart';
import 'package:billforge/features/shop/domain/gst_registration.dart';
import 'package:billforge/features/shop/domain/shop_profile.dart';

ShopProfile shopFromRow(ShopProfileRow r) => ShopProfile(
  id: r.id,
  name: r.name,
  businessType: BusinessType.fromName(r.businessType),
  phone: r.phone,
  email: r.email,
  addressLine1: r.addressLine1,
  addressLine2: r.addressLine2,
  city: r.city,
  state: r.state,
  pincode: r.pincode,
  gstRegistration: GstRegistration.fromName(r.gstRegistration),
  gstin: r.gstin,
  defaultGstRate: r.defaultGstRate,
  pricesIncludeTax: r.pricesIncludeTax,
  currencyCode: r.currencyCode,
  invoicePrefix: r.invoicePrefix,
  nextInvoiceNumber: r.nextInvoiceNumber,
  invoiceFooter: r.invoiceFooter,
  paymentInstructions: r.paymentInstructions,
  logo: r.logo,
  primaryColorValue: r.primaryColor,
  createdAt: r.createdAt,
  updatedAt: r.updatedAt,
);

ShopProfilesCompanion shopToCompanion(ShopProfile s) => ShopProfilesCompanion(
  id: Value(s.id),
  name: Value(s.name),
  businessType: Value(s.businessType.name),
  phone: Value(s.phone),
  email: Value(s.email),
  addressLine1: Value(s.addressLine1),
  addressLine2: Value(s.addressLine2),
  city: Value(s.city),
  state: Value(s.state),
  pincode: Value(s.pincode),
  gstRegistration: Value(s.gstRegistration.name),
  gstin: Value(s.gstin),
  defaultGstRate: Value(s.defaultGstRate),
  pricesIncludeTax: Value(s.pricesIncludeTax),
  currencyCode: Value(s.currencyCode),
  invoicePrefix: Value(s.invoicePrefix),
  nextInvoiceNumber: Value(s.nextInvoiceNumber),
  invoiceFooter: Value(s.invoiceFooter),
  paymentInstructions: Value(s.paymentInstructions),
  logo: Value(s.logo),
  primaryColor: Value(s.primaryColorValue),
  createdAt: Value(s.createdAt),
  updatedAt: Value(s.updatedAt),
);
