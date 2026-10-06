import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:billforge/features/billing/domain/discount.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/products/domain/product_unit.dart';

part 'invoice.freezed.dart';

enum InvoiceStatus {
  draft,
  issued;

  static InvoiceStatus fromName(String name) =>
      values.firstWhere((e) => e.name == name, orElse: () => draft);
}

enum PaymentStatus { unpaid, partial, paid }

@freezed
abstract class Invoice with _$Invoice {
  const Invoice._();

  const factory Invoice({
    required String id,

    /// Null until the invoice is issued.
    String? invoiceNumber,
    required InvoiceStatus status,
    String? customerId,

    /// Customer details are copied so later edits don't change the invoice.
    String? customerName,
    String? customerPhone,
    String? customerGstin,
    required String placeOfSupply,
    required bool isInterState,
    required bool pricesIncludeTax,
    @Default(Discount.none()) Discount billDiscount,
    required int discountPaise,
    required int taxablePaise,
    required int cgstPaise,
    required int sgstPaise,
    required int igstPaise,
    required int roundOffPaise,
    required int grandTotalPaise,
    @Default(0) int paidPaise,
    DateTime? issuedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Invoice;

  bool get isDraft => status == InvoiceStatus.draft;
  int get taxPaise => cgstPaise + sgstPaise + igstPaise;
  int get duePaise => grandTotalPaise - paidPaise;

  PaymentStatus get paymentStatus {
    if (paidPaise >= grandTotalPaise) return PaymentStatus.paid;
    return paidPaise <= 0 ? PaymentStatus.unpaid : PaymentStatus.partial;
  }
}

@freezed
abstract class InvoiceItem with _$InvoiceItem {
  const factory InvoiceItem({
    required String id,
    required String invoiceId,
    required int position,
    String? productId,
    required String name,
    String? hsnCode,
    required ProductUnit unit,
    required int qtyMilli,
    required int unitPricePaise,
    @Default(Discount.none()) Discount discount,
    required int gstRatePercent,

    /// Line discount plus this line's share of the bill discount.
    required int discountPaise,
    required int taxablePaise,
    required int cgstPaise,
    required int sgstPaise,
    required int igstPaise,
    required int totalPaise,
  }) = _InvoiceItem;
}

@freezed
abstract class InvoicePayment with _$InvoicePayment {
  const factory InvoicePayment({
    required String id,
    required String invoiceId,
    required PaymentMethod method,
    required int amountPaise,
    required DateTime paidAt,
  }) = _InvoicePayment;
}

class InvoiceDetail {
  const InvoiceDetail({
    required this.invoice,
    required this.items,
    this.payments = const [],
  });

  final Invoice invoice;
  final List<InvoiceItem> items;
  final List<InvoicePayment> payments;
}
