import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/utils/date_format.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/utils/quantity.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_card.dart';
import 'package:billforge/core/widgets/app_empty_state.dart';
import 'package:billforge/core/widgets/app_error_state.dart';
import 'package:billforge/core/widgets/page_container.dart';
import 'package:billforge/features/inventory/application/inventory_providers.dart';
import 'package:billforge/features/inventory/domain/purchase.dart';

class PurchaseDetailPage extends ConsumerWidget {
  const PurchaseDetailPage({required this.purchaseId, super.key});

  final String purchaseId;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.inventory);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(purchaseDetailProvider(purchaseId))
        .when(
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (error, stack) => AppErrorState(
            message: const StorageFailure().message,
            onRetry: () => ref.invalidate(purchaseDetailProvider(purchaseId)),
          ),
          data: (detail) {
            if (detail == null) {
              return AppEmptyState(
                icon: Icons.search_off_rounded,
                title: 'Purchase not found',
                action: AppButton(
                  label: 'Back to inventory',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.go(AppRoutes.inventory),
                ),
              );
            }
            return _View(detail: detail, onBack: () => _back(context));
          },
        );
  }
}

class _View extends StatelessWidget {
  const _View({required this.detail, required this.onBack});

  final PurchaseDetail detail;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final purchase = detail.purchase;

    return PageContainer(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.xl,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: onBack,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Purchase · ${formatDate(purchase.purchasedAt)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xs,
                children: [
                  Text(
                    purchase.supplierName ?? 'No supplier',
                    style: theme.textTheme.titleMedium,
                  ),
                  if (purchase.billNumber != null)
                    Text('Bill ${purchase.billNumber}'),
                  if (purchase.note != null)
                    Text(
                      purchase.note!,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  Text(
                    'Saved ${formatDateTime(purchase.createdAt)}. To correct a mistake, use Adjust stock.',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < detail.items.length; i++) ...[
                    if (i > 0) const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  detail.items[i].productName,
                                  style: theme.textTheme.titleSmall,
                                ),
                                Text(
                                  '${formatMilli(detail.items[i].qtyMilli)} ${detail.items[i].unit.symbol} × ${formatPaise(detail.items[i].unitCostPaise)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatPaise(detail.items[i].totalPaise),
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Total', style: theme.textTheme.titleMedium),
                  ),
                  Text(
                    formatPaise(purchase.totalPaise),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
