import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/theme/app_colors.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/utils/app_logger.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/utils/quantity.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_card.dart';
import 'package:billforge/core/widgets/app_dropdown.dart';
import 'package:billforge/core/widgets/app_empty_state.dart';
import 'package:billforge/core/widgets/app_error_state.dart';
import 'package:billforge/core/widgets/app_text_field.dart';
import 'package:billforge/core/widgets/app_toast.dart';
import 'package:billforge/core/widgets/page_container.dart';
import 'package:billforge/features/billing/application/billing_providers.dart';
import 'package:billforge/features/billing/application/credit_note_providers.dart';
import 'package:billforge/features/billing/domain/credit_note.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/billing/domain/return_calculator.dart';

class ReturnItemsPage extends ConsumerWidget {
  const ReturnItemsPage({required this.invoiceId, super.key});

  final String invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(invoiceDetailProvider(invoiceId));
    final returnedAsync = ref.watch(returnedItemsProvider(invoiceId));

    if ((detailAsync.hasError && !detailAsync.hasValue) ||
        (returnedAsync.hasError && !returnedAsync.hasValue)) {
      return AppErrorState(
        message: const StorageFailure().message,
        onRetry: () {
          ref.invalidate(invoiceDetailProvider(invoiceId));
          ref.invalidate(returnedItemsProvider(invoiceId));
        },
      );
    }
    if (!detailAsync.hasValue || !returnedAsync.hasValue) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final detail = detailAsync.requireValue;
    if (detail == null || detail.invoice.status != InvoiceStatus.issued) {
      return AppEmptyState(
        icon: Icons.assignment_return_outlined,
        title: 'This invoice cannot have returns',
        message: 'Only issued invoices can be returned.',
        action: AppButton(
          label: 'Back to billing',
          variant: AppButtonVariant.secondary,
          onPressed: () => context.go(AppRoutes.billing),
        ),
      );
    }
    return _ReturnForm(detail: detail, previous: returnedAsync.requireValue);
  }
}

class _ReturnForm extends ConsumerStatefulWidget {
  const _ReturnForm({required this.detail, required this.previous});

  final InvoiceDetail detail;
  final List<CreditNoteItem> previous;

  @override
  ConsumerState<_ReturnForm> createState() => _ReturnFormState();
}

class _ReturnFormState extends ConsumerState<_ReturnForm> {
  final _formKey = GlobalKey<FormState>();
  final _note = TextEditingController();
  late final List<ReturnableLine> _lines = returnableLines(
    widget.detail.items,
    widget.previous,
  );
  late final Map<String, TextEditingController> _qty = {
    for (final l in _lines)
      if (l.canReturn) l.item.id: TextEditingController(),
  };
  ReturnReason _reason = ReturnReason.notNeeded;
  PaymentMethod _refundMethod = PaymentMethod.cash;
  bool _restock = true;
  bool _saving = false;
  String? _problem;

  Invoice get _invoice => widget.detail.invoice;

