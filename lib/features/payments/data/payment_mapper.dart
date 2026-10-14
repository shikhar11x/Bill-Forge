import 'package:drift/drift.dart' show Value;

import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/payments/domain/customer_payment.dart';

CustomerPayment receiptFromRow(CustomerPaymentRow r) => CustomerPayment(
      id: r.id,
      customerId: r.customerId,
      method: PaymentMethod.fromName(r.method),
      amountPaise: r.amountPaise,
      note: r.note,
      receivedAt: r.receivedAt,
      createdAt: r.createdAt,
    );

CustomerPaymentsCompanion receiptToCompanion(CustomerPayment p) =>
    CustomerPaymentsCompanion(
      id: Value(p.id),
      customerId: Value(p.customerId),
      method: Value(p.method.name),
      amountPaise: Value(p.amountPaise),
      note: Value(p.note),
      receivedAt: Value(p.receivedAt),
      createdAt: Value(p.createdAt),
    );