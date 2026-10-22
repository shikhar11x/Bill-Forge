import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:billforge/app/theme/app_colors.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/utils/date_format.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/utils/money.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';
import 'package:billforge/features/payments/domain/credit_check.dart';

class _PaymentRow {
  _PaymentRow(this.method, String amount)
    : controller = TextEditingController(text: amount);

  PaymentMethod method;
  final TextEditingController controller;
}

/// What the cashier agreed: the payments taken now and, if part of the bill
/// stays on credit, when it is due.
class PaymentResult {
  const PaymentResult({required this.entries, this.dueDate});

  final List<PaymentEntry> entries;
  final DateTime? dueDate;
}

/// Collects how the bill is paid. Anything left unpaid becomes credit.
/// Returns the result, or null if cancelled.
class PaymentDialog extends StatefulWidget {
  const PaymentDialog({
    required this.totalPaise,
    required this.hasCustomer,
    this.credit,
    super.key,
  });

  final int totalPaise;
  final bool hasCustomer;

  /// The selected customer's limit and current balance, when there is one.
  final CreditContext? credit;

  static Future<PaymentResult?> show(
    BuildContext context, {
    required int totalPaise,
    required bool hasCustomer,
    CreditContext? credit,
  }) => showDialog<PaymentResult>(
    context: context,
    builder: (_) => PaymentDialog(
      totalPaise: totalPaise,
      hasCustomer: hasCustomer,
      credit: credit,
    ),
  );

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  late final List<_PaymentRow> _rows = [
    if (widget.totalPaise > 0)
      _PaymentRow(PaymentMethod.cash, paiseToInput(widget.totalPaise)),
  ];
  DateTime? _dueDate;

  @override
  void dispose() {
    for (final row in _rows) {
      row.controller.dispose();
    }
    super.dispose();
  }

  DateTime _inDays(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + days);
  }

  ({List<PaymentEntry> entries, bool invalid}) _read() {
    final entries = <PaymentEntry>[];
    var invalid = false;
    for (final row in _rows) {
      final text = row.controller.text.trim();
      if (text.isEmpty) continue;
      final paise = parsePaise(text);
      if (paise == null) {
        invalid = true;
        continue;
      }
      entries.add(PaymentEntry(method: row.method, amountPaise: paise));
    }
    return (entries: entries, invalid: invalid);
  }

  String? _problem(({List<PaymentEntry> entries, bool invalid}) read) {
    if (read.invalid) return 'Enter valid amounts (up to 2 decimals).';
    return validatePayments(
      totalPaise: widget.totalPaise,
      entries: read.entries,
      hasCustomer: widget.hasCustomer,
    );
  }

  void _addRow(int duePaise) {
    setState(() {
      _rows.add(
        _PaymentRow(
          PaymentMethod.upi,
          duePaise > 0 ? paiseToInput(duePaise) : '',
        ),
      );
    });
  }

  void _removeRow(_PaymentRow row) {
    setState(() => _rows.remove(row));
    row.controller.dispose();
  }

  Future<void> _pickDate() async {
    final today = _inDays(0);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? _inDays(7),
      firstDate: today,
      lastDate: _inDays(3650),
    );
    if (picked != null) {
      setState(
        () => _dueDate = DateTime(picked.year, picked.month, picked.day),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final read = _read();
    final problem = _problem(read);
    final paid = read.entries.fold<int>(0, (s, e) => s + e.amountPaise);
    final due = widget.totalPaise - paid;

    final credit = widget.credit;
    final check = (due > 0 && credit != null && credit.limitPaise != null)
        ? checkCredit(
            limitPaise: credit.limitPaise,
            outstandingPaise: credit.outstandingPaise,
            newDuePaise: due,
          )
        : null;
    final creditBlocked = check != null && !check.allowed;

    final presets = [7, 15, 30];
    final customDate =
        _dueDate != null && !presets.any((days) => _dueDate == _inDays(days));

    return AlertDialog(
      title: const Text('Take payment'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Bill total',
                      style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                    ),
                  ),
                  Text(
                    formatPaise(widget.totalPaise),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final row in _rows)
                Padding(
                  key: ObjectKey(row),
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: DropdownButtonFormField<PaymentMethod>(
                          initialValue: row.method,
                          isExpanded: true,
                          decoration: const InputDecoration(),
                          dropdownColor:
                              theme.colorScheme.surfaceContainerHighest,
                          items: [
                            for (final m in PaymentMethod.values)
                              DropdownMenuItem(value: m, child: Text(m.label)),
                          ],
                          onChanged: (m) {
                            if (m != null) setState(() => row.method = m);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextField(
                          controller: row.controller,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                            LengthLimitingTextInputFormatter(12),
                          ],
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            prefixText: '₹ ',
                            hintText: '0.00',
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove payment',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => _removeRow(row),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _addRow(due),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add payment method'),
                ),
              ),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              _SummaryLine(label: 'Paid now', value: formatPaise(paid)),
              if (due > 0)
                _SummaryLine(
                  label: 'On credit',
                  value: formatPaise(due),
                  color: AppColors.warning,
                ),
              if (due > 0 && widget.hasCustomer) ...[
                const SizedBox(height: AppSpacing.md),
                Text('Due date', style: theme.textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    ChoiceChip(
                      label: const Text('No due date'),
                      selected: _dueDate == null,
                      onSelected: (_) => setState(() => _dueDate = null),
                    ),
                    for (final days in presets)
                      ChoiceChip(
                        label: Text('$days days'),
                        selected: _dueDate == _inDays(days),
                        onSelected: (_) =>
                            setState(() => _dueDate = _inDays(days)),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.event_outlined, size: 16),
                      label: Text(
                        customDate ? formatDate(_dueDate!) : 'Pick date',
                      ),
                      onPressed: _pickDate,
                    ),
                  ],
                ),
              ],
              if (check != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  creditBlocked
                      ? creditLimitMessage(check)
                      : 'Credit limit ${formatPaise(check.limitPaise!)}: owes '
                            '${formatPaise(check.outstandingPaise)}, '
                            '${formatPaise(check.afterPaise)} after this bill.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: creditBlocked ? AppColors.danger : muted,
                  ),
                ),
              ],
              if (problem != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    problem,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: 'Save & issue',
          onPressed: (problem == null && !creditBlocked)
              ? () => Navigator.of(context).pop(
                  PaymentResult(
                    entries: read.entries,
                    dueDate: due > 0 ? _dueDate : null,
                  ),
                )
              : null,
        ),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color ?? theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
