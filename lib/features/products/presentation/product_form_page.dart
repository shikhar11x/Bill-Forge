import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/utils/app_logger.dart';
import 'package:billforge/core/utils/ids.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_card.dart';
import 'package:billforge/core/widgets/app_empty_state.dart';
import 'package:billforge/core/widgets/app_error_state.dart';
import 'package:billforge/core/widgets/app_toast.dart';
import 'package:billforge/core/widgets/page_container.dart';
import 'package:billforge/features/products/application/product_providers.dart';
import 'package:billforge/features/products/domain/product.dart';
import 'package:billforge/features/products/presentation/product_form_state.dart';
import 'package:billforge/features/products/presentation/widgets/product_form_sections.dart';
import 'package:billforge/features/shop/application/shop_providers.dart';
import 'package:billforge/features/shop/domain/shop_profile.dart';

/// Create (productId == null) or edit a product.
class ProductFormPage extends ConsumerWidget {
  const ProductFormPage({this.productId, super.key});

  final String? productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = shopOrNull(ref.watch(shopProfileProvider));
    if (shop == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final id = productId;
    if (id == null) return _ProductFormView(shop: shop);

    return ref
        .watch(productByIdProvider(id))
        .when(
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (error, stack) => AppErrorState(
            message: const StorageFailure().message,
            onRetry: () => ref.invalidate(productByIdProvider(id)),
          ),
          data: (product) => product == null
              ? AppEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Product not found',
                  message: 'It may have been removed.',
                  action: AppButton(
                    label: 'Back to products',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.go(AppRoutes.products),
                  ),
                )
              : _ProductFormView(shop: shop, product: product),
        );
  }
}

class _ProductFormView extends ConsumerStatefulWidget {
  const _ProductFormView({required this.shop, this.product});

  final ShopProfile shop;
  final Product? product;

  @override
  ConsumerState<_ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends ConsumerState<_ProductFormView> {
  final _formKey = GlobalKey<FormState>();
  late final ProductFormState _form = ProductFormState(
    shop: widget.shop,
    existing: widget.product,
  );
  bool _saving = false;

  bool get _isNew => widget.product == null;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.products);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final existing = widget.product;
      final product = _form.toProduct(
        id: existing?.id ?? newId('prd'),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
        archivedAt: existing?.archivedAt,
      );
      await ref.read(productRepositoryProvider).save(product);
      if (!mounted) return;
      AppToast.show(
        context,
        _isNew ? 'Product added' : 'Product saved',
        type: ToastType.success,
      );
      _close();
    } on ConflictFailure catch (failure) {
      if (!mounted) return;
      AppToast.show(context, failure.message, type: ToastType.error);
      setState(() => _saving = false);
    } catch (error, stack) {
      AppLogger.error('Saving product failed', error: error, stackTrace: stack);
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

    return PageContainer(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Form(
          key: _formKey,
          child: Column(
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
                      _isNew ? 'New product' : 'Edit product',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              _FormSection(
                title: 'Basic details',
                child: BasicSection(form: _form),
              ),
              _FormSection(
                title: 'Identification',
                child: IdentificationSection(form: _form),
              ),
              _FormSection(
                title: 'Pricing',
                child: PricingSection(form: _form),
              ),
              _FormSection(
                title: 'Inventory',
                child: InventorySection(form: _form, isNew: _isNew),
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
                    label: _isNew ? 'Add product' : 'Save changes',
                    isLoading: _saving,
                    onPressed: _save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.child});

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
