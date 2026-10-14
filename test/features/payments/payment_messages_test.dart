import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/payments/domain/payment_messages.dart';
import 'package:billforge/features/payments/domain/statement.dart';
import '../../support/fakes.dart';
import '../../support/payment_fakes.dart';
import 'statement_test.dart' as statement_fixture;

void main() {
  final now = DateTime(2026, 6, 15, 10);
  final shop = sampleShop().copyWith(paymentInstructions: 'UPI: sharma@upi');

  final invoices = [
    sampleOpenInvoice(
      id: 'i1',
      number: 'INV-0001',
      total: 100000,
      dueDate: DateTime(2026, 6, 10),
    ),
    sampleOpenInvoice(
      id: 'i2',
      number: 'INV-0002',
      total: 50000,
      paid: 20000,
      dueDate: DateTime(2026, 6, 20),
    ),
    sampleOpenInvoice(id: 'i3', number: 'INV-0003', total: 20000),
  ];

  test('reminder lists what is pending and the total', () {
    final message = buildReminderMessage(
      shop: shop,
      customerName: 'Rahul Sharma',
      openInvoices: invoices,
      now: now,
    );

    expect(message, contains('*Sharma General Store*'));
    expect(message, contains('Payment reminder'));
    expect(message, contains('Hello Rahul Sharma,'));
    expect(
      message,
      contains('• INV-0001 · 01 Jun 2026 · ₹1,000.00 (