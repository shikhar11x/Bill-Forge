import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/utils/async_value_x.dart';
import 'package:billforge/core/utils/validators.dart';
import 'package:billforge/core/widgets/app_dropdown.dart';
import 'package:billforge/core/widgets/app_field_row.dart';
import 'package:billforge/core/widgets/app_text_field.dart';
import 'package:billforge/core/widgets/app_toast.dart';
import 'package:billforge/features/products/application/product_providers.dart';
import 'package:billforge/features/products/domain/category.dart';
import 'package:billforge/features/products/domain/product_unit.dart';
import 'package:billforge/features/products/presentation/product_form_state.dart';
import 'package:billforge/features/products/presentation/product_validators.dart';
import 'package:billforge/features/products/presentation/widgets/category_dialogs.dart';

const _none = '__none__';
const _create = '__create__';

final _moneyFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
  LengthLimitingTextInputFormatter(12),
];

final _quantityFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
  LengthLimitingTextInputFormatter(12),
];

class BasicSection extends ConsumerWidget {
  const BasicSection({required this.form, super.key});

  final ProductFormState form;

  Future<void> _onCategoryChanged(
    BuildContext context,
    WidgetRef ref,
    String? value,
  ) async {
    if (value != _create) {
      form.setCategory(value == _none ? null : value);
      return;
    }
    final name = await promptCategoryName(context);
    if (!context.mounted) return;
    if (name == null) {
      form.bumpCategoryField(); // snap the dropdown back
      return;
    }
    try {
      final category = await ref.read(categoryRepositoryProvider).create(name);
      form.setCategory(category.id);
    } on ConflictFailure catch (failure) {
      form.bumpCategoryField();
      if (context.mounted) {
        AppToast.show(context, failure.message, type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories =
        ref.watch(categoriesProvider).dataOrNull ?? const <Category>[];
    final names = {for (final c in categories) c.id: c.name};

    return ListenableBuilder(
      listenable: form,
      builder: (context, _) {
        final selected = names.containsKey(form.categoryId)
            ? form.categoryId!
            : _none;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.lg,
          children: [
            AppTextField(
              label: 'Product name',
              hint: 'e.g. Parle-G Biscuits 200 g',
              controller: form.name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (v) {
                final required = Validators.required(
                  v,
                  message: 'Product name is required',
                );
                return required ?? Validators.maxLength(120)(v);
              },
            ),
            AppFieldRow(
              children: [
                AppDropdown<String>(
                  key: ValueKey(
                    'category-$selected-${form.categoryRevision}-${categories.length}',
                  ),
                  label: 'Category',
                  value: selected,
                  items: [_none, ...names.keys, _create],
                  itemLabel: (id) => switch (id) {
                    _none => 'No category',
                    _create => '+ New category',
                    _ => names[id] ?? '',
                  },
                  onChanged: (v) => _onCategoryChanged(context, ref, v),
                ),
                AppDropdown<ProductUnit>(
                  label: 'Unit',
                  value: form.unit,
                  items: ProductUnit.values,
                  itemLabel: (u) => '${u.label} (${u.symbol})',
                  onChanged: (v) {
                    if (v != null) form.setUnit(v);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class IdentificationSection extends StatelessWidget {
  const IdentificationSection({required this.form, super.key});

  final ProductFormState form;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        AppFieldRow(
          children: [
            AppTextField(
              label: 'SKU (optional)',
              hint: 'Your own product code',
              controller: form.sku,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              validator: Validators.maxLength(40),
            ),
            AppTextField(
              label: 'Barcode (optional)',
              controller: form.barcode,
              helper: 'Type it, or scan with a USB/Bluetooth scanner into this field.',
              textInputAction: TextInputAction.next,
              validator: Validators.maxLength(40),
            ),
          ],
        ),
        AppTextField(
          label: 'HSN / SAC code (optional)',
          hint: '4, 6 or 8 digits',
          controller: form.hsn,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          validator: ProductValidators.hsn,
        ),
      ],
    );
  }
}

class PricingSection extends StatelessWidget {
  const PricingSection({required this.form, super.key});

  final ProductFormState form;

  @override
  Widget build(BuildContext context) {
    final taxNote = form.showGst
        ? (form.shop.pricesIncludeTax ? ' (incl. GST)' : ' (excl. GST)')
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        AppFieldRow(
          children: [
            AppTextField(
              label: 'Selling price$taxNote',
              controller: form.selling,
              prefixIcon: Icons.currency_rupee_rounded,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: _moneyFormatters,
              textInputAction: TextInputAction.next,
              validator: form.validateSelling,
            ),
            AppTextField(
              label: 'Purchase price (optional)',
              helper: 'Used to calculate profit.',
              controller: form.purchase,
              prefixIcon: Icons.currency_rupee_rounded,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: _moneyFormatters,
              textInputAction: TextInputAction.next,
              validator: ProductValidators.amount(
                required: false,
                label: 'Purchase price',
              ),
            ),
          ],
        ),
        AppFieldRow(
          children: [
            AppTextField(
              label: 'MRP (optional)',
              helper: form.enforceMrpCap
                  ? 'Selling price cannot be higher than MRP.'
                  : null,
              controller: form.mrp,
              prefixIcon: Icons.currency_rupee_rounded,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: _moneyFormatters,
              textInputAction: TextInputAction.next,
              validator: ProductValidators.amount(
                required: false,
                label: 'MRP',
              ),
            ),
            if (form.showGst)
              AppTextField(
                label: 'GST rate (%)',
                controller: form.gstRate,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                validator: Validators.integerInRange(0, 40, label: 'GST rate'),
              ),
          ],
        ),
      ],
    );
  }
}

class InventorySection extends StatelessWidget {
  const InventorySection({required this.form, required this.isNew, super.key});

  final ProductFormState form;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: form,
      builder: (context, _) {
        final symbol = form.unit.symbol;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Track stock'),
              subtitle: const Text(
                'Turn off for services or items you do not count.',
              ),
              value: form.trackStock,
              onChanged: form.setTrackStock,
            ),
            if (form.trackStock) ...[
              const SizedBox(height: AppSpacing.md),
              AppFieldRow(
                children: [
                  AppTextField(
                    label: isNew
                        ? 'Opening stock ($symbol)'
                        : 'Stock quantity ($symbol)',
                    controller: form.stock,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: _quantityFormatters,
                    textInputAction: TextInputAction.next,
                    validator: ProductValidators.quantity(
                      fractional: () => form.unit.fractional,
                      label: 'Stock',
                    ),
                  ),
                  AppTextField(
                    label: 'Low-stock alert at ($symbol)',
                    helper: 'You will see a warning at or below this level.',
                    controller: form.lowStock,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: _quantityFormatters,
                    validator: ProductValidators.quantity(
                      fractional: () => form.unit.fractional,
                      label: 'Alert level',
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
