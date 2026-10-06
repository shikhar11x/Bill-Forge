import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/utils/app_logger.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/utils/ids.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_card.dart';
import 'package:billforge/core/widgets/app_empty_state.dart';
import 'package:billforge/core/widgets/app_toast.dart';
import 'package:billforge/features/billing/application/bill_controller.dart';
import 'package:billforge/features/billing/application/bill_state.dart';
import 'package:billforge/features/billing/application/billing_providers.dart';
import 'package:billforge/features/billing/domain/discount.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/invoice_composer.dart';
import 'package:billforge/features/billing/presentation/widgets/bill_discount_dialog.dart';
import 'package:billforge/features/billing/presentation/widgets/cart_line_tile.dart';
import 'package:billforge/features/billing/presentation/widgets/customer_picker_dialog.dart';
import 'package:billforge/features/billing/presentation/widgets/line_edit_dialog.dart';
import 'package:billforge/features/billing/presentation/widgets/payment_dialog.dart';
import 'package:billforge/features/billing/presentation/widgets/totals_block.dart';
import 'package:billforge/features/customers/domain/customer.dart';

class CartPanel extends ConsumerStatefulWidget {
  const CartPanel({super.key});

  @override
  ConsumerState<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends ConsumerState<CartPanel> {
  bool _busy = false;

  BillController get _controller => ref.read(billControllerProvider.notifier);

  InvoiceDetail _compose(BillState bill) {
    final now = DateTime.now();
    return composeInvoice(
      id: bill.draftId ?? newId('inv'),
      lines: bill.lines,
      billDiscount: bill.billDiscount,
      customer: bill.customer,
      shop: ref.read(shopTaxContextProvider),
      createdAt: bill.draftCreatedAt ?? now,
      now: now,
    );
  }

  Future<void> _pickCustomer() async {
    final choice = await CustomerPickerDialog.show(context);
    if (choice != null) _controller.setCustomer(choice.customer);
  }

  Future<void> _editBillDiscount() async {
    final bill = ref.read(billControllerProvider);
    final totals = ref.read(billTotalsProvider);
    final result = await showBillDiscountDialog(
      context,
      current: bill.billDiscount,
      maxAmountPaise: totals.discountableBasePaise,
    );
    if (result != null) _controller.setBillDiscount(result);
  }

  void _showFailure(Object error, StackTrace stack, String log) {
    if (error is ConflictFailure) {
      AppToast.show(context, error.message, type: ToastType.error);
      return;
    }
    AppLogger.error(log, error: error, stackTrace: stack);
    AppToast.show(
      context,
      const StorageFailure().message,
      type: ToastType.error,
    );
  }

  Future<void> _saveDraft() async {
    final bill = ref.read(billControllerProvider);
    if (bill.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(invoiceRepositoryProvider).saveDraft(_compose(bill));
      _controller.clear();
      if (!mounted) return;
      AppToast.show(context, 'Draft saved', type: ToastType.success);
      context.go(AppRoutes.billing);
    } catch (error, stack) {
      if (!mounted) return;
      _showFailure(error, stack, 'Saving draft failed');
      setState(() => _busy = false);
    }
  }

  Future<void> _charge() async {
    final bill = ref.read(billControllerProvider);
    if (bill.isEmpty || _busy) return;
    final totals = ref.read(billTotalsProvider);

    final payments = await PaymentDialog.show(
      context,
      totalPaise: totals.grandTotalPaise,
      hasCustomer: bill.customer != null,
    );
    if (payments == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final issued = await ref
          .read(invoiceRepositoryProvider)
          .issue(_compose(bill), payments);
      _controller.clear();
      if (!mounted) return;
      AppToast.show(
        context,
        'Invoice ${issued.invoiceNumber} saved',
        type: ToastType.success,
      );
      context.go(AppRoutes.invoice(issued.id));
    } catch (error, stack) {
      if (!mounted) return;
      _showFailure(error, stack, 'Issuing invoice failed');
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    final bill = ref.watch(billControllerProvider);
    final totals = ref.watch(billTotalsProvider);
    final shop = ref.watch(shopTaxContextProvider);

    final rows = buildTotalsRows(
      discountPaise: totals.discountPaise,
      taxablePaise: totals.taxablePaise,
      cgstPaise: totals.cgstPaise,
      sgstPaise: totals.sgstPaise,
      igstPaise: totals.igstPaise,
      roundOffPaise: totals.roundOffPaise,
    );

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CustomerRow(
            customer: bill.customer,
            taxNote: shop.chargesTax
                ? (shop.isInterState(bill.customer)
                      ? 'Inter-state: IGST (${shop.placeOfSupplyFor(bill.customer)})'
                      : 'Same state: CGST + SGST')
                : null,
            onPick: _pickCustomer,
            onClear: () => _controller.setCustomer(null),
          ),
          const Divider(),
          Expanded(
            child: bill.isEmpty
                ? const AppEmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Cart is empty',
                    message: 'Search or tap a product to add it.',
                  )
                : ListView.separated(
                    itemCount: bill.lines.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, i) {
                      final line = bill.lines[i];
                      return CartLineTile(
                        line: line,
                        amounts: totals.lines[i],
                        onEdit: () async {
                          final updated = await showLineEditDialog(
                            context,
                            line,
                          );
                          if (updated != null) _controller.updateLine(updated);
                        },
                        onIncrement: () =>
                            _controller.increment(line.productId),
                        onDecrement: () =>
                            _controller.decrement(line.productId),
                        onRemove: () => _controller.removeLine(line.productId),
                      );
                    },
                  ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: bill.isEmpty ? null : _editBillDiscount,
                    icon: const Icon(Icons.sell_outlined, size: 18),
                    label: Text(
                      bill.billDiscount.isNone
                          ? 'Add bill discount'
                          : 'Bill discount ${describeDiscount(bill.billDiscount)}',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TotalsBlock(rows: rows, totalPaise: totals.grandTotalPaise),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Save draft',
                        variant: AppButtonVariant.secondary,
                        expanded: true,
                        onPressed: (bill.isEmpty || _busy) ? null : _saveDraft,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        label: 'Charge ${formatPaise(totals.grandTotalPaise)}',
                        expanded: true,
                        isLoading: _busy,
                        onPressed: bill.isEmpty ? null : _charge,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({
    required this.customer,
    required this.taxNote,
    required this.onPick,
    required this.onClear,
  });

  final Customer? customer;
  final String? taxNote;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onPick,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(Icons.person_outline_rounded, color: muted),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer?.name ?? 'Walk-in customer',
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (taxNote != null)
                    Text(
                      taxNote!,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                ],
              ),
            ),
            if (customer != null)
              IconButton(
                tooltip: 'Remove customer',
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: onClear,
              )
            else
              const Text('Change'),
          ],
        ),
      ),
    );
  }
}
