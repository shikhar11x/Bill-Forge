import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/app/theme/app_colors.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/utils/app_logger.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_dropdown.dart';
import 'package:billforge/core/widgets/app_text_field.dart';
import 'package:billforge/features/billing/application/credit_note_providers.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';

/// Cancels an issued invoice. Resolves to true when it was cancelled.
class CancelInvoiceDialog extends ConsumerStatefulWidget {
  const CancelInvoiceDialog({required this.invoice, super.key});

  final Invoice invoice;

  static Future<bool?> show(BuildContext context, Invoice invoice) =>
      showDialog<bool>(
        context: context,
        builder: (_) => CancelInvoiceDialog(invoice: invoice),
      );

  @override
  ConsumerState<CancelInvoiceDialog> createState() =>
      _CancelInvoiceDialogState();
}

class _CancelInvoiceDialogState extends ConsumerState<CancelInvoiceDialog> {
  final _note = TextEditingController();
  bool _restock = true;
  PaymentMethod _method = PaymentMethod.cash;
  bool _saving = false;
  String? _problem;

  /// Cancelling returns everything, so exactly what was paid is refunded.
  int get _refund => widget.invoice.paidPaise;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _problem = null;
    });
    try {
      await ref
          .read(creditNoteRepositoryProvider)
          .cancelInvoice(
            invoiceId: widget.invoice.id,
            note: _note.text,
            restock: _restock,
            refundMethod: _refund > 0 ? _method : null,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ConflictFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _problem = failure.message;
      });
    } catch (error, stack) {
      AppLogger.error(
        'Cancelling invoice failed',
        error: error,
        stackTrace: stack,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _problem = const StorageFailure().message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return AlertDialog(
      title: Text('Cancel ${widget.invoice.invoiceNumber ?? 'invoice'}?'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.lg,
            children: [
              Text(
                'The whole invoice is returned and a credit note is issued. '
                'This cannot be undone.',
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
              AppTextField(
                label: 'Reason (optional)',
                controller: _note,
                maxLines: 2,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Return items to stock'),
                subtitle: const Text('Turn off if the goods cannot be resold.'),
                value: _restock,
                onChanged: (v) => setState(() => _restock = v),
              ),
              if (_refund > 0) ...[
                Text(
                  '${formatPaise(_refund)} will be refunded to the customer.',
                  style: theme.textTheme.titleSmall,
                ),
                AppDropdown<PaymentMethod>(
                  label: 'Refund method',
                  value: _method,
                  items: PaymentMethod.values,
                  itemLabel: (m) => m.label,
                  onChanged: (m) {
                    if (m != null) setState(() => _method = m);
                  },
                ),
              ],
              if (_problem != null)
                Text(
                  _problem!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.danger,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Keep invoice'),
        ),
        AppButton(
          label: 'Cancel invoice',
          variant: AppButtonVariant.danger,
          isLoading: _saving,
          onPressed: _confirm,
        ),
      ],
    );
  }
}
