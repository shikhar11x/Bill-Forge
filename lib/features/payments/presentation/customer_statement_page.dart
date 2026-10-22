import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/theme/app_colors.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/utils/app_logger.dart';
import 'package:billforge/core/utils/date_format.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_card.dart';
import 'package:billforge/core/widgets/app_empty_state.dart';
import 'package:billforge/core/widgets/app_error_state.dart';
import 'package:billforge/features/billing/application/invoice_pdf_providers.dart';
import 'package:billforge/features/customers/application/customer_providers.dart';
import 'package:billforge/features/customers/domain/customer.dart';
import 'package:billforge/features/payments/application/payment_providers.dart';
import 'package:billforge/features/payments/data/pdf/statement_pdf_builder.dart';
import 'package:billforge/features/payments/domain/customer_ledger.dart';
import 'package:billforge/features/payments/domain/payment_messages.dart';
import 'package:billforge/features/payments/domain/statement.dart';
import 'package:billforge/features/payments/presentation/widgets/customer_message_dialog.dart';
import 'package:billforge/features/shop/application/shop_providers.dart';

class CustomerStatementPage extends ConsumerStatefulWidget {
  const CustomerStatementPage({required this.customerId, super.key});

  final String customerId;

  @override
  ConsumerState<CustomerStatementPage> createState() =>
      _CustomerStatementPageState();
}

class _CustomerStatementPageState extends ConsumerState<CustomerStatementPage> {
  StatementPeriod _period = StatementPeriod.all;

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.customerAccount(widget.customerId));
    }
  }

  Statement _statement(CustomerLedger ledger) {
    final (from, to) = _period.range(DateTime.now());
    return buildStatement(ledger: ledger, from: from, to: to);
  }

  Future<void> _share(Customer customer, Statement statement) async {
    final shop = shopOrNull(ref.read(shopProfileProvider));
    if (shop == null) return;
    final safeName = customer.name.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-');
    await CustomerMessageDialog.show(
      context,
      title: 'Share statement',
      phone: customer.phone,
      message: buildStatementMessage(
        shop: shop,
        customerName: customer.name,
        statement: statement,
      ),
      pdfFileName: 'Statement-$safeName.pdf',
      buildPdf: () async {
        final fonts = await ref.read(pdfFontsProvider.future);
        return buildStatementPdf(
          shop: shop,
          customer: customer,
          statement: statement,
          fonts: fonts,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerByIdProvider(widget.customerId));
    final ledgerAsync = ref.watch(customerLedgerProvider(widget.customerId));

    if (customerAsync.hasError || ledgerAsync.hasError) {
      AppLogger.error(
        'Could not load statement',
        error: customerAsync.error ?? ledgerAsync.error,
        stackTrace: customerAsync.stackTrace ?? ledgerAsync.stackTrace,
      );
      return AppErrorState(
        message: const StorageFailure().message,
        onRetry: () {
          ref.invalidate(customerByIdProvider(widget.customerId));
          ref.invalidate(customerLedgerProvider(widget.customerId));
        },
      );
    }

    final customer = customerAsync.value;
    final ledger = ledgerAsync.value;
    if (!customerAsync.hasValue || !ledgerAsync.hasValue) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (customer == null || ledger == null) {
      return AppEmptyState(
        icon: Icons.search_off_rounded,
        title: 'Customer not found',
        action: AppButton(
          label: 'Back to customers',
          variant: AppButtonVariant.secondary,
          onPressed: () => context.go(AppRoutes.customers),
        ),
      );
    }

    final statement = _statement(ledger);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.lg,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: _back,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Statement · ${customer.name}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppButton(
                    label: 'Share',
                    icon: Icons.share_outlined,
                    onPressed: () => _share(customer, statement),
                  ),
                ],
              ),
              SegmentedButton<StatementPeriod>(
                showSelectedIcon: false,
                segments: [
                  for (final p in StatementPeriod.values)
                    ButtonSegment(value: p, label: Text(p.label)),
                ],
                selected: {_period},
                onSelectionChanged: (s) => setState(() => _period = s.first),
              ),
              AppCard(
                child: Column(
                  children: [
                    _SummaryRow(
                      'Opening balance',
                      formatPaise(statement.openingPaise),
                    ),
                    _SummaryRow('Billed', formatPaise(statement.billedPaise)),
                    _SummaryRow(
                      'Received',
                      formatPaise(statement.receivedPaise),
                    ),
                    const Divider(),
                    _SummaryRow(
                      'Closing balance',
                      formatPaise(statement.closingPaise),
                      bold: true,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: statement.entries.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No transactions in this period',
                        message: 'Try a longer period.',
                      )
                    : AppCard(
                        padding: EdgeInsets.zero,
                        child: ListView.separated(
                          itemCount: statement.entries.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (context, i) {
                            final e = statement.entries[i];
                            final isDebit = e.debitPaise > 0;
                            return ListTile(
                              title: Text(e.particulars),
                              subtitle: Text(
                                formatDate(e.date),
                                style: TextStyle(color: muted),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    isDebit
                                        ? formatPaise(e.debitPaise)
                                        : '-${formatPaise(e.creditPaise)}',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: isDebit ? null : AppColors.success,
                                    ),
                                  ),
                                  Text(
                                    'Balance ${formatPaise(e.balancePaise)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: muted,
                                    ),
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
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = bold
        ? theme.textTheme.titleMedium
        : theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(
            value,
            style: bold
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  )
                : theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
