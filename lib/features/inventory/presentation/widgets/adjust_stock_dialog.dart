import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/app/theme/app_colors.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/utils/app_logger.dart';
import 'package:billforge/core/utils/quantity.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_dropdown.dart';
import 'package:billforge/core/widgets/app_text_field.dart';
import 'package:billforge/features/inventory/application/inventory_providers.dart';
import 'package:billforge/features/inventory/domain/movement_type.dart';
import 'package:billforge/features/inventory/domain/stock_adjustment.dart';
import 'package:billforge/features/products/domain/product.dart';

class AdjustStockDialog extends ConsumerStatefulWidget {
  const AdjustStockDialog({required this.product, super.key});

  final Product product;

  /// Resolves to true when the stock was changed.
  static Future<bool?> show(BuildContext context, Product product) =>
      showDialog<bool>(
        context: context,
        builder: (_) => AdjustStockDialog(product: product),
      );

  @override
  ConsumerState<AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends ConsumerState<AdjustStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qty = TextEditingController();
  final _note = TextEditingController();
  AdjustMode _mode = AdjustMode.setTo;
  AdjustmentReason _reason = AdjustmentReason.recount;
  bool _saving = false;
  String? _problem;

  Product get _product => widget.product;

  @override
  void dispose() {
    _qty.dispose();
    _note.dispose();
    super.dispose();
  }

  String? _validateQty(String? value) => validateAdjustment(
    mode: _mode,
    currentMilli: _product.stockMilli,
    text: value ?? '',
    fractional: _product.unit.fractional,
  );

  Future<void> _submit() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final adjustment = computeAdjustment(
      mode: _mode,
      currentMilli: _product.stockMilli,
      text: _qty.text,
    );
    if (adjustment == null) return;

    setState(() {
      _saving = true;
      _problem = null;
    });
    try {
      final note = _note.text.trim();
      await ref
          .read(stockRepositoryProvider)
          .adjust(
            productId: _product.id,
            deltaMilli: adjustment.deltaMilli,
            reason: _reason,
            note: note.isEmpty ? null : note,
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
        'Stock adjustment failed',
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
    final symbol = _product.unit.symbol;

    return AlertDialog(
      title: Text(
        'Adjust stock · ${_product.name}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.lg,
              children: [
                Text(
                  'Current stock: ${formatMilli(_product.stockMilli)} $symbol',
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
                SegmentedButton<AdjustMode>(
                  showSelectedIcon: false,
                  segments: [
                    for (final m in AdjustMode.values)
                      ButtonSegment(value: m, label: Text(m.label)),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => setState(() => _mode = s.first),
                ),
                AppTextField(
                  label: _mode == AdjustMode.setTo
                      ? 'Counted quantity ($symbol)'
                      : 'Quantity ($symbol)',
                  controller: _qty,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: _validateQty,
                ),
                ListenableBuilder(
                  listenable: _qty,
                  builder: (context, _) {
                    final valid = _validateQty(_qty.text) == null;
                    final adjustment = computeAdjustment(
                      mode: _mode,
                      currentMilli: _product.stockMilli,
                      text: _qty.text,
                    );
                    if (!valid || adjustment == null) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      'New stock: ${formatMilli(adjustment.newStockMilli)} $symbol',
                      style: theme.textTheme.titleSmall,
                    );
                  },
                ),
                AppDropdown<AdjustmentReason>(
                  label: 'Reason',
                  value: _reason,
                  items: AdjustmentReason.values,
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
          label: 'Save adjustment',
          isLoading: _saving,
          onPressed: _submit,
        ),
      ],
    );
  }
}
