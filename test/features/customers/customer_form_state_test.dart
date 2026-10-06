import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/customers/presentation/customer_form_state.dart';

import '../../support/customer_fakes.dart';

void main() {
  test('normalises text fields', () {
    final form = CustomerFormState()
      ..name.text = ' Rahul Sharma '
      ..phone.text = '+91 98765-43210'
      ..email.text = 'Rahul@Example.COM'
      ..gstin.text = '07aapfu0939f1zv'
      ..creditLimit.text = '5000';
    addTearDown(form.dispose);

    final customer = form.toCustomer(
      id: 'c',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    expect(customer.name, 'Rahul Sharma');
    expect(customer.phone, '9876543210');
    expect(customer.email, 'rahul@example.com');
    expect(customer.gstin, '07AAPFU0939F1ZV');
    expect(customer.creditLimitPaise, 500000);
  });

  test('blank optional fields become null', () {
    final form = CustomerFormState()..name.text = 'Walk-in Regular';
    addTearDown(form.dispose);

    final customer = form.toCustomer(
      id: 'c',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    expect(customer.phone, isNull);
    expect(customer.email, isNull);
    expect(customer.gstin, isNull);
    expect(customer.creditLimitPaise, isNull);
    expect(customer.state, isNull);
  });

  test('prefills from an existing customer', () {
    final form = CustomerFormState(sampleCustomer(creditLimitPaise: 250050));
    addTearDown(form.dispose);

    expect(form.name.text, 'Rahul Sharma');
    expect(form.creditLimit.text, '2500.50');
    expect(form.state, 'Haryana');
  });
}
