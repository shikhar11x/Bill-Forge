import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import 'package:billforge/app/router/app_routes.dart';
import 'package:billforge/app/theme/app_spacing.dart';
import 'package:billforge/core/errors/failure.dart';
import 'package:billforge/core/responsive/responsive_builder.dart';
import 'package:billforge/core/utils/app_logger.dart';
import 'package:billforge/core/utils/async_value_x.dart';
import 'package:billforge/core/widgets/app_bottom_sheet.dart';
import 'package:billforge/core/widgets/app_button.dart';
import 'package:billforge/core/widgets/app_card.dart';
import 'package:billforge/core/widgets/app_empty_state.dart';
import 'package:billforge/core/widgets/app_error_state.dart';
import 'package:billforge/features/billing/application/billing_providers.dart';
import 'package:billforge/features/billing/application/invoice_pdf_providers.dart';
import 'package:billforge/features/billing/data/pdf/invoice_pdf_builder.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/invoice_document.dart';
import 'package:billforge/features/billing/presentation/widgets/invoice_options_panel.dart';
import 'package:billforge/features/shop/application/shop_providers.dart';

class InvoicePreviewPage extends ConsumerWidget {
  const InvoicePreviewPage({required this.invoiceId, super.key});

  final String invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(invoiceDetailProvider(invoiceId)).when(
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (error, stack) => AppErrorState(
            message: const StorageFailure().message,
            onRetry: () => ref.invalidate(invoiceDetailProvider(invoiceId)),
          ),
          data: (detail) {
            if (detail == null || detail.invoice.isDraft) {
              return AppEmptyState(
                icon: Icons.print_disabled_outlined,
                title: 'Only issued invoices can be printed',
                message: 'Issue the bill first, then print or share it.',
                action: AppButton(
                  label: 'Back to billing',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.go(AppRoutes.billing),
                ),
              );
            }
            return _PreviewBody(detail: detail);
          },
        );
  }
}

class _PreviewBody extends ConsumerWidget {
  const _PreviewBody({required this.detail});

  final InvoiceDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = shopOrNull(ref.watch(shopProfileProvider));
    final fontsAsync = ref.watch(pdfFontsProvider);
    final fonts = fontsAsync.dataOrNull;
    final options = ref.watch(invoiceTemplateProvider);
    final theme = Theme.of(context);
    final invoice = detail.invoice;

    if (fontsAsync.hasError && fonts == null) {
      AppLogger.error(
        'Could not load PDF fonts',
        error: fontsAsync.error,
        stackTrace: fontsAsync.stackTrace,
      );
      return AppErrorState(
        message: 'Could not prepare the invoice. Please try again.',
        onRetry: () => ref.invalidate(pdfFontsProvider),
      );
    }
    if (shop == null || fonts == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final document = InvoiceDocument(shop: shop, detail: detail);
    final fileName = '${invoice.invoiceNumber ?? 'invoice'}.pdf';

    final preview = PdfPreview(
      // A new key rebuilds the preview whenever the layout choices change.
      key: ValueKey((options, shop.updatedAt)),
      build: (format) => buildInvoicePdf(
        document: document,
        options: options,
        fonts: fonts,
      ),
      pdfFileName: fileName,
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
      allowPrinting: true,
      allowSharing: true,
      maxPageWidth: 760,
      onError: (context, error) {
        AppLogger.error('PDF preview failed', error: error);
        return AppErrorState(
          message: 'Could not build the PDF for this invoice.',
          onRetry: () => ref.invalidate(pdfFontsProvider),
        );
      },
    );

    return ResponsiveBuilder(
      builder: (context, size) {
        final header = Row(
          children: [
            IconButton(
              tooltip: 'Back to invoice',
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.go(AppRoutes.invoice(invoice.id)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Print · ${invoice.invoiceNumber ?? ''}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (size.isMobile)
              IconButton(
                tooltip: 'Invoice layout',
                icon: const Icon(Icons.tune_rounded),
                onPressed: () => AppBottomSheet.show<void>(
                  context,
                  title: 'Invoice layout',
                  builder: (_) => const InvoiceOptionsPanel(),
                ),
              ),
          ],
        );

        final body = size.isMobile
            ? preview
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: preview),
                  const SizedBox(width: AppSpacing.lg),
                  SizedBox(
                    width: 300,
                    child: AppCard(
                      child: const SingleChildScrollView(
                        child: InvoiceOptionsPanel(),
                      ),
                    ),
                  ),
                ],
              );

        return Padding(
          padding: EdgeInsets.all(size.isMobile ? AppSpacing.lg : AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: AppSpacing.lg),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }
}