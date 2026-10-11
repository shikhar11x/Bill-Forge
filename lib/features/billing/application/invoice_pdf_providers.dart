import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/features/billing/data/pdf/pdf_fonts.dart';
import 'package:billforge/features/billing/domain/invoice_template_options.dart';

/// Loaded once and cached for the session.
final pdfFontsProvider = FutureProvider<PdfFonts>((ref) => loadPdfFonts());

/// The user's current layout choices. Kept in memory for the session.
class InvoiceTemplateNotifier extends Notifier<InvoiceTemplateOptions> {
  @override
  InvoiceTemplateOptions build() => const InvoiceTemplateOptions();

  void update(InvoiceTemplateOptions options) => state = options;
}

final invoiceTemplateProvider =
    NotifierProvider<InvoiceTemplateNotifier, InvoiceTemplateOptions>(
  InvoiceTemplateNotifier.new,
);