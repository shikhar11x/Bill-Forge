import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/theme/app_colors.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/utils/amount_validator.dart';
import 'package:billforge/core/utils/app_logger.dart';
import 'package:billforge/core/utils/async_value_x.dart';
import 'package:billforge/core/utils/date_format.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/utils/ids.dart';
import 'package:billforge/core/utils/money.dart';
import 'package:billforge/core/utils/quantity.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_card.dart';
import 'package:billforge/core/widgets/app_dropdown.dart';
import 'package:billforge/core/widgets/app_field_row.dart';
import 'package:billforge/core/widgets/app_text_field.dart';
import 'package:billforge/core/widgets/app_toast.dart';
import 'package:billforge/core/widgets/page_container.dart';
import 'package:billforge/features/inventory/application/inventory_providers.dart';
import 'package:billforge/features/inventory/domain/purchase_math.dart';
import 'package:billforge/features/inventory/domain/supplier.dart';
import 'package:billforge/features/inventory/presentation/purchase_form_state.dart';
import 'package:billforge/features/inventory/presentation/widgets/product_search_dialog.dart';
import 'package:billforge/features/products/presentation/product_validators.dart';

const _noSupplier = '__none__';

class PurchaseFormPage extends ConsumerStatefulWidget {
  const PurchaseFormPage({super.key});

  @override
  ConsumerState<PurchaseFormPage> createState() => _PurchaseFormPageState();
}

class _PurchaseFormPageState extends ConsumerState<PurchaseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _form = PurchaseFormState();
  bool _saving = false;
  String? _linesError;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.inventory);
    }
  }

  Future<void> _addProduct() async {
    final product = await ProductSearchDialog.show(context);
    if (product == null || !mounted) return;
    if (!product.trackStock) {
      AppToast.show(
        context,
        '"${product.name}" has stock tracking turned off. Turn it on in Products first.',
        type: ToastType.error,
      );
      return;
    }
    if (!_form.addProduct(product)) {
      AppToast.show(context, '"${product.name}" is already in this purchase.');
    }
    setState(() => _linesError = null);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _form.date,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null) _form.setDate(picked);
  }

  String? _validateQty(PurchaseLineEditor line, String? value) {
    final base = ProductValidators.quantity(
      fractional: () => line.product.unit.fractional,
      label: 'Quantity',
    )(value);
    if (base != null) return base;
    final milli = parseMilli(value!)!;
    if (milli <= 0) return 'Must be more than zero';
    if (milli > kMaxStockQtyMilli) return 'Quantity is too large';
    return null;
  }

  String? _validateCost(String? value) {
    final base = amountValidator(required: true, label: 'Cost')(value);
    if (base != null) return base;
    return parsePaise(value!)! > kMaxUnitCostPaise ? 'Cost is too large' : null;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_form.lines.isEmpty) {
      setState(() => _linesError = 'Add at least one product.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(purchaseRepositoryProvider)
          .receive(
            _form.toDetail(id: newId('pur'), now: DateTime.now()),
            updateCostPrices: _form.updateCostPrices,
          );
      if (!mounted) return;
      AppToast.show(context, 'Purchase saved', type: ToastType.success);
      _close();
    } on ConflictFailure catch (failure) {
      if (!mounted) return;
      AppToast.show(context, failure.message, type: ToastType.error);
      setState(() => _saving = false);
    } catch (error, stack) {
      AppLogger.error(
        'Saving purchase failed',
        error: error,
        stackTrace: stack,
      );
      if (!mounted) return;
      AppToast.show(
        context,
        const StorageFailure().message,
        type: ToastType.error,
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suppliers =
        ref.watch(supplierOptionsProvider).dataOrNull ?? const <Supplier>[];
    final byId = {for (final s in suppliers) s.id: s};
    final selected = byId.containsKey(_form.supplier?.id)
        ? _form.supplier!.id
        : _noSupplier;

    return PageContainer(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Form(
          key: _formKey,
          child: ListenableBuilder(
            listenable: _form,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.xl,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: _saving ? null : _close,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'New purchase',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                _Section(
                  title: 'Details',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.lg,
                    children: [
                      AppDropdown<String>(
                        key: ValueKey('supplier-$selected-${suppliers.length}'),
                        label: 'Supplier (optional)',
                        value: selected,
                        items: [_noSupplier, ...byId.keys],
                        itemLabel: (id) => id == _noSupplier
                            ? 'No supplier'
                            : (byId[id]?.name ?? ''),
                        onChanged: (id) => _form.setSupplier(
                          id == null || id == _noSupplier ? null : byId[id],
                        ),
                      ),
                      AppFieldRow(
                        children: [
                          AppTextField(
                            label: 'Supplier bill number (optional)',
                            controller: _form.billNumber,
                          ),
                          _DateField(date: _form.date, onTap: _pickDate),
                        ],
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: 'Items',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.md,
                    children: [
                      for (final line in _form.lines)
                        _LineCard(
                          key: ObjectKey(line),
                          line: line,
                          validateQty: (v) => _validateQty(line, v),
                          validateCost: _validateCost,
                          onRemove: () => _form.removeLine(line),
                        ),
                      if (_linesError != null)
                        Text(
                          _linesError!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: AppButton(
                          label: 'Add product',
                          icon: Icons.add_rounded,
                          variant: AppButtonVariant.secondary,
                          onPressed: _addProduct,
                        ),
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: 'Notes',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        label: 'Note (optional)',
                        controller: _form.note,
                        maxLines: 2,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Update product purchase prices'),
                        subtitle: const Text(
                          'Use these costs as each product\'s latest purchase price.',
                        ),
                        value: _form.updateCostPrices,
                        onChanged: _form.setUpdateCostPrices,
                      ),
                    ],
                  ),
                ),
                ListenableBuilder(
                  listenable: _form.fieldsListenable,
                  builder: (context, _) => Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        formatPaise(_form.totalPaise),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
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
                      onPressed: _saving ? null : _close,
                    ),
                    AppButton(
                      label: 'Save purchase',
                      isLoading: _saving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Purchase date',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InputDecorator(
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
            ),
            child: Text(formatDate(date)),
          ),
        ),
      ],
    );
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({
    required this.line,
    required this.validateQty,
    required this.validateCost,
    required this.onRemove,
    super.key,
  });

  final PurchaseLineEditor line;
  final String? Function(String?) validateQty;
  final String? Function(String?) validateCost;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = line.product;
    const decimal = TextInputType.numberWithOptions(decimal: true);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(product.name, style: theme.textTheme.titleSmall),
              ),
              IconButton(
                tooltip: 'Remove ${product.name}',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: onRemove,
              ),
            ],
          ),
          AppFieldRow(
            children: [
              AppTextField(
                key: ValueKey('qty-${product.id}'),
                label: 'Quantity (${product.unit.symbol})',
                controller: line.qty,
                keyboardType: decimal,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: validateQty,
              ),
              AppTextField(
                key: ValueKey('cost-${product.id}'),
                label: 'Cost per ${product.unit.symbol}',
                controller: line.cost,
                prefixIcon: Icons.currency_rupee_rounded,
                keyboardType: decimal,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                  LengthLimitingTextInputFormatter(12),
                ],
                validator: validateCost,
              ),
            ],
          ),
          ListenableBuilder(
            listenable: Listenable.merge([line.qty, line.cost]),
            builder: (context, _) {
              final total = line.totalPaise;
              return Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Line total: ${total == null ? '—' : formatPaise(total)}',
                  style: theme.textTheme.titleSmall,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
