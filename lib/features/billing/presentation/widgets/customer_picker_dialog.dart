import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/widgets/app_empty_state.dart';
import 'package:billforge/core/widgets/app_error_state.dart';
import 'package:billforge/core/widgets/app_search_field.dart';
import 'package:billforge/features/billing/application/billing_providers.dart';
import 'package:billforge/features/customers/domain/customer.dart';
import 'package:billforge/features/customers/presentation/widgets/customer_list_items.dart';

/// Wraps the selection so "walk-in" (null customer) differs from "cancelled".
class CustomerChoice {
  const CustomerChoice(this.customer);

  final Customer? customer;
}

class CustomerPickerDialog extends ConsumerStatefulWidget {
  const CustomerPickerDialog({super.key});

  static Future<CustomerChoice?> show(BuildContext context) =>
      showDialog<CustomerChoice>(
        context: context,
        builder: (_) => const CustomerPickerDialog(),
      );

  @override
  ConsumerState<CustomerPickerDialog> createState() =>
      _CustomerPickerDialogState();
}

class _CustomerPickerDialogState extends ConsumerState<CustomerPickerDialog> {
  final _controller = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customers = ref.watch(customerSearchProvider(_search));

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 600),
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
                      'Select customer',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AppSearchField(
                controller: _controller,
                hint: 'Search by name, phone or GSTIN',
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: const Icon(Icons.directions_walk_rounded),
              title: const Text('Walk-in customer'),
              subtitle: const Text('No customer details on the bill'),
              onTap: () =>
                  Navigator.of(context).pop(const CustomerChoice(null)),
            ),
            const Divider(),
            Flexible(
              child: customers.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (error, stack) => AppErrorState(
                  message: const StorageFailure().message,
                  onRetry: () =>
                      ref.invalidate(customerSearchProvider(_search)),
                ),
                data: (items) => items.isEmpty
                    ? AppEmptyState(
                        icon: Icons.people_outline_rounded,
                        title: 'No customers found',
                        message: _search.isEmpty
                            ? 'Add customers from the Customers section.'
                            : 'Try a different search.',
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, i) {
                          final c = items[i];
                          return ListTile(
                            leading: CustomerAvatar(name: c.name),
                            title: Text(c.name),
                            subtitle: Text(
                              [c.phone, c.locationLabel]
                                  .whereType<String>()
                                  .where((s) => s.isNotEmpty)
                                  .join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () =>
                                Navigator.of(context).pop(CustomerChoice(c)),
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
