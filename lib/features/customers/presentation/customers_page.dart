import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/responsive/breakpoints.dart';
import 'package:billforge/core/responsive/responsive_builder.dart';
import 'package:billforge/core/utils/app_logger.dart';
import 'package:billforge/core/utils/async_value_x.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_data_table.dart';
import 'package:billforge/core/widgets/app_dialog.dart';
import 'package:billforge/core/widgets/app_empty_state.dart';
import 'package:billforge/core/widgets/app_error_state.dart';
import 'package:billforge/core/widgets/app_search_field.dart';
import 'package:billforge/core/widgets/app_skeleton.dart';
import 'package:billforge/core/widgets/app_toast.dart';
import 'package:billforge/features/customers/application/customer_providers.dart';
import 'package:billforge/features/customers/domain/customer.dart';
import 'package:billforge/features/customers/presentation/widgets/customer_list_items.dart';

class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    // The query survives navigation; restore the search text with it.
    _search.text = ref.read(customerQueryProvider).search;
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients || _scroll.position.extentAfter > 400) return;
    final items = ref.read(customersProvider).dataOrNull;
    final limit = ref.read(customerQueryProvider).limit;
    // A full page means there may be more; a short page means we're done.
    if (items != null && items.length >= limit) {
      ref.read(customerQueryProvider.notifier).loadMore();
    }
  }

  void _add() => context.push(AppRoutes.customerNew);

  void _edit(Customer customer) =>
      context.push(AppRoutes.customerEdit(customer.id));

  Future<void> _toggleArchive(Customer customer) async {
    final archive = !customer.isArchived;
    if (archive) {
      final confirmed = await AppDialog.confirm(
        context,
        title: 'Archive "${customer.name}"?',
        message: 'They will be hidden from customer lists and billing. You can restore them from the Archived filter.',
        confirmLabel: 'Archive',
        destructive: true,
      );
      if (!confirmed) return;
    }
    try {
      await ref
          .read(customerRepositoryProvider)
          .setArchived(customer.id, archived: archive);
      if (!mounted) return;
      AppToast.show(
        context,
        archive ? 'Customer archived' : 'Customer restored',
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

  void _resetAll() {
    _search.clear();
    ref.read(customerQueryProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(customersProvider, (previous, next) {
      if (next.hasError) {
        AppLogger.error(
          'Could not load customers',
          error: next.error,
          stackTrace: next.stackTrace,
        );
      }
    });

    final query = ref.watch(customerQueryProvider);
    final notifier = ref.read(customerQueryProvider.notifier);

    return ResponsiveBuilder(
      builder: (context, size) {
        final wide = !size.isMobile;

        final archivedChip = FilterChip(
          label: const Text('Archived'),
          selected: query.showArchived,
          onSelected: notifier.setShowArchived,
        );

        final toolbar = wide
            ? Row(
                children: [
                  Expanded(
                    child: AppSearchField(
                      controller: _search,
                      hint: 'Search by name, phone or GSTIN',
                      onChanged: notifier.setSearch,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  archivedChip,
                  const SizedBox(width: AppSpacing.md),
                  AppButton(
                    label: 'Add customer',
                    icon: Icons.add_rounded,
                    onPressed: _add,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSearchField(
                    controller: _search,
                    hint: 'Search customers',
                    onChanged: notifier.setSearch,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      archivedChip,
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppButton(
                          label: 'Add customer',
                          icon: Icons.add_rounded,
                          expanded: true,
                          onPressed: _add,
                        ),
                      ),
                    ],
                  ),
                ],
              );

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.contentMaxWidth,
            ),
            child: Padding(
              padding: EdgeInsets.all(wide ? AppSpacing.xxl : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  toolbar,
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(child: _content(size)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _content(ScreenSize size) {
    final async = ref.watch(customersProvider);
    final query = ref.watch(customerQueryProvider);
    final items = async.dataOrNull;

    if (items == null) {
      if (async.hasError) {
        return AppErrorState(
          message: const StorageFailure().message,
          onRetry: () => ref.invalidate(customersProvider),
        );
      }
      return const AppListSkeleton();
    }

    if (items.isEmpty) {
      final searching = query.search.trim().isNotEmpty;
      if (query.showArchived && !searching) {
        return const AppEmptyState(
          icon: Icons.archive_outlined,
          title: 'No archived customers',
          message: 'Customers you archive will appear here.',
        );
      }
      if (searching || query.showArchived) {
        return AppEmptyState(
          icon: Icons.search_off_rounded,
          title: 'No customers found',
          message: 'Try a different search.',
          action: AppButton(
            label: 'Clear search',
            variant: AppButtonVariant.secondary,
            onPressed: _resetAll,
          ),
        );
      }
      return AppEmptyState(
        icon: Icons.people_outline_rounded,
        title: 'Add your first customer',
        message: 'Save customers to bill them quickly and track credit later.',
        action: AppButton(
          label: 'Add customer',
          icon: Icons.add_rounded,
          onPressed: _add,
        ),
      );
    }

    final loadingMore = async.isLoading;

    if (size.isMobile) {
      return ListView.separated(
        controller: _scroll,
        itemCount: items.length + (loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) {
          if (i >= items.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final customer = items[i];
          return CustomerCard(
            customer: customer,
            onTap: () => _edit(customer),
            onToggleArchive: () => _toggleArchive(customer),
          );
        },
      );
    }

    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return AppDataTable<Customer>(
      controller: _scroll,
      rows: items,
      showLoadingRow: loadingMore,
      onRowTap: _edit,
      columns: [
        AppColumn<Customer>(
          label: 'Customer',
          flex: 4,
          cell: (context, c) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomerAvatar(name: c.name, radius: 16),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (c.gstin != null)
                      Text(
                        c.gstin!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppColumn<Customer>(
          label: 'Phone',
          flex: 2,
          cell: (context, c) => Text(c.phone ?? '—'),
        ),
        AppColumn<Customer>(
          label: 'Location',
          flex: 3,
          cell: (context, c) => Text(
            c.locationLabel.isEmpty ? '—' : c.locationLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppColumn<Customer>(
          label: 'Credit limit',
          flex: 2,
          alignment: Alignment.centerRight,
          cell: (context, c) => Text(
            c.creditLimitPaise == null
                ? 'No limit'
                : formatPaise(c.creditLimitPaise!, showDecimals: false),
          ),
        ),
      ],
      trailing: (context, c) => CustomerMenu(
        customer: c,
        onEdit: () => _edit(c),
        onToggleArchive: () => _toggleArchive(c),
      ),
    );
  }
}
