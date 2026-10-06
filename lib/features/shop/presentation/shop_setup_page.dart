import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/utils/app_logger.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_toast.dart';
import 'package:billforge/core/widgets/brand_mark.dart';
import 'package:billforge/features/shop/application/shop_providers.dart';
import 'package:billforge/features/shop/domain/shop_profile.dart';
import 'package:billforge/features/shop/presentation/shop_form_state.dart';
import 'package:billforge/features/shop/presentation/steps/address_step.dart';
import 'package:billforge/features/shop/presentation/steps/branding_step.dart';
import 'package:billforge/features/shop/presentation/steps/business_step.dart';
import 'package:billforge/features/shop/presentation/steps/tax_step.dart';

enum SetupMode { create, edit }

class ShopSetupPage extends ConsumerStatefulWidget {
  const ShopSetupPage({required this.mode, super.key});

  final SetupMode mode;

  @override
  ConsumerState<ShopSetupPage> createState() => _ShopSetupPageState();
}

class _ShopSetupPageState extends ConsumerState<ShopSetupPage> {
  static const _titles = ['Business', 'Address', 'Tax', 'Branding & invoices'];
  static const _subtitles = [
    'Tell us about your shop.',
    'Where can customers find you? This appears on invoices.',
    'Set up GST so invoices are correct from day one.',
    'Make invoices look like yours.',
  ];

  final _formKeys = List.generate(
    _titles.length,
    (_) => GlobalKey<FormState>(),
  );

  late final ShopProfile? _existing = _isEdit
      ? shopOrNull(ref.read(shopProfileProvider))
      : null;
  late final ShopFormState _form = ShopFormState(_existing);

  int _step = 0;
  bool _saving = false;

  bool get _isEdit => widget.mode == SetupMode.edit;
  bool get _isLast => _step == _titles.length - 1;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_saving) return;
    if (!(_formKeys[_step].currentState?.validate() ?? false)) return;
    if (!_isLast) {
      setState(() => _step++);
      return;
    }
    await _save();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final profile = _form.toProfile(
        id: _existing?.id ?? 'shop_${now.microsecondsSinceEpoch}',
        createdAt: _existing?.createdAt ?? now,
        updatedAt: now,
      );
      await ref.read(shopRepositoryProvider).save(profile);
      if (!mounted) return;
      if (_isEdit) {
        AppToast.show(context, 'Shop details saved', type: ToastType.success);
        context.go(AppRoutes.settings);
      }
      // Create mode: the shop stream emits and the router moves us on.
    } catch (error, stack) {
      AppLogger.error('Saving shop failed', error: error, stackTrace: stack);
      if (!mounted) return;
      AppToast.show(
        context,
        const StorageFailure().message,
        type: ToastType.error,
      );
      setState(() => _saving = false);
    }
  }

  Widget _buildStep() => switch (_step) {
    0 => BusinessStep(form: _form),
    1 => AddressStep(form: _form),
    2 => TaxStep(form: _form),
    _ => BrandingStep(form: _form),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const BrandMark(),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              _isEdit ? 'Shop profile' : 'Set up your shop',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (_isEdit)
                            IconButton(
                              tooltip: 'Close',
                              icon: const Icon(Icons.close_rounded),
                              onPressed: _saving
                                  ? null
                                  : () => context.go(AppRoutes.settings),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Step ${_step + 1} of ${_titles.length} · ${_titles[_step]}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: LinearProgressIndicator(
                          value: (_step + 1) / _titles.length,
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _subtitles[_step],
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: muted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Form(key: _formKeys[_step], child: _buildStep()),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      if (_step > 0) ...[
                        Expanded(
                          child: AppButton(
                            label: 'Back',
                            variant: AppButtonVariant.secondary,
                            expanded: true,
                            onPressed: _saving
                                ? null
                                : () => setState(() => _step--),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                      ],
                      Expanded(
                        flex: 2,
                        child: AppButton(
                          label: _isLast
                              ? (_isEdit ? 'Save changes' : 'Create shop')
                              : 'Continue',
                          expanded: true,
                          isLoading: _saving,
                          onPressed: _next,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
