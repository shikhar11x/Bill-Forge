import 'package:flutter/material.dart';

import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/features/billing/domain/discount.dart';
import 'package:billforge/features/billing/presentation/widgets/discount_editor.dart';

/// Edits the discount on the whole bill. Returns the new discount (possibly
/// none), or null if cancelled.
Future<Discount?> showBillDiscountDialog(
  BuildContext context, {
  required Discount current,
  required int maxAmountPaise,
}) {
  return showDialog<Discount>(
    context: context,
    builder: (_) =>
        _BillDiscountDialog(current: current, maxAmountPaise: maxAmountPaise),
  );
}

class _BillDiscountDialog extends StatefulWidget {
  const _BillDiscountDialog({
    required this.current,
    required this.maxAmountPaise,
  });

  final Discount current;
  final int maxAmountPaise;

  @override
  State<_BillDiscountDialog> createState() => _BillDiscountDialogState();
}

class _BillDiscountDialogState extends State<_BillDiscountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(
    text: discountToInput(widget.current),
  );
  late DiscountType _type = widget.current.type;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(parseDiscount(_type, _controller.text)!);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bill discount'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DiscountEditor(
                type: _type,
                controller: _controller,
                maxAmountPaise: widget.maxAmountPaise,
                onTypeChanged: (t) => setState(() => _type = t),
              ),
              const SizedBox(height: 8),
              Text(
                'Up to ${formatPaise(widget.maxAmountPaise)} on this bill. '
                'It is shared across items before GST.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        AppButton(label: 'Apply', onPressed: _submit),
      ],
    );
  }
}
