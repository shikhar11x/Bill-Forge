import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/features/billing/domain/discount.dart';

/// Returns an error message, or null when [text] is a valid discount.
String? validateDiscount(
  DiscountType type,
  String? text, {
  int? maxAmountPaise,
}) {
  final parsed = parseDiscount(type, text ?? '');
  if (parsed == null) return 'Enter a valid number';
  if (type == DiscountType.percent && parsed.value > 10000) {
    return 'Cannot exceed 100%';
  }
  if (type == DiscountType.amount &&
      maxAmountPaise != null &&
      parsed.value > maxAmountPaise) {
    return 'Cannot exceed ${formatPaise(maxAmountPaise)}';
  }
  return null;
}

/// ₹ / % toggle plus the value field. The parent owns the type and the
/// controller, and reads them with [parseDiscount].
class DiscountEditor extends StatelessWidget {
  const DiscountEditor({
    required this.type,
    required this.controller,
    required this.onTypeChanged,
    this.maxAmountPaise,
    this.onChanged,
    super.key,
  });

  final DiscountType type;
  final TextEditingController controller;
  final ValueChanged<DiscountType> onTypeChanged;
  final int? maxAmountPaise;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPercent = type == DiscountType.percent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Discount (optional)',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SegmentedButton<DiscountType>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: DiscountType.amount, label: Text('₹')),
                ButtonSegment(value: DiscountType.percent, label: Text('%')),
              ],
              selected: {type},
              onSelectionChanged: (s) => onTypeChanged(s.first),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
            LengthLimitingTextInputFormatter(12),
          ],
          onChanged: onChanged == null ? null : (_) => onChanged!(),
          decoration: InputDecoration(
            hintText: isPercent ? '0' : '0.00',
            prefixText: isPercent ? null : '₹ ',
            suffixText: isPercent ? '%' : null,
          ),
          validator: (v) =>
              validateDiscount(type, v, maxAmountPaise: maxAmountPaise),
        ),
      ],
    );
  }
}
