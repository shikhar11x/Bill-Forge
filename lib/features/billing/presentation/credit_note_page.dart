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
import 'package:billforge/features/billing/application/credit_note_providers.dart';
import 'package:billforge/features/billing/application/invoice_pdf_providers.dart';
import 'package:billforge/features/billing/data/pdf/credit_note_pdf_builder.dart';
import 'package:billforge/features/billing/domain/credit_note.dart';
import 'package:billforge/features/billing/domain/credit_note_message.dart';
import 'package:billforge/features/billing/presentation/widgets/totals_block.dart';
import 'package:billforge/features/payments/presentation/widgets/customer_message_dialog.dart';
import 'package:billforge/features/shop/application/shop_providers.dart';

class CreditNotePage extends ConsumerWidget {
  const CreditNotePage({required this.creditNoteId, super.key});

  final String creditNoteId;

  Future<void> _share(
    BuildContext context,
    WidgetRef ref,
    CreditNoteDetail detail,
  ) async {
    final shop = shopOrNull(ref.read(shopProfileProvider));
    if (shop == null) return;
    final note = detail.creditNote;
    await CustomerMessageDialog.show(
      context,
      title: 'Share credit note',
      phone: note.customerPhone,
      message: buildCreditNoteMessage(shop: shop, detail: detail),
      pdfFileName: '${note.creditNoteNumber}.pdf',
      buildPdf: () async => buildCreditNotePdf(
        shop: shop,
        detail: detail,
        fonts: await ref.read(pdfFontsProvider.future),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sharing needs the shop, so keep it loaded while this page is open.
    ref.watch(shopProfileProvider);

    return ref
        .watch(creditNoteDetailProvider(creditNoteId))
        .when(
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (error, stack) => AppErrorState(
            message: const StorageFailure().message,
            onRetry: () =>
                ref.invalidate(creditNoteDetailProvider(creditNoteId)),
          ),
          data: (detail) {
            if (detail == null) {
              return AppEmptyState(
                icon: Icons.search_off_rounded,
                title: 'Credit note not found',
                action: AppButton(
                  label: 'Back to billing',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.go(AppRoutes.billing),
                ),
              );
            }
            final theme = Theme.of(context);
            final muted = theme.colorScheme.onSurfaceVariant;
            final note = detail.creditNote;
            final rows = buildTotalsRows(
              discountPaise: 0,
              taxablePaise: note.taxablePaise,
              cgstPaise: note.cgstPaise,
              sgstPaise: note.sgstPaise,
              igstPaise: note.igstPaise,
              roundOffPaise: note.roundOffPaise,
            );

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
                          tooltip: 'Back to invoice',
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () =>
                              context.go(AppRoutes.invoice(note.invoiceId)),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Credit note ${note.creditNoteNumber}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        AppButton(
                          label: 'Share',
                          icon: Icons.share_outlined,
                          onPressed: () => _share(context, ref, detail),
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
                            note.customerName ?? 'Walk-in customer',
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            '${formatDateTime(note.issuedAt)} · Against invoice ${note.invoiceNumber}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                          ),
                          Text(
                            'Reason: ${note.reason.label}${note.note == null ? '' : ' (${note.note})'}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            note.restocked
                                ? 'Items returned to stock'
                                : 'Items not returned to stock',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
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
                            ListTile(
                              title: Text(detail.items[i].name),
                              subtitle: Text(
                                '${formatMilli(detail.items[i].qtyMilli)} ${detail.items[i].unit.symbol} × ${formatPaise(detail.items[i].unitPricePaise)}',
                                style: TextStyle(color: muted),
                              ),
                              trailing: Text(
                                formatPaise(detail.items[i].totalPaise),
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TotalsBlock(rows: rows, totalPaise: note.totalPaise),
                          if (note.appliedPaise > 0 ||
                              note.refundPaise > 0) ...[
                            const SizedBox(height: AppSpacing.lg),
                            const Divider(),
                            const SizedBox(height: AppSpacing.sm),
                            if (note.appliedPaise > 0)
                              _Line(
                                'Adjusted against balance',
                                formatPaise(note.appliedPaise),
                              ),
                            if (note.refundPaise > 0)
                              _Line(
                                'Refunded · ${note.refundMethod?.label ?? 'Cash'}',
                                formatPaise(note.refundPaise),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
