import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/utils/validators.dart';
import 'package:billforge/core/widgets/app_dropdown.dart';
import 'package:billforge/core/widgets/app_field_row.dart';
import 'package:billforge/core/widgets/app_text_field.dart';
import 'package:billforge/features/shop/domain/business_type.dart';
import 'package:billforge/features/shop/presentation/shop_form_state.dart';

class BusinessStep extends StatelessWidget {
  const BusinessStep({required this.form, super.key});

  final ShopFormState form;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        AppTextField(
          label: 'Shop name',
          hint: 'e.g. Sharma General Store',
          controller: form.name,
          prefixIcon: Icons.storefront_outlined,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          validator: (v) =>
              Validators.required(v, message: 'Shop name is required'),
        ),
        AppDropdown<BusinessType>(
          label: 'Business type',
          hint: 'Select one',
          value: form.businessType,
          items: BusinessType.values,
          itemLabel: (t) => t.label,
          onChanged: form.setBusinessType,
          validator: (v) => v == null ? 'Select your business type' : null,
        ),
        AppFieldRow(
          children: [
            AppTextField(
              label: 'Phone',
              hint: '98765 43210',
              controller: form.phone,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: Validators.phone,
            ),
            AppTextField(
              label: 'Email (optional)',
              controller: form.email,
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.optional(Validators.email),
            ),
          ],
        ),
      ],
    );
  }
}
