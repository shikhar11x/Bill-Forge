import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/responsive/responsive_builder.dart';
import 'package:billforge/core/utils/app_logger.dart';
import 'package:billforge/core/utils/async_value_x.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_card.dart';
import 'package:billforge/core/widgets/app_data_table.dart';
import 'package:billforge/core/widgets/app_dialog.dart';
import 'package:billforge/core/widgets/app_empty_state.dart';
import 'package:billforge/core/widgets/app_error_state.dart';
import 'package:billforge/core/widgets/app_search_field.dart';
import 'package:billforge/core/widgets/app_skeleton.dart';
import 'package:billforge/core/widgets/app_toast.dart';
import 'package:billforge/features/inventory/application/inventory_providers.dart';
import 'package:billforge/features/inventory/domain/supplier.dart';
import 'package:billforge/features/inventory/presentation/widgets/supplier_dialog.dart';

enum _SupplierAction { edit, toggleArchive }

class SuppliersTab extends ConsumerStatefulWidget {
  const SuppliersTab({super.key});

  @override
  ConsumerState<SuppliersTab> createState() => _SuppliersTabState();
}

class _SuppliersTabState extends ConsumerState<SuppliersTab> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.text = ref.read(supplierQueryProvider).search;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final saved = await SupplierDialog.show(context);
    if (saved == true && mounted) {
      AppToast.show(context, 'Supplier added', type: ToastType.success);
    }
  }

  Future<void> _edit(Supplier supplier) async {
    final saved = await SupplierDialog.show(context, supplier: supplier);
    if (saved == true && mounted) {
      AppToast.show(context, 'Supplier saved', type: ToastType.success);
    }
  }

  Future<void> _toggleArchive(Supplier supplier) async {
    final archive = !supplier.isArchived;
    if (archive) {
      final confirmed = await AppDialog.confirm(
        context,
        title: 'Archive "${supplier.name}"?',
        message:
            'They will no longer appear when recording purchases. Past purchases keep their name. You can restore them from the Archived filter.',
        confirmLabel: 'Archive',
        destructive: true,
      );
      if (!confirmed) return;
    }
    try {
      await ref
          .read(supplierRepositoryProvider)
          .setArchived(supplier.id, archived: archive);
      if (!mounted) return;
      AppToast.show(
        context,
        archive ? 'Supplier archived' : 'Supplier restored',
        type: ToastType.success,
      );
    } catch (error, stack) {
      AppLogger.error('Archive failed', error: error, stackTrace: stack);
      if (!mounted) return;
      AppToast.show(
        context,
        const StorageFailure().message,
        type: ToastType.error,
      );
    }
  }

  Widget _menu(Supplier supplier) => PopupMenuButton<_SupplierAction>(
        tooltip: 'Supplier actions',
        icon: const Icon(Icons.more_vert_rounded),
        onSelected: (a) {
          switch (a) {
            case _SupplierAction.edit:
              _edit(supplier);
            case _SupplierAction.toggleArchive:
              _toggleArchive(supplier);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: _SupplierAction.edit, child: Text('Edit')),
          PopupMenuItem(
            value: _SupplierAction.toggleArchive,
            child: Text(supplier.isArchived ? 'Restore' : 'Archive'),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    ref.listen(suppliersProvider, (previous, next) {
      if (next.hasError) {
        AppLogger.error(
          'Could not load suppliers',
          error: next.error,
          stackTrace: next.stackTrace,
        );
      }
    });

    final query = ref.watch(supplierQueryProvider);
    final notifier = ref.read(supplierQueryProvider.notifier);

    return ResponsiveBuilder(
      builder: (context, size) {
        final search = AppSearchField(
          controller: _search,
          hint: 'Search suppliers',
          onChanged: notifier.setSearch,
        );
        final archived = FilterChip(
          label: const Text('Archived'),
          selected: query.showArchived,
          onSelected: notifier.setShowArchived,
        );
        final add = AppButton(
          label: 'Add supplier',
          icon: Icons.add_rounded,
          expanded: size.isMobile,
          onPressed: _add,
        );
        final toolbar = size.isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  search,
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      archived,
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: add),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: AppSpacing.md),
                  archived,
                  const SizedBox(width: AppSpacing.md),
                  add,
                ],
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            toolbar,
            const SizedBox(height: AppSpacing.lg),
            Expanded(child: _content(size.isMobile)),
          ],
        );
      },
    );
  }

  Widget _content(bool mobile) {
    final async = ref.watch(suppliersProvider);
    final query = ref.watch(supplierQueryProvider);
    final items = async.dataOrNull;

    if (items == null) {
      if (async.hasError) {
        return AppErrorState(
          message: const StorageFailure().message,
          onRetry: () => ref.invalidate(suppliersProvider),
        );
      }
      return const AppListSkeleton();
    }

    if (items.isEmpty) {
      if (query.search.trim().isNotEmpty || query.showArchived) {
        return AppEmptyState(
          icon: query.showArchived && query.search.trim().isEmpty
              ? Icons.archive_outlined
              : Icons.search_off_rounded,
          title: query.showArchived && query.search.trim().isEmpty
              ? 'No archived suppliers'
              : 'No suppliers found',
          message: 'Try a different search or filter.',
        );
      }
      return AppEmptyState(
        icon: Icons.store_outlined,
        title: 'No suppliers yet',
        message: 'Add the businesses you buy stock from.',
        action: AppButton(
          label: 'Add supplier',
          icon: Icons.add_rounded,
          onPressed: _add,
        ),
      );
    }

    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    if (mobile) {
      return ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) {
          final s = items[i];
          final subtitle = [s.phone, s.city]
              .whereType<String>()
              .where((v) => v.isNotEmpty)
              .join(' · ');
          return AppCard(
            onTap: () => _edit(s),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name, style: theme.textTheme.titleSmall),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(color: muted),
                        ),
                    ],
                  ),
                ),
                _menu(s),
              ],
            ),
          );
        },
      );
    }

    return AppDataTable<Supplier>(
      rows: items,
      onRowTap: _edit,
      columns: [
        AppColumn<Supplier>(
          label: 'Supplier',
          flex: 4,
          cell: (context, s) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.name, style: theme.textTheme.titleSmall),
              if (s.gstin != null)
                Text(
                  s.gstin!,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
            ],
          ),
        ),
        AppColumn<Supplier>(
          label: 'Phone',
          flex: 2,
          cell: (context, s) => Text(s.phone ?? '—'),
        ),
        AppColumn<Supplier>(
          label: 'City',
          flex: 2,
          cell: (context, s) => Text(s.city ?? '—'),
        ),
      ],
      trailing: (context, s) => _menu(s),
    );
  }
}