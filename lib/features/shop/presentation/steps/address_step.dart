import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/constants/indian_states.dart';
import 'package:billforge/core/utils/validators.dart';
import 'package:billforge/core/widgets/app_dropdown.dart';
import 'package:billforge/core/widgets/app_field_row.dart';
import 'package:billforge/core/widgets/app_text_field.dart';
import 'package:billforge/features/shop/presentation/shop_form_state.dart';

class AddressStep extends StatelessWidget {
  const AddressStep({required this.form, super.key});

  final ShopFormState form;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        AppTextField(
          label: 'Address line 1',
          hint: 'Shop no., building, street',
          controller: form.addressLine1,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          validator: (v) =>
              Validators.required(v, message: 'Address is required'),
        ),
        AppTextField(
          label: 'Address line 2 (optional)',
          hint: 'Area, landmark',
          controller: form.addressLine2,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
        ),
        AppFieldRow(
          children: [
            AppTextField(
              label: 'City',
              controller: form.city,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  Validators.required(v, message: 'City is required'),
            ),
            AppDropdown<String>(
              label: 'State',
              hint: 'Select state',
              value: form.state,
              items: IndianStates.all,
              itemLabel: (s) => s,
              onChanged: form.setState,
              validator: (v) => v == null ? 'Select a state' : null,
            ),
          ],
        ),
        AppTextField(
          label: 'PIN code',
          hint: '6 digits',
          controller: form.pincode,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          validator: Validators.pincode,
        ),
      ],
    );
  }
}
