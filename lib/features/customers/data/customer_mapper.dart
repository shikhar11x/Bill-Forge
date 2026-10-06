import 'package:drift/drift.dart' show Value;

import 'package:billforge/core/database/app_database.dart';
import 'package:billforge/features/customers/domain/customer.dart';

Customer customerFromRow(CustomerRow r) => Customer(
  id: r.id,
  name: r.name,
  phone: r.phone,
  email: r.email,
  gstin: r.gstin,
  addressLine1: r.addressLine1,
  addressLine2: r.addressLine2,
  city: r.city,
  state: r.state,
  pincode: r.pincode,
  creditLimitPaise: r.creditLimitPaise,
  notes: r.notes,
  archivedAt: r.archivedAt,
  createdAt: r.createdAt,
  updatedAt: r.updatedAt,
);

CustomersCompanion customerToCompanion(Customer c) => CustomersCompanion(
  id: Value(c.id),
  name: Value(c.name),
  phone: Value(c.phone),
  email: Value(c.email),
  gstin: Value(c.gstin),
  addressLine1: Value(c.addressLine1),
  addressLine2: Value(c.addressLine2),
  city: Value(c.city),
  state: Value(c.state),
  pincode: Value(c.pincode),
  creditLimitPaise: Value(c.creditLimitPaise),
  notes: Value(c.notes),
  archivedAt: Value(c.archivedAt),
  createdAt: Value(c.createdAt),
  updatedAt: Value(c.updatedAt),
);
