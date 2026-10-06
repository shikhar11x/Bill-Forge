import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/features/customers/data/customer_mapper.dart';
import 'package:billforge/features/customers/domain/customer.dart';

void main() {
  final created = DateTime(2026, 1, 1);

  final row = CustomerRow(
    id: 'c1',
    name: 'Rahul Sharma',
    phone: '9876543210',
    email: null,
    gstin: '07AAPFU0939F1ZV',
    addressLine1: '12 Main Bazaar',
    addressLine2: null,
    city: 'Delhi',
    state: 'Delhi',
    pincode: '110001',
    creditLimitPaise: 500000,
    notes: null,
    archivedAt: null,
    createdAt: created,
    updatedAt: created,
  );

  test('maps a row to the domain model', () {
    expect(
      customerFromRow(row),
      Customer(
        id: 'c1',
        name: 'Rahul Sharma',
        phone: '9876543210',
        gstin: '07AAPFU0939F1ZV',
        addressLine1: '12 Main Bazaar',
        city: 'Delhi',
        state: 'Delhi',
        pincode: '110001',
        creditLimitPaise: 500000,
        createdAt: created,
        updatedAt: created,
      ),
    );
  });

  test('maps the domain model to a companion', () {
    final companion = customerToCompanion(customerFromRow(row));
    expect(companion.name.value, 'Rahul Sharma');
    expect(companion.creditLimitPaise.value, 500000);
    expect(companion.email.value, isNull);
  });

  test('locationLabel joins city and state, skipping blanks', () {
    final base = customerFromRow(row);
    expect(base.locationLabel, 'Delhi, Delhi');
    expect(base.copyWith(city: null).locationLabel, 'Delhi');
    expect(base.copyWith(city: null, state: null).locationLabel, '');
  });
}
