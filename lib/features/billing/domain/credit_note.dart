import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/products/domain/product_unit.dart';

part 'credit_note.freezed.dart';

enum ReturnReason {
  damaged('Damaged or defective'),
  wrongItem('Wrong item'),
  notNeeded('Customer changed mind'),
  quality('Quality issue'),
  other('Other'),
  cancellation('Invoice cancelled');

  const ReturnReason(this.label);

  final String label;

  static ReturnReason fromName(String name) =>
      values.firstWhere((e) => e.name == name, orElse: () => other);
}

@freezed
abstract class CreditNote with _$CreditNote {
  const CreditNote._();

  const factory CreditNote({
    required String id,
    required String creditNoteNumber,
    required String invoiceId,

    /// Copied so the note stays readable on its own.
    required String invoiceNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerGstin,
    required String placeOfSupply,
    required bool isInterState,
    required ReturnReason reason,
    String? note,
    required bool isCancellation,

    /// Whether the returned goods went back into stock.
    required bool restocked,
    required int taxablePaise,
    required int cgstPaise,
    required int sgstPaise,
    required int igstPaise,
    required int roundOffPaise,
    required int totalPaise,

    /// Part of [totalPaise] that reduced what the customer owed.
    required int appliedPaise,

    /// Part of [totalPaise] paid back to the customer.
    required int refundPaise,
    PaymentMethod? refundMethod,
    required DateTime issuedAt,
  }) = _CreditNote;

  int get taxPaise => cgstPaise + sgstPaise + igstPaise;
}

@freezed
abstract class CreditNoteItem with _$CreditNoteItem {
  const factory CreditNoteItem({
    required String id,
    required String creditNoteId,
    required String invoiceItemId,
    required int position,
    String? productId,
    required String name,
    String? hsnCode,
    required ProductUnit unit,
    required int qtyMilli,
    required int unitPricePaise,
    required int gstRatePercent,
    required int taxablePaise,
    required int cgstPaise,
    required int sgstPaise,
    required int igstPaise,
    required int totalPaise,
  }) = _CreditNoteItem;
}

class CreditNoteDetail {
  const CreditNoteDetail({required this.creditNote, required this.items});

  final CreditNote creditNote;
  final List<CreditNoteItem> items;
}