  @override
  void dispose() {
    _note.dispose();
    for (final c in _qty.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, int> _selection() => {
    for (final e in _qty.entries) e.key: parseMilli(e.value.text.trim()) ?? 0,
  };

  String? _validateQty(ReturnableLine line, String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final milli = parseMilli(text);
    if (milli == null) return 'Enter a valid number';
    if (!line.item.unit.fractional && milli % 1000 != 0) {
      return 'This unit cannot have decimals';
    }
    if (milli > line.remainingQtyMilli) {
      return 'Only ${formatMilli(line.remainingQtyMilli)} can be returned';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final selection = _selection();
    final outcome = planReturn(
      invoice: _invoice,
      lines: _lines,
      qtyByItemId: selection,
    );
    final plan = outcome.plan;
    if (plan == null) {
      setState(() => _problem = outcome.error);
      return;
    }
    final refund = settleCreditNote(
      totalPaise: plan.totalPaise,
      invoiceDuePaise: _invoice.duePaise,
    ).refundPaise;

    setState(() {
      _saving = true;
      _problem = null;
    });
    try {
      final note = await ref
          .read(creditNoteRepositoryProvider)
          .issue(
            invoiceId: _invoice.id,
            quantities: {
              for (final e in selection.entries)
                if (e.value > 0) e.key: e.value,
            },
            reason: _reason,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            restock: _restock,
            refundMethod: refund > 0 ? _refundMethod : null,
          );
      ref.invalidate(invoiceDetailProvider(_invoice.id));
      ref.invalidate(returnedItemsProvider(_invoice.id));
      if (!mounted) return;
      AppToast.show(
        context,
        'Credit note ${note.creditNoteNumber} issued',
        type: ToastType.success,
      );
      context.go(AppRoutes.creditNote(note.id));
    } on ConflictFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _problem = failure.message;
      });
    } catch (error, stack) {
      AppLogger.error(
        'Issuing credit note failed',
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

  Widget _summary(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final selection = _selection();

    if (!selection.values.any((q) => q > 0)) {
      return Text(
        'Enter the quantity to return for each item.',
        style: theme.textTheme.bodyMedium?.copyWith(color: muted),
      );
    }
    final outcome = planReturn(
      invoice: _invoice,
      lines: _lines,
      qtyByItemId: selection,
    );
    final plan = outcome.plan;
    if (plan == null) {
      return Text(
        outcome.error!,
        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.danger),
      );
    }

    final settlement = settleCreditNote(
      totalPaise: plan.totalPaise,
      invoiceDuePaise: _invoice.duePaise,
    );

    Widget row(String label, String value, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: bold
                  ? theme.textTheme.titleSmall
                  : theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ),
          Text(
            value,
            style: bold
                ? theme.textTheme.titleMedium
                : theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row('Credit note total', formatPaise(plan.totalPaise), bold: true),
        if (settlement.appliedPaise > 0)
          row('Reduces balance due', formatPaise(settlement.appliedPaise)),
        if (settlement.refundPaise > 0) ...[
          row('Refund to customer', formatPaise(settlement.refundPaise)),
          const SizedBox(height: AppSpacing.md),
          AppDropdown<PaymentMethod>(
            label: 'Refund method',
            value: _refundMethod,
            items: PaymentMethod.values,
            itemLabel: (m) => m.label,
            onChanged: (m) {
              if (m != null) setState(() => _refundMethod = m);
            },
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    const decimal = TextInputType.numberWithOptions(decimal: true);

    return PageContainer(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.xl,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back to invoice',
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: _saving
                        ? null
                        : () => context.go(AppRoutes.invoice(_invoice.id)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Return items · ${_invoice.invoiceNumber ?? ''}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              for (final line in _lines)
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.md,
                    children: [
                      Text(line.item.name, style: theme.textTheme.titleSmall),
                      Text(
                        line.canReturn
                            ? 'Sold ${formatMilli(line.item.qtyMilli)} ${line.item.unit.symbol} · can return ${formatMilli(line.remainingQtyMilli)}'
                            : 'Fully returned',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                      if (line.canReturn)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppTextField(
                                label:
                                    'Quantity to return (${line.item.unit.symbol})',
                                controller: _qty[line.item.id]!,
                                keyboardType: decimal,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp('[0-9.]'),
                                  ),
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                validator: (v) => _validateQty(line, v),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Padding(
                              padding: const EdgeInsets.only(top: 28),
                              child: TextButton(
                                onPressed: () => _qty[line.item.id]!.text =
                                    formatMilli(line.remainingQtyMilli),
                                child: const Text('All'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.lg,
                  children: [
                    AppDropdown<ReturnReason>(
                      label: 'Reason',
                      value: _reason,
                      items: [
                        for (final r in ReturnReason.values)
                          if (r != ReturnReason.cancellation) r,
                      ],
                      itemLabel: (r) => r.label,
                      onChanged: (r) {
                        if (r != null) setState(() => _reason = r);
                      },
                    ),
                    AppTextField(
                      label: 'Note (optional)',
                      controller: _note,
                      maxLines: 2,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Return items to stock'),
                      subtitle: const Text(
                        'Turn off for damaged goods that cannot be resold.',
                      ),
                      value: _restock,
                      onChanged: (v) => setState(() => _restock = v),
                    ),
                    const Divider(),
                    ListenableBuilder(
                      listenable: Listenable.merge(_qty.values.toList()),
                      builder: (context, _) => _summary(context),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: AppSpacing.md,
                children: [
                  AppButton(
                    label: 'Cancel',
                    variant: AppButtonVariant.secondary,
                    onPressed: _saving
                        ? null
                        : () => context.go(AppRoutes.invoice(_invoice.id)),
                  ),
                  AppButton(
                    label: 'Issue credit note',
                    isLoading: _saving,
                    onPressed: _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
