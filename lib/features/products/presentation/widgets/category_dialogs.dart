import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/utils/app_logger.dart';
import 'package:billforge/core/utils/validators.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_dialog.dart';
import 'package:billforge/core/widgets/app_empty_state.dart';
import 'package:billforge/core/widgets/app_error_state.dart';
import 'package:billforge/core/widgets/app_text_field.dart';
import 'package:billforge/core/widgets/app_toast.dart';
import 'package:billforge/features/products/application/product_providers.dart';
import 'package:billforge/features/products/domain/category.dart';

/// Asks for a category name. Returns the trimmed name, or null if cancelled.
Future<String?> promptCategoryName(
  BuildContext context, {
  String? initial,
  String title = 'New category',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _CategoryNameDialog(initial: initial, title: title),
  );
}

class _CategoryNameDialog extends StatefulWidget {
  const _CategoryNameDialog({required this.title, this.initial});

  final String title;
  final String? initial;

  @override
  State<_CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<_CategoryNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: AppTextField(
            label: 'Category name',
            hint: 'e.g. Beverages',
            controller: _controller,
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => _submit(),
            validator: (v) {
              final required = Validators.required(
                v,
                message: 'Name is required',
              );
              return required ?? Validators.maxLength(40)(v);
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AppButton(label: 'Save', onPressed: _submit),
      ],
    );
  }
}

/// Rename / delete / add categories.
class ManageCategoriesDialog extends ConsumerWidget {
  const ManageCategoriesDialog({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => const ManageCategoriesDialog(),
  );

  Future<void> _guard(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on ConflictFailure catch (failure) {
      if (context.mounted) {
        AppToast.show(context, failure.message, type: ToastType.error);
      }
    } catch (error, stack) {
      AppLogger.error(
        'Category action failed',
        error: error,
        stackTrace: stack,
      );
      if (context.mounted) {
        AppToast.show(
          context,
          const StorageFailure().message,
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final name = await promptCategoryName(context);
    if (name == null || !context.mounted) return;
    await _guard(
      context,
      () => ref.read(categoryRepositoryProvider).create(name),
    );
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final name = await promptCategoryName(
      context,
      initial: category.name,
      title: 'Rename category',
    );
    if (name == null || !context.mounted) return;
    await _guard(
      context,
      () => ref.read(categoryRepositoryProvider).rename(category.id, name),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Delete "${category.name}"?',
      message: 'Products in this category will become uncategorised.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await _guard(context, () async {
      await ref.read(categoryRepositoryProvider).delete(category.id);
      ref.read(productQueryProvider.notifier).categoryRemoved(category.id);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesProvider);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Categories',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  AppButton(
                    label: 'New',
                    icon: Icons.add_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _add(context, ref),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),
            Flexible(
              child: categories.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (error, stack) => AppErrorState(
                  message: const StorageFailure().message,
                  onRetry: () => ref.invalidate(categoriesProvider),
                ),
                data: (items) => items.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.label_outline_rounded,
                        title: 'No categories yet',
                        message: 'Create one to group your products.',
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, i) {
                          final category = items[i];
                          return ListTile(
                            title: Text(category.name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Rename',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () =>
                                      _rename(context, ref, category),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                  ),
                                  onPressed: () =>
                                      _delete(context, ref, category),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
