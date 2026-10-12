import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/app/theme/app_colors.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/utils/app_logger.dart';
import 'package:billforge/core/utils/ids.dart';
import 'package:billforge/core/utils/phone.dart';
import 'package:billforge/core/utils/validators.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_field_row.dart';
import 'package:billforge/core/widgets/app_text_field.dart';
import 'package:billforge/features/inventory/application/inventory_providers.dart';
import 'package:billforge/features/inventory/domain/supplier.dart';

/// Add (supplier == null) or edit a supplier. Resolves to true when saved.
class SupplierDialog extends ConsumerStatefulWidget {
  const SupplierDialog({this.supplier, super.key});

  final Supplier? supplier;

  static Future<bool?> show(BuildContext context, {Supplier? supplier}) =>
      showDialog<bool>(
        context: context,
        builder: (_) => SupplierDialog(supplier: supplier),
      );

  @override
  ConsumerState<SupplierDialog> createState() => _SupplierDialogState();
}

class _SupplierDialogState extends ConsumerState<SupplierDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.supplier?.name);
  late final _phone = TextEditingController(text: widget.supplier?.phone);
  late final _email = TextEditingController(text: widget.supplier?.email);
  late final _gstin = TextEditingController(text: widget.supplier?.gstin);
  late final _city = TextEditingController(text: widget.supplier?.city);
  late final _notes = TextEditingController(text: widget.supplier?.notes);
  bool _saving = false;
  String? _problem;

  bool get _isNew => widget.supplier == null;

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _gstin, _city, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _optional(TextEditingController c) {
    final text = c.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _submit() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _problem = null;
    });
    try {
      final now = DateTime.now();
      final existing = widget.supplier;
      final rawPhone = _optional(_phone);
      await ref.read(supplierRepositoryProvider).save(
            Supplier(
              id: existing?.id ?? newId('sup'),
              name: _name.text.trim(),
              phone: rawPhone == null ? null : normalizeIndianPhone(rawPhone),
              email: _optional(_email)?.toLowerCase(),
              gstin: _optional(_gstin)?.toUpperCase(),
              city: _optional(_city),
              notes: _optional(_notes),
              archivedAt: existing?.archivedAt,
              createdAt: existing?.createdAt ?? now,
              updatedAt: now,
            ),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ConflictFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _problem = failure.message;
      });
    } catch (error, stack) {
      AppLogger.error('Saving supplier failed', error: error, stackTrace: stack);
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

    return AlertDialog(
      title: Text(_isNew ? 'New supplier' : 'Edit supplier'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.lg,
              children: [
                AppTextField(
                  label: 'Supplier name',
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) {
                    final required =
                        Validators.required(v, message: 'Name is required');
                    return required ?? Validators.maxLength(80)(v);
                  },
                ),
                AppFieldRow(
                  children: [
                    AppTextField(
                      label: 'Phone (optional)',
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      validator: Validators.optional(Validators.phone),
                    ),
                    AppTextField(
                      label: 'Email (optional)',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.optional(Validators.email),
                    ),
                  ],
                ),
                AppFieldRow(
                  children: [
                    AppTextField(
                      label: 'GSTIN (optional)',
                      controller: _gstin,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[0-9a-zA-Z]')),
                        LengthLimitingTextInputFormatter(15),
                      ],
                      validator: Validators.optional(Validators.gstin),
                    ),
                    AppTextField(
                      label: 'City (optional)',
                      controller: _city,
                      textCapitalization: TextCapitalization.words,
                      validator: Validators.maxLength(60),
                    ),
                  ],
                ),
                AppTextField(
                  label: 'Notes (optional)',
                  controller: _notes,
                  maxLines: 2,
                  validator: Validators.maxLength(300),
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
          label: _isNew ? 'Add supplier' : 'Save changes',
          isLoading: _saving,
          onPressed: _submit,
        ),
      ],
    );
  }
}