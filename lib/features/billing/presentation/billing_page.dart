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
import 'package:billforge/core/utils/date_format.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_card.dart';
import 'package:billforge/core/widgets/app_data_table.dart';
import 'package:billforge/core/widgets/app_dialog.dart';
import 'package:billforge/core/widgets/app_empty_state.dart';
import 'package:billforge/core/widgets/app_error_state.dart';
import 'package:billforge/core/widgets/app_search_field.dart';
import 'package:billforge/core/widgets/app_skeleton.dart';
import 'package:billforge/core/widgets/app_toast.dart';
import 'package:billforge/features/billing/application/bill_controller.dart';
import 'package:billforge/features/billing/application/billing_providers.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/invoice_query.dart';
import 'package:billforge/features/billing/presentation/widgets/invoice_list_items.dart';

class BillingPage extends ConsumerStatefulWidget {
  const BillingPage({super.key});

  @override
  ConsumerState<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends ConsumerState<BillingPage> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _search.text = ref.read(invoiceQueryProvider).search;
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
    final items = ref.read(invoicesProvider).dataOrNull;
    final limit = ref.read(invoiceQueryProvider).limit;
    if (items != null && items.length >= limit) {
      ref.read(invoiceQueryProvider.notifier).loadMore();
    }
  }

  Future<bool> _confirmDiscardCart({String? exceptDraftId}) async {
    final bill = ref.read(billControllerProvider);
    if (bill.isEmpty ||
        (exceptDraftId != null && bill.draftId == exceptDraftId)) {
      return true;
    }
    return AppDialog.confirm(
      context,
      title: 'Discard the current bill?',
      message: 'The bill in progress has not been saved and will be lost.',
      confirmLabel: 'Discard',
      destructive: true,
    );
  }

  Future<void> _newBill() async {
    if (!await _confirmDiscardCart()) return;
    ref.read(billControllerProvider.notifier).clear();
    if (mounted) context.go(AppRoutes.billingNew);
  }

  Future<void> _open(Invoice invoice) async {
    if (!invoice.isDraft) {
      context.go(AppRoutes.invoice(invoice.id));
      return;
    }
    if (!await _confirmDiscardCart(exceptDraftId: invoice.id)) return;
    try {
      final loaded = await ref
          .read(billControllerProvider.notifier)
          .loadDraft(invoice.id);
      if (!mounted) return;
      if (loaded) {
        context.go(AppRoutes.billingNew);
      } else {
        AppToast.show(
          context,
          'That draft no longer exists.',
          type: ToastType.error,
        );
      }
    } catch (error, stack) {
      AppLogger.error('Loading draft failed', error: error, stackTrace: stack);
      if (!mounted) return;
      AppToast.show(
        context,
        const StorageFailure().message,
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(invoicesProvider, (previous, next) {
      if (next.hasError) {
        AppLogger.error(
          'Could not load invoices',
          error: next.error,
          stackTrace: next.stackTrace,
        );
      }
    });

    final query = ref.watch(invoiceQueryProvider);
    final notifier = ref.read(invoiceQueryProvider.notifier);

    return ResponsiveBuilder(
      builder: (context, size) {
        final wide = !size.isMobile;

        final filter = SegmentedButton<InvoiceStatusFilter>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: InvoiceStatusFilter.all, label: Text('All')),
            ButtonSegment(
              value: InvoiceStatusFilter.drafts,
              label: Text('Drafts'),
            ),
            ButtonSegment(
              value: InvoiceStatusFilter.issued,
              label: Text('Issued'),
            ),
          ],
          selected: {query.status},
          onSelectionChanged: (s) => notifier.setStatus(s.first),
        );

        final newBill = AppButton(
          label: 'New bill',
          icon: Icons.add_rounded,
          expanded: !wide,
          onPressed: _newBill,
        );

        final search = AppSearchField(
          controller: _search,
          hint: 'Search by invoice number or customer',
          onChanged: notifier.setSearch,
        );

        final toolbar = wide
            ? Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: AppSpacing.md),
                  filter,
                  const SizedBox(width: AppSpacing.md),
                  newBill,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  search,
                  const SizedBox(height: AppSpacing.md),
                  filter,
                  const SizedBox(height: AppSpacing.md),
                  newBill,
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
                  const _InProgressBanner(),
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
    final async = ref.watch(invoicesProvider);
    final query = ref.watch(invoiceQueryProvider);
    final items = async.dataOrNull;

    if (items == null) {
      if (async.hasError) {
        return AppErrorState(
          message: const StorageFailure().message,
          onRetry: () => ref.invalidate(invoicesProvider),
        );
      }
      return const AppListSkeleton();
    }

    if (items.isEmpty) {
      final filtered =
          query.search.trim().isNotEmpty ||
          query.status != InvoiceStatusFilter.all;
      if (filtered) {
        return AppEmptyState(
          icon: Icons.search_off_rounded,
          title: 'No invoices found',
          message: 'Try a different search or filter.',
          action: AppButton(
            label: 'Clear search & filter',
            variant: AppButtonVariant.secondary,
            onPressed: () {
              _search.clear();
              ref.read(invoiceQueryProvider.notifier).reset();
            },
          ),
        );
      }
      return AppEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Create your first bill',
        message: 'Invoices you issue and drafts you save will appear here.',
        action: AppButton(
          label: 'New bill',
          icon: Icons.add_rounded,
          onPressed: _newBill,
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
          return InvoiceCard(invoice: items[i], onTap: () => _open(items[i]));
        },
      );
    }

    final theme = Theme.of(context);
    return AppDataTable<Invoice>(
      controller: _scroll,
      rows: items,
      showLoadingRow: loadingMore,
      onRowTap: _open,
      columns: [
        AppColumn<Invoice>(
          label: 'Invoice',
          flex: 2,
          cell: (context, i) =>
              Text(invoiceTitle(i), style: theme.textTheme.titleSmall),
        ),
        AppColumn<Invoice>(
          label: 'Date',
          flex: 3,
          cell: (context, i) => Text(formatDateTime(invoiceDate(i))),
        ),
        AppColumn<Invoice>(
          label: 'Customer',
          flex: 3,
          cell: (context, i) => Text(
            i.customerName ?? 'Walk-in customer',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppColumn<Invoice>(
          label: 'Total',
          flex: 2,
          alignment: Alignment.centerRight,
          cell: (context, i) => Text(formatPaise(i.grandTotalPaise)),
        ),
        AppColumn<Invoice>(
          label: 'Status',
          flex: 2,
          alignment: Alignment.centerRight,
          cell: (context, i) => InvoiceStatusBadge(invoice: i),
        ),
      ],
    );
  }
}

class _InProgressBanner extends ConsumerWidget {
  const _InProgressBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bill = ref.watch(billControllerProvider);
    if (bill.isEmpty) return const SizedBox.shrink();
    final total = ref.watch(billTotalsProvider).grandTotalPaise;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppCard(
        child: Row(
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Bill in progress · ${bill.itemCount} item${bill.itemCount == 1 ? '' : 's'} · ${formatPaise(total)}',
                style: theme.textTheme.titleSmall,
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(billControllerProvider.notifier).clear(),
              child: const Text('Discard'),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppButton(
              label: 'Resume',
              onPressed: () => context.go(AppRoutes.billingNew),
            ),
          ],
        ),
      ),
    );
  }
}
