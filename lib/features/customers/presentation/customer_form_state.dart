import 'package:flutter/material.dart';

import 'package:billforge/core/utils/money.dart';
import 'package:billforge/core/utils/phone.dart';
import 'package:billforge/features/customers/domain/customer.dart';

class CustomerFormState extends ChangeNotifier {
  CustomerFormState([Customer? existing])
    : name = TextEditingController(text: existing?.name),
      phone = TextEditingController(text: existing?.phone),
      email = TextEditingController(text: existing?.email),
      gstin = TextEditingController(text: existing?.gstin),
      addressLine1 = TextEditingController(text: existing?.addressLine1),
      addressLine2 = TextEditingController(text: existing?.addressLine2),
      city = TextEditingController(text: existing?.city),
      pincode = TextEditingController(text: existing?.pincode),
      creditLimit = TextEditingController(
        text: existing?.creditLimitPaise == null
            ? ''
            : paiseToInput(existing!.creditLimitPaise!),
      ),
      notes = TextEditingController(text: existing?.notes),
      state = existing?.state;

  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController email;
  final TextEditingController gstin;
  final TextEditingController addressLine1;
  final TextEditingController addressLine2;
  final TextEditingController city;
  final TextEditingController pincode;
  final TextEditingController creditLimit;
  final TextEditingController notes;

  String? state;

  void setState(String? v) {
    state = v;
    notifyListeners();
  }

  String? _optional(TextEditingController c) {
    final text = c.text.trim();
    return text.isEmpty ? null : text;
  }

  /// Call only after the form has validated.
  Customer toCustomer({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? archivedAt,
  }) {
    final rawPhone = _optional(phone);
    return Customer(
      id: id,
      name: name.text.trim(),
      phone: rawPhone == null ? null : normalizeIndianPhone(rawPhone),
      email: _optional(email)?.toLowerCase(),
      gstin: _optional(gstin)?.toUpperCase(),
      addressLine1: _optional(addressLine1),
      addressLine2: _optional(addressLine2),
      city: _optional(city),
      state: state,
      pincode: _optional(pincode),
      creditLimitPaise: parsePaise(creditLimit.text),
      notes: _optional(notes),
      archivedAt: archivedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  void dispose() {
    for (final c in [
      name,
      phone,
      email,
      gstin,
      addressLine1,
      addressLine2,
      city,
      pincode,
      creditLimit,
      notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }
}
