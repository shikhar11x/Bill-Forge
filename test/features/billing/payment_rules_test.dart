import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/billing/domain/payment_method.dart';

void main() {
  const cash = PaymentMethod.cash;

  test('exact payment is valid without a customer', () {
    expect(
      validatePayments(
        totalPaise: 5000,
        entries: [const PaymentEntry(method: cash, amountPaise: 5000)],
        hasCustomer: false,
      ),
      isNull,
    );
  });

  test('split payments that add up are valid', () {
    expect(
      validatePayments(
        totalPaise: 5000,
        entries: const [
          PaymentEntry(method: cash, amountPaise: 3000),
          PaymentEntry(method: PaymentMethod.upi, amountPaise: 2000),
        ],
        hasCustomer: false,
      ),
      isNull,
    );
  });

  test('overpaying is rejected', () {
    expect(
      validatePayments(
        totalPaise: 5000,
        entries: const [PaymentEntry(method: cash, amountPaise: 6000)],
        hasCustomer: true,
      ),
      'Payments cannot exceed the bill total.',
    );
  });

  test('a shortfall needs a customer to owe it', () {
    const partial = [PaymentEntry(method: cash, amountPaise: 2000)];
    expect(
      validatePayments(totalPaise: 5000, entries: partial, hasCustomer: false),
      isNotNull,
    );
    expect(
      validatePayments(totalPaise: 5000, entries: partial, hasCustomer: true),
      isNull,
    );
  });

  test('a fully credit sale is valid with a customer', () {
    expect(
      validatePayments(totalPaise: 5000, entries: const [], hasCustomer: true),
      isNull,
    );
  });

  test('zero-amount payments are rejected', () {
    expect(
      validatePayments(
        totalPaise: 5000,
        entries: const [PaymentEntry(method: cash, amountPaise: 0)],
        hasCustomer: true,
      ),
      'Enter an amount for every payment.',
    );
  });

  test('a zero total needs no payment', () {
    expect(
      validatePayments(totalPaise: 0, entries: const [], hasCustomer: false),
      isNull,
    );
  });
}
