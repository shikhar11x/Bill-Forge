import 'package:flutter_test/flutter_test.dart';

import 'package:billforge/features/shop/domain/business_type.dart';
import 'package:billforge/features/shop/domain/gst_registration.dart';
import 'package:billforge/features/shop/presentation/shop_form_state.dart';

void main() {
  ShopFormState filledForm() {
    final form = ShopFormState()
      ..name.text = ' Test Shop '
      ..phone.text = '98765 43210'
      ..addressLine1.text = '1 Road'
      ..city.text = 'Delhi'
      ..pincode.text = '110001'
      ..invoicePrefix.text = 'ts'
      ..gstin.text = '07aapfu0939f1zv'
      ..setBusinessType(BusinessType.grocery)
      ..setState('Delhi');
    addTearDown(form.dispose);
    return form;
  }

  test('trims, normalises phone and uppercases prefix', () {
    final shop = filledForm().toProfile(
      id: 'x',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    expect(shop.name, 'Test Shop');
    expect(shop.phone, '9876543210');
    expect(shop.invoicePrefix, 'TS');
  });

  test('unregistered shops drop GSTIN and tax rate', () {
    final shop = filledForm().toProfile(
      id: 'x',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    expect(shop.gstin, isNull);
    expect(shop.defaultGstRate, 0);
  });

  test('regular shops keep an uppercased GSTIN and the rate', () {
    final form = filledForm()
      ..setGstRegistration(GstRegistration.regular)
      ..defaultGstRate.text = '5';
    final shop = form.toProfile(
      id: 'x',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    expect(shop.gstin, '07AAPFU0939F1ZV');
    expect(shop.defaultGstRate, 5);
  });
}
