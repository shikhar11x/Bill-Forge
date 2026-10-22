import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:billforge/features/billing/domain/payment_method.dart';

part '../data/domain/customer_payment.freezed.dart';

/// A payment received from a customer (a receipt). It is spread across the
/// customer's open invoices through `InvoicePayment.receiptId`.
@freezed
abstract class CustomerPayment with _$CustomerPayment {
  const factory CustomerPayment({
    required String id,
    required String customerId,
    required PaymentMethod method,
    required int amountPaise,
    String? note,
    required DateTime receivedAt,
    required DateTime createdAt,
  }) = _CustomerPayment;
}
