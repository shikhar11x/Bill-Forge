import 'package:flutter/material.dart';

import 'package:billforge/app/theme/app_spacing.dart';

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    required this.label,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.value,
    this.hint,
    this.validator,
    this.enabled = true,
    super.key,
  });

  final String label;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final T? value;
  final String? hint;
  final String? Function(T?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          menuMaxHeight: 320,
          decoration: InputDecoration(hintText: hint),
          dropdownColor: theme.colorScheme.surfaceContainerHighest,
          items: [
            for (final item in items)
              DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: enabled ? onChanged : null,
          validator: validator,
        ),
      ],
    );
  }
}
