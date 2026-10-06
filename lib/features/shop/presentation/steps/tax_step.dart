import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/utils/validators.dart';
import 'package:billforge/core/widgets/app_dropdown.dart';
import 'package:billforge/core/widgets/app_text_field.dart';
import 'package:billforge/features/shop/domain/gst_registration.dart';
import 'package:billforge/features/shop/presentation/shop_form_state.dart';

class TaxStep extends StatelessWidget {
  const TaxStep({required this.form, super.key});

  final ShopFormState form;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: form,
      builder: (context, _) {
        final registration = form.gstRegistration;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.lg,
          children: [
            AppDropdown<GstRegistration>(
              label: 'GST registration',
              value: registration,
              items: GstRegistration.values,
              itemLabel: (r) => r.label,
              onChanged: (v) {
                if (v != null) form.setGstRegistration(v);
              },
            ),
            if (registration.hasGstin)
              AppTextField(
                label: 'GSTIN',
                hint: '15-character GSTIN',
                controller: form.gstin,
                prefixIcon: Icons.badge_outlined,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9a-zA-Z]')),
                  LengthLimitingTextInputFormatter(15),
                ],
                validator: Validators.gstin,
              ),
            if (registration.chargesTax) ...[
              AppTextField(
                label: 'Default GST rate (%)',
                controller: form.defaultGstRate,
                helper: 'Used for new products. You can set a different rate per product later.',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: Validators.integerInRange(0, 40, label: 'GST rate'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Prices include GST'),
                subtitle: const Text(
                  'Your selling prices already contain tax (tax-inclusive).',
                ),
                value: form.pricesIncludeTax,
                onChanged: form.setPricesIncludeTax,
              ),
            ] else
              _Note(
                registration == GstRegistration.composition
                    ? 'Composition dealers issue a Bill of Supply and do not charge GST to customers, so tax fields are turned off.'
                    : 'Unregistered businesses cannot charge GST, so tax fields are turned off. You can change this when you register.',
              ),
          ],
        );
      },
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
