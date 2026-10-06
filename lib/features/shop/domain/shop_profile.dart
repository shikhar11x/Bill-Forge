import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:billforge/features/shop/domain/business_type.dart';
import 'package:billforge/features/shop/domain/gst_registration.dart';

part 'shop_profile.freezed.dart';

@freezed
abstract class ShopProfile with _$ShopProfile {
  const factory ShopProfile({
    required String id,
    required String name,
    required BusinessType businessType,
    required String phone,
    String? email,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String pincode,
    required GstRegistration gstRegistration,
    String? gstin,
    @Default(18) int defaultGstRate,
    @Default(true) bool pricesIncludeTax,
    @Default('INR') String currencyCode,
    required String invoicePrefix,
    required int nextInvoiceNumber,
    String? invoiceFooter,
    String? paymentInstructions,
    Uint8List? logo,
    required int primaryColorValue,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ShopProfile;
}
