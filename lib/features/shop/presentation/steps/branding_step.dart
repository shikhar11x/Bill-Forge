import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/utils/validators.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_field_row.dart';
import 'package:billforge/core/widgets/app_text_field.dart';
import 'package:billforge/core/widgets/app_toast.dart';
import 'package:billforge/features/shop/data/logo_picker.dart';
import 'package:billforge/features/shop/domain/invoice_number.dart';
import 'package:billforge/features/shop/presentation/shop_form_state.dart';

const _brandPresets = <int>[
  0xFF3F6FF0, // blue (default)
  0xFF7C5CFC, // violet
  0xFF0EA5A4, // teal
  0xFF22A06B, // green
  0xFFE5832F, // orange
  0xFFE5484D, // red
  0xFFD6409F, // pink
  0xFF64748B, // slate
];

class BrandingStep extends StatelessWidget {
  const BrandingStep({required this.form, super.key});

  final ShopFormState form;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        Text('Logo', style: theme.textTheme.titleSmall),
        _LogoPicker(form: form),
        Text('Brand colour', style: theme.textTheme.titleSmall),
        _ColourPicker(form: form),
        const Divider(),
        Text('Invoices', style: theme.textTheme.titleSmall),
        AppFieldRow(
          children: [
            AppTextField(
              label: 'Invoice prefix',
              controller: form.invoicePrefix,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9a-zA-Z-]')),
                LengthLimitingTextInputFormatter(8),
              ],
              textInputAction: TextInputAction.next,
              validator: Validators.invoicePrefix,
            ),
            AppTextField(
              label: 'Starting number',
              controller: form.nextInvoiceNumber,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
              validator: Validators.integerInRange(
                1,
                9999999,
                label: 'Starting number',
              ),
            ),
          ],
        ),
        ListenableBuilder(
          listenable: Listenable.merge([
            form.invoicePrefix,
            form.nextInvoiceNumber,
          ]),
          builder: (context, _) {
            final prefix = form.invoicePrefix.text.trim().toUpperCase();
            final number = int.tryParse(form.nextInvoiceNumber.text.trim());
            return Text(
              'Example: ${formatInvoiceNumber(prefix.isEmpty ? 'INV' : prefix, number ?? 1)}',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            );
          },
        ),
        AppTextField(
          label: 'Invoice footer (optional)',
          hint: 'e.g. Thank you for shopping with us!',
          controller: form.invoiceFooter,
          maxLines: 2,
          validator: Validators.maxLength(200),
        ),
        AppTextField(
          label: 'Payment instructions (optional)',
          hint: 'e.g. UPI: shop@upi, Bank: A/c, IFSC',
          controller: form.paymentInstructions,
          maxLines: 3,
          validator: Validators.maxLength(300),
        ),
        Text(
          'Currency: Indian Rupee (₹)',
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
      ],
    );
  }
}

class _LogoPicker extends StatelessWidget {
  const _LogoPicker({required this.form});

  final ShopFormState form;

  Future<void> _pick(BuildContext context) async {
    final result = await LogoPicker.pick();
    if (!context.mounted) return;
    if (result.error != null) {
      AppToast.show(context, result.error!, type: ToastType.error);
    } else if (result.bytes != null) {
      form.setLogo(result.bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: form,
      builder: (context, _) {
        final logo = form.logo;
        return Row(
          children: [
            Container(
              width: 64,
              height: 64,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: scheme.outline),
              ),
              child: logo == null
                  ? Icon(Icons.image_outlined, color: scheme.onSurfaceVariant)
                  : Image.memory(
                      logo,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      semanticLabel: 'Shop logo preview',
                      errorBuilder: (_, _, _) => Icon(
                        Icons.broken_image_outlined,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      AppButton(
                        label: logo == null ? 'Upload logo' : 'Replace logo',
                        variant: AppButtonVariant.secondary,
                        icon: Icons.upload_rounded,
                        onPressed: () => _pick(context),
                      ),
                      if (logo != null)
                        TextButton(
                          onPressed: () => form.setLogo(null),
                          child: const Text('Remove'),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'PNG, JPG or WebP, up to 512 KB.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ColourPicker extends StatelessWidget {
  const _ColourPicker({required this.form});

  final ShopFormState form;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: form,
      builder: (context, _) => Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          for (final value in _brandPresets)
            _Swatch(
              color: Color(value),
              selected: form.primaryColorValue == value,
              onTap: () => form.setPrimaryColor(value),
            ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hex = color.toARGB32().toRadixString(16).substring(2).toUpperCase();
    return Semantics(
      button: true,
      selected: selected,
      label: 'Brand colour #$hex',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: selected
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
              : null,
        ),
      ),
    );
  }
}
