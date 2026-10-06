import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:billforge/app/theme/app_spacing.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.maxLines = 1,
    this.obscureText = false,
    this.prefixIcon,
    this.onSubmitted,
    this.enabled = true,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? helper;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final bool obscureText;
  final IconData? prefixIcon;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          enabled: widget.enabled,
          obscureText: _obscured,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          inputFormatters: widget.inputFormatters,
          onFieldSubmitted: widget.onSubmitted,
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helper,
            helperMaxLines: 2,
            prefixIcon: widget.prefixIcon == null
                ? null
                : Icon(widget.prefixIcon, size: 20),
            suffixIcon: widget.obscureText
                ? IconButton(
                    tooltip: _obscured ? 'Show password' : 'Hide password',
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscured = !_obscured),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
