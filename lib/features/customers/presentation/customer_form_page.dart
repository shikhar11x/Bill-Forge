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
import 'package:billforge/features/customers/application/customer_providers.dart';
import 'package:billforge/features/customers/domain/customer.dart';
import 'package:billforge/features/customers/presentation/customer_form_state.dart';
import 'package:billforge/features/customers/presentation/widgets/customer_form_sections.dart';

/// Create (customerId == null) or edit a customer.
class CustomerFormPage extends ConsumerWidget {
  const CustomerFormPage({this.customerId, super.key});

  final String? customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = customerId;
    if (id == null) return const _CustomerFormView();

    return ref
        .watch(customerByIdProvider(id))
        .when(
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (error, stack) => AppErrorState(
            message: const StorageFailure().message,
            onRetry: () => ref.invalidate(customerByIdProvider(id)),
          ),
          data: (customer) => customer == null
              ? AppEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Customer not found',
                  message: 'They may have been removed.',
                  action: AppButton(
                    label: 'Back to customers',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.go(AppRoutes.customers),
                  ),
                )
              : _CustomerFormView(customer: customer),
        );
  }
}

class _CustomerFormView extends ConsumerStatefulWidget {
  const _CustomerFormView({this.customer});

  final Customer? customer;

  @override
  ConsumerState<_CustomerFormView> createState() => _CustomerFormViewState();
}

class _CustomerFormViewState extends ConsumerState<_CustomerFormView> {
  final _formKey = GlobalKey<FormState>();
  late final CustomerFormState _form = CustomerFormState(widget.customer);
  bool _saving = false;

  bool get _isNew => widget.customer == null;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.customers);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final existing = widget.customer;
      final customer = _form.toCustomer(
        id: existing?.id ?? newId('cus'),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
        archivedAt: existing?.archivedAt,
      );
      await ref.read(customerRepositoryProvider).save(customer);
      if (!mounted) return;
      AppToast.show(
        context,
        _isNew ? 'Customer added' : 'Customer saved',
        type: ToastType.success,
      );
      _close();
    } on ConflictFailure catch (failure) {
      if (!mounted) return;
      AppToast.show(context, failure.message, type: ToastType.error);
      setState(() => _saving = false);
    } catch (error, stack) {
      AppLogger.error(
        'Saving customer failed',
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
                      _isNew ? 'New customer' : 'Edit customer',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              _FormSection(
                title: 'Customer details',
                child: ContactSection(form: _form),
              ),
              _FormSection(
                title: 'Business',
                child: BusinessSection(form: _form),
              ),
              _FormSection(
                title: 'Address',
                child: AddressSection(form: _form),
              ),
              _FormSection(
                title: 'Credit & notes',
                child: CreditSection(form: _form),
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
                    label: _isNew ? 'Add customer' : 'Save changes',
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
