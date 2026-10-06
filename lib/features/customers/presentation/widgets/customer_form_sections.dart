import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/constants/indian_states.dart';
import 'package:billforge/core/utils/amount_validator.dart';
import 'package:billforge/core/utils/validators.dart';
import 'package:billforge/core/widgets/app_dropdown.dart';
import 'package:billforge/core/widgets/app_field_row.dart';
import 'package:billforge/core/widgets/app_text_field.dart';
import 'package:billforge/features/customers/presentation/customer_form_state.dart';

const _noState = '__none__';

class ContactSection extends StatelessWidget {
  const ContactSection({required this.form, super.key});

  final CustomerFormState form;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        AppTextField(
          label: 'Customer name',
          hint: 'e.g. Rahul Sharma',
          controller: form.name,
          prefixIcon: Icons.person_outline_rounded,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          validator: (v) {
            final required = Validators.required(
              v,
              message: 'Customer name is required',
            );
            return required ?? Validators.maxLength(80)(v);
          },
        ),
        AppFieldRow(
          children: [
            AppTextField(
              label: 'Phone (optional)',
              hint: '98765 43210',
              controller: form.phone,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: Validators.optional(Validators.phone),
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

class BusinessSection extends StatelessWidget {
  const BusinessSection({required this.form, super.key});

  final CustomerFormState form;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: 'GSTIN (optional)',
      hint: '15-character GSTIN',
      helper: 'Add this for business customers who need a GST invoice.',
      controller: form.gstin,
      prefixIcon: Icons.badge_outlined,
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp('[0-9a-zA-Z]')),
        LengthLimitingTextInputFormatter(15),
      ],
      validator: Validators.optional(Validators.gstin),
    );
  }
}

class AddressSection extends StatelessWidget {
  const AddressSection({required this.form, super.key});

  final CustomerFormState form;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        AppTextField(
          label: 'Address line 1',
          controller: form.addressLine1,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          validator: Validators.maxLength(120),
        ),
        AppTextField(
          label: 'Address line 2',
          controller: form.addressLine2,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          validator: Validators.maxLength(120),
        ),
        AppFieldRow(
          children: [
            AppTextField(
              label: 'City',
              controller: form.city,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: Validators.maxLength(60),
            ),
            AppDropdown<String>(
              label: 'State',
              value: form.state ?? _noState,
              items: const [_noState, ...IndianStates.all],
              itemLabel: (s) => s == _noState ? 'Not set' : s,
              onChanged: (v) => form.setState(v == _noState ? null : v),
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
          validator: Validators.optional(Validators.pincode),
        ),
      ],
    );
  }
}

class CreditSection extends StatelessWidget {
  const CreditSection({required this.form, super.key});

  final CustomerFormState form;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        AppTextField(
          label: 'Credit limit (optional)',
          helper: 'The most you let this customer owe on credit (Udhaar). Leave empty for no limit.',
          controller: form.creditLimit,
          prefixIcon: Icons.currency_rupee_rounded,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
            LengthLimitingTextInputFormatter(12),
          ],
          validator: amountValidator(required: false, label: 'Credit limit'),
        ),
        AppTextField(
          label: 'Notes (optional)',
          hint: 'Anything worth remembering about this customer',
          controller: form.notes,
          maxLines: 3,
          validator: Validators.maxLength(500),
        ),
      ],
    );
  }
}
