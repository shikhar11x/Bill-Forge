import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/app/theme/app_colors.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/utils/amount_validator.dart';
import 'package:billforge/core/utils/app_logger.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/utils/money.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_dropdown.dart';
import 'package:billforge/core/widgets/app_text_field.dart';
import 'package:billforge/features/billing/application/billing_providers.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/customers/domain/customer.dart';
import 'package:billforge/features/payments/application/payment_providers.dart';
import 'package:billforge/features/payments/domain/payment_allocation.dart';

const _all = '__all__';

/// Collect a payment from a customer. Resolves to true when it was recorded.
class CollectPaymentDialog extends ConsumerStatefulWidget {
  const CollectPaymentDialog({
    required this.customer,
    required this.openInvoices,
    this.initialInvoiceId,
    super.key,
  });

  final Customer customer;
  final List<Invoice> openInvoices;

  /// Preselects one invoice; otherwise the payment goes to the oldest first.
  final String? initialInvoiceId;

  static Future<bool?> show(
    BuildContext context, {
    required Customer customer,
    required List<Invoice> openInvoices,
    String? invoiceId,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (_) => CollectPaymentDialog(
          customer: customer,
          openInvoices: openInvoices,
          initialInvoiceId: invoiceId,
        ),
      );

  @override
  ConsumerState<CollectPaymentDialog> createState() =>
      _CollectPaymentDialogState();
}

class _CollectPaymentDialogState extends ConsumerState<CollectPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _note = TextEditingController();
  late String _applyTo = _validInitial();
  late final _amount = TextEditingController(text: paiseToInput(_due));
  PaymentMethod _method = PaymentMethod.cash;
  bool _saving = false;
  String? _problem;

  Map<String, Invoice> get _byId => {
        for (final i in widget.openInvoices) i.id: i,
      };

  String _validInitial() {
    final id = widget.initialInvoiceId;
    return (id != null && _byId.containsKey(id)) ? id : _all;
  }

  int get _totalDue =>
      widget.openInvoices.fold<int>(0, (sum, i) => sum + i.duePaise);

  int get _due => _applyTo == _all ? _totalDue : (_byId[_applyTo]?.duePaise ?? 0);

  String _label(Invoice i) =>
      '${i.invoiceNumber ?? 'Bill'} · due ${formatPaise(i.duePaise)}';

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    final base = amountValidator(required: true, label: 'Amount')(value);
    if (base != null) return base;
    return validateCollection(amountPaise: parsePaise(value!)!, duePaise: _due);
  }

  Future<void> _submit() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _problem = null;
    });
    try {
      await ref.read(paymentRepositoryProvider).collect(
            customerId: widget.customer.id,
            amountPaise: parsePaise(_amount.text)!,
            method: _method,
            note: _note.text,
            invoiceId: _applyTo == _all ? null : _applyTo,
          );
      ref.invalidate(customerLedgerProvider(widget.customer.id));
      if (_applyTo != _all) ref.invalidate(invoiceDetailProvider(_applyTo));
      if (mounted) Navigator.of(context).pop(true);
    } on ConflictFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _problem = failure.message;
      });
    } catch (error, stack) {
      AppLogger.error('Collecting payment failed', error: error, stackTrace: stack);
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
      title: Text(
        'Collect payment · ${widget.customer.name}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.lg,
              children: [
                Text(
                  'Total due: ${formatPaise(_totalDue)}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
                AppDropdown<String>(
                  label: 'Apply to',
                  value: _applyTo,
                  items: [_all, ...widget.openInvoices.map((i) => i.id)],
                  itemLabel: (id) => id == _all
                      ? 'All open invoices (oldest first)'
                      : _label(_byId[id]!),
                  onChanged: (id) => setState(() {
                    _applyTo = id ?? _all;
                    _amount.text = paiseToInput(_due);
                  }),
                ),
                AppTextField(
                  label: 'Amount received',
                  controller: _amount,
                  prefixIcon: Icons.currency_rupee_rounded,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                    LengthLimitingTextInputFormatter(12),
                  ],
                  validator: _validateAmount,
                ),
                AppDropdown<PaymentMethod>(
                  label: 'Payment method',
                  value: _method,
                  items: PaymentMethod.values,
                  itemLabel: (m) => m.label,
                  onChanged: (m) {
                    if (m != null) setState(() => _method = m);
                  },
                ),
                AppTextField(
                  label: 'Note (optional)',
                  controller: _note,
                  maxLines: 2,
                ),
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
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: 'Record payment',
          isLoading: _saving,
          onPressed: _submit,
        ),
      ],
    );
  }
}