import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/features/billing/application/invoice_pdf_providers.dart';
import 'package:billforge/features/billing/domain/invoice_template_options.dart';

class InvoiceOptionsPanel extends ConsumerWidget {
  const InvoiceOptionsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final options = ref.watch(invoiceTemplateProvider);
    final notifier = ref.read(invoiceTemplateProvider.notifier);

    Widget toggle(
      String label,
      bool value,
      InvoiceTemplateOptions Function(bool v) apply,
    ) =>
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          value: value,
          onChanged: (v) => notifier.update(apply(v)),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Paper', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<InvoicePaper>(
          showSelectedIcon: false,
          segments: [
            for (final p in InvoicePaper.values)
              ButtonSegment(value: p, label: Text(p.label)),
          ],
          selected: {options.paper},
          onSelectionChanged: (s) =>
              notifier.update(options.copyWith(paper: s.first)),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Show on invoice', style: theme.textTheme.titleSmall),
        toggle('Shop logo', options.showLogo,
            (v) => options.copyWith(showLogo: v)),
        toggle('HSN/SAC codes', options.showHsn,
            (v) => options.copyWith(showHsn: v)),
        toggle('Tax summary', options.showTaxSummary,
            (v) => options.copyWith(showTaxSummary: v)),
        toggle('Amount in words', options.showAmountInWords,
            (v) => options.copyWith(showAmountInWords: v)),
        toggle('Payment details', options.showPaymentInstructions,
            (v) => options.copyWith(showPaymentInstructions: v)),
        toggle('Footer note', options.showFooter,
            (v) => options.copyWith(showFooter: v)),
        toggle('Signature block (A4)', options.showSignature,
            (v) => options.copyWith(showSignature: v)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Choices apply until you close the app. Receipts print through your '
          'printer driver. Shop address, GSTIN, footer and payment details '
          'come from Settings → Shop.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}