import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:billforge/app/theme/app_colors.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/utils/money.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/features/billing/domain/payment_method.dart';

class _PaymentRow {
  _PaymentRow(this.method, String amount)
    : controller = TextEditingController(text: amount);

  PaymentMethod method;
  final TextEditingController controller;
}

/// Collects how the bill is paid. Anything left unpaid becomes credit.
/// Returns the payments (possibly none), or null if cancelled.
class PaymentDialog extends StatefulWidget {
  const PaymentDialog({
    required this.totalPaise,
    required this.hasCustomer,
    super.key,
  });

  final int totalPaise;
  final bool hasCustomer;

  static Future<List<PaymentEntry>?> show(
    BuildContext context, {
    required int totalPaise,
    required bool hasCustomer,
  }) => showDialog<List<PaymentEntry>>(
    context: context,
    builder: (_) =>
        PaymentDialog(totalPaise: totalPaise, hasCustomer: hasCustomer),
  );

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  late final List<_PaymentRow> _rows = [
    if (widget.totalPaise > 0)
      _PaymentRow(PaymentMethod.cash, paiseToInput(widget.totalPaise)),
  ];

  @override
  void dispose() {
    for (final row in _rows) {
      row.controller.dispose();
    }
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final read = _read();
    final problem = _problem(read);
    final paid = read.entries.fold<int>(0, (s, e) => s + e.amountPaise);
    final due = widget.totalPaise - paid;

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
          onPressed: problem == null
              ? () => Navigator.of(context).pop(read.entries)
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
