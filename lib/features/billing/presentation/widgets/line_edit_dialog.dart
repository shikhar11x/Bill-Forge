import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/utils/amount_validator.dart';
import 'package:billforge/core/utils/money.dart';
import 'package:billforge/core/utils/quantity.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_field_row.dart';
import 'package:billforge/core/widgets/app_text_field.dart';
import 'package:billforge/features/billing/domain/bill_calculator.dart';
import 'package:billforge/features/billing/domain/cart_line.dart';
import 'package:billforge/features/billing/domain/discount.dart';
import 'package:billforge/features/billing/presentation/widgets/discount_editor.dart';
import 'package:billforge/features/products/presentation/product_validators.dart';

/// Edits quantity, price and discount of one cart line.
/// Returns the updated line, or null if cancelled.
Future<CartLine?> showLineEditDialog(BuildContext context, CartLine line) {
  return showDialog<CartLine>(
    context: context,
    builder: (_) => _LineEditDialog(line: line),
  );
}

class _LineEditDialog extends StatefulWidget {
  const _LineEditDialog({required this.line});

  final CartLine line;

  @override
  State<_LineEditDialog> createState() => _LineEditDialogState();
}

class _LineEditDialogState extends State<_LineEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _qty = TextEditingController(
    text: formatMilli(widget.line.qtyMilli),
  );
  late final _price = TextEditingController(
    text: paiseToInput(widget.line.unitPricePaise),
  );
  late final _discount = TextEditingController(
    text: discountToInput(widget.line.discount),
  );
  late DiscountType _type = widget.line.discount.type;

  @override
  void dispose() {
    _qty.dispose();
    _price.dispose();
    _discount.dispose();
    super.dispose();
  }

  /// Gross value from the current qty and price fields, if both are valid.
  int? get _gross {
    final qty = parseMilli(_qty.text);
    final price = parsePaise(_price.text);
    if (qty == null || price == null) return null;
    return roundHalfUpDiv(price * qty, 1000);
  }

  String? _validateQty(String? value) {
    final base = ProductValidators.quantity(
      fractional: () => widget.line.unit.fractional,
      label: 'Quantity',
    )(value);
    if (base != null) return base;
    final milli = parseMilli(value!)!;
    if (milli <= 0) return 'Quantity must be more than zero';
    if (milli > kMaxQtyMilli) return 'Quantity is too large';
    return null;
  }

  String? _validatePrice(String? value) {
    final base = amountValidator(required: true, label: 'Price')(value);
    if (base != null) return base;
    return parsePaise(value!)! > kMaxUnitPricePaise
        ? 'Price is too large'
        : null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      widget.line.copyWith(
        qtyMilli: parseMilli(_qty.text)!,
        unitPricePaise: parsePaise(_price.text)!,
        discount: parseDiscount(_type, _discount.text)!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const decimal = TextInputType.numberWithOptions(decimal: true);
    final unitSymbol = widget.line.unit.symbol;

    return AlertDialog(
      title: Text(
        widget.line.name,
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
                AppFieldRow(
                  children: [
                    AppTextField(
                      label: 'Quantity ($unitSymbol)',
                      controller: _qty,
                      keyboardType: decimal,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: _validateQty,
                    ),
                    AppTextField(
                      label: 'Unit price',
                      controller: _price,
                      prefixIcon: Icons.currency_rupee_rounded,
                      keyboardType: decimal,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                        LengthLimitingTextInputFormatter(12),
                      ],
                      validator: _validatePrice,
                    ),
                  ],
                ),
                DiscountEditor(
                  type: _type,
                  controller: _discount,
                  maxAmountPaise: _gross,
                  onTypeChanged: (t) => setState(() => _type = t),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AppButton(label: 'Apply', onPressed: _submit),
      ],
    );
  }
}
