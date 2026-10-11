import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:billforge/core/utils/amount_in_words.dart';
import 'package:billforge/core/utils/date_format.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/utils/quantity.dart';
import 'package:billforge/features/billing/data/pdf/pdf_fonts.dart';
import 'package:billforge/features/billing/domain/invoice.dart';
import 'package:billforge/features/billing/domain/invoice_document.dart';
import 'package:billforge/features/billing/domain/invoice_template_options.dart';
import 'package:billforge/features/billing/domain/tax_summary.dart';
import 'package:billforge/features/billing/domain/totals_rows.dart';

/// Builds the PDF bytes for an issued invoice.
Future<Uint8List> buildInvoicePdf({
  required InvoiceDocument document,
  required InvoiceTemplateOptions options,
  required PdfFonts fonts,
}) {
  final invoice = document.invoice;
  final pdf = pw.Document(
    theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
    title: '${document.title} ${invoice.invoiceNumber ?? ''}'.trim(),
    author: document.shop.name,
  );
  final logo = options.showLogo ? _tryLogo(document.shop.logo) : null;

  if (options.paper.isThermal) {
    _addReceipt(pdf, document, options, logo);
  } else {
    _addA4(pdf, document, options, logo);
  }
  return pdf.save();
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

/// The PDF library embeds PNG and JPEG only; anything else is skipped.
pw.MemoryImage? _tryLogo(Uint8List? bytes) {
  if (bytes == null || bytes.length < 4) return null;
  final isPng = bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E;
  final isJpeg = bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
  if (!isPng && !isJpeg) return null;
  try {
    return pw.MemoryImage(bytes);
  } catch (_) {
    return null;
  }
}

pw.Widget _text(
  String value, {
  double size = 9,
  bool bold = false,
  PdfColor? color,
  pw.TextAlign align = pw.TextAlign.left,
}) =>
    pw.Text(
      value,
      textAlign: align,
      style: pw.TextStyle(
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color,
      ),
    );

pw.Widget _kv(
  String label,
  String value, {
  double size = 9,
  bool bold = false,
  PdfColor? color,
}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: _text(label, size: size, bold: bold, color: color),
          ),
          pw.SizedBox(width: 8),
          _text(value, size: size, bold: bold, color: color),
        ],
      ),
    );

List<TotalsRow> _totalsRows(Invoice invoice) => buildTotalsRows(
      discountPaise: invoice.discountPaise,
      taxablePaise: invoice.taxablePaise,
      cgstPaise: invoice.cgstPaise,
      sgstPaise: invoice.sgstPaise,
      igstPaise: invoice.igstPaise,
      roundOffPaise: invoice.roundOffPaise,
    );

String _qty(InvoiceItem item) =>
    '${formatMilli(item.qtyMilli)} ${item.unit.symbol}';

List<String> _contactLines(InvoiceDocument d) => [
      if (d.shop.phone.isNotEmpty) 'Phone: ${d.shop.phone}',
      if (d.shop.email != null) d.shop.email!,
      if (d.shop.gstin != null) 'GSTIN: ${d.shop.gstin}',
    ];

List<pw.Widget> _paymentLines(
  InvoiceDocument d, {
  double size = 9,
}) {
  final invoice = d.invoice;
  return [
    for (final p in d.payments)
      _kv('Paid by ${p.method.label}', formatPaise(p.amountPaise), size: size),
    if (invoice.duePaise > 0)
      _kv(
        'Balance due (credit)',
        formatPaise(invoice.duePaise),
        size: size,
        bold: true,
      ),
  ];
}

// ---------------------------------------------------------------------------
// A4
// ---------------------------------------------------------------------------

void _addA4(
  pw.Document pdf,
  InvoiceDocument d,
  InvoiceTemplateOptions o,
  pw.MemoryImage? logo,
) {
  final accent = PdfColor.fromInt(d.shop.primaryColorValue);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.copyWith(
        marginTop: 32,
        marginBottom: 32,
        marginLeft: 32,
        marginRight: 32,
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: _text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          size: 8,
          color: PdfColors.grey600,
        ),
      ),
      build: (context) => [
        _a4Header(d, logo, accent),
        pw.SizedBox(height: 10),
        pw.Divider(color: accent, thickness: 1.2),
        pw.SizedBox(height: 6),
        _a4Parties(d),
        pw.SizedBox(height: 14),
        _a4Items(d, o),
        if (d.chargesTax && d.invoice.pricesIncludeTax)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: _text(
              'Rates are inclusive of GST.',
              size: 8,
              color: PdfColors.grey700,
            ),
          ),
        pw.SizedBox(height: 14),
        _a4Summary(d, o, accent),
        if (o.showTaxSummary && d.chargesTax && d.invoice.taxPaise > 0) ...[
          pw.SizedBox(height: 14),
          _a4TaxSummary(d),
        ],
        pw.SizedBox(height: 16),
        _a4Notes(d, o),
      ],
    ),
  );
}

pw.Widget _a4Header(InvoiceDocument d, pw.MemoryImage? logo, PdfColor accent) {
  final shop = d.shop;
  final invoice = d.invoice;
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      if (logo != null)
        pw.Container(
          width: 56,
          height: 56,
          margin: const pw.EdgeInsets.only(right: 12),
          child: pw.Image(logo, fit: pw.BoxFit.contain),
        ),
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _text(shop.name, size: 16, bold: true),
            pw.SizedBox(height: 3),
            for (final line in d.sellerAddressLines) _text(line),
            for (final line in _contactLines(d)) _text(line),
          ],
        ),
      ),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _text(d.title.toUpperCase(), size: 16, bold: true, color: accent),
          pw.SizedBox(height: 4),
          _text('No: ${invoice.invoiceNumber ?? '-'}', bold: true),
          _text('Date: ${formatDate(d.date)}'),
          _text('Time: ${formatTime(d.date)}'),
        ],
      ),
    ],
  );
}

pw.Widget _a4Parties(InvoiceDocument d) {
  final invoice = d.invoice;
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _text('BILLED TO', size: 8, color: PdfColors.grey700, bold: true),
            pw.SizedBox(height: 2),
            _text(invoice.customerName ?? 'Walk-in customer', bold: true),
            if (invoice.customerPhone != null) _text(invoice.customerPhone!),
            if (invoice.customerGstin != null)
              _text('GSTIN: ${invoice.customerGstin}'),
          ],
        ),
      ),
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _text(
              'PLACE OF SUPPLY',
              size: 8,
              color: PdfColors.grey700,
              bold: true,
            ),
            pw.SizedBox(height: 2),
            _text(invoice.placeOfSupply, bold: true),
            if (d.chargesTax)
              _text(
                invoice.isInterState
                    ? 'Inter-state supply (IGST)'
                    : 'Intra-state supply (CGST + SGST)',
              ),
          ],
        ),
      ),
    ],
  );
}

class _Col {
  const _Col(this.label, this.width, this.alignment, this.cell);

  final String label;
  final pw.TableColumnWidth width;
  final pw.Alignment alignment;
  final pw.Widget Function(InvoiceItem item, int index) cell;
}

pw.Widget _a4Items(InvoiceDocument d, InvoiceTemplateOptions o) {
  final showTax = d.chargesTax;
  final showDiscount = d.items.any((i) => i.discountPaise > 0);

  pw.Widget plain(String value, {bool bold = false}) =>
      _text(value, bold: bold);

  final columns = <_Col>[
    _Col(
      '#',
      const pw.FixedColumnWidth(22),
      pw.Alignment.center,
      (item, i) => plain('${i + 1}'),
    ),
    _Col(
      'Item',
      const pw.FlexColumnWidth(4),
      pw.Alignment.centerLeft,
      (item, i) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _text(item.name, bold: true),
          if (o.showHsn && item.hsnCode != null)
            _text(
              'HSN/SAC ${item.hsnCode}',
              size: 7.5,
              color: PdfColors.grey700,
            ),
        ],
      ),
    ),
    _Col(
      'Qty',
      const pw.FixedColumnWidth(54),
      pw.Alignment.centerRight,
      (item, i) => plain(_qty(item)),
    ),
    _Col(
      'Rate',
      const pw.FixedColumnWidth(62),
      pw.Alignment.centerRight,
      (item, i) => plain(formatPaise(item.unitPricePaise)),
    ),
    if (showDiscount)
      _Col(
        'Disc.',
        const pw.FixedColumnWidth(54),
        pw.Alignment.centerRight,
        (item, i) => plain(
          item.discountPaise > 0 ? formatPaise(item.discountPaise) : '-',
        ),
      ),
    if (showTax)
      _Col(
        'Taxable',
        const pw.FixedColumnWidth(64),
        pw.Alignment.centerRight,
        (item, i) => plain(formatPaise(item.taxablePaise)),
      ),
    if (showTax)
      _Col(
        'GST',
        const pw.FixedColumnWidth(34),
        pw.Alignment.centerRight,
        (item, i) => plain('${item.gstRatePercent}%'),
      ),
    _Col(
      'Amount',
      const pw.FixedColumnWidth(68),
      pw.Alignment.centerRight,
      (item, i) => plain(formatPaise(item.totalPaise), bold: true),
    ),
  ];

  pw.Widget cellOf(pw.Alignment alignment, pw.Widget child) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: pw.Align(alignment: alignment, child: child),
      );

  return pw.Table(
    columnWidths: {
      for (var i = 0; i < columns.length; i++) i: columns[i].width,
    },
    border: const pw.TableBorder(
      top: pw.BorderSide(color: PdfColors.grey500, width: 0.6),
      bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.6),
      horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
    ),
    children: [
      pw.TableRow(
        repeat: true,
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          for (final c in columns)
            cellOf(c.alignment, _text(c.label, size: 8.5, bold: true)),
        ],
      ),
      for (var i = 0; i < d.items.length; i++)
        pw.TableRow(
          children: [
            for (final c in columns) cellOf(c.alignment, c.cell(d.items[i], i)),
          ],
        ),
    ],
  );
}

pw.Widget _a4Summary(
  InvoiceDocument d,
  InvoiceTemplateOptions o,
  PdfColor accent,
) {
  final invoice = d.invoice;
  final rows = _totalsRows(invoice);

  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (o.showAmountInWords) ...[
              _text(
                'AMOUNT IN WORDS',
                size: 8,
                color: PdfColors.grey700,
                bold: true,
              ),
              pw.SizedBox(height: 2),
              _text(amountInWordsInr(invoice.grandTotalPaise), bold: true),
              pw.SizedBox(height: 10),
            ],
            if (d.payments.isNotEmpty || invoice.duePaise > 0) ...[
              _text('PAYMENT', size: 8, color: PdfColors.grey700, bold: true),
              pw.SizedBox(height: 2),
              pw.SizedBox(
                width: 210,
                child: pw.Column(children: _paymentLines(d)),
              ),
            ],
          ],
        ),
      ),
      pw.SizedBox(width: 24),
      pw.SizedBox(
        width: 220,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            for (final r in rows) _kv(r.label, formatPaise(r.paise)),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.only(top: 6),
              decoration: pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: accent, width: 1)),
              ),
              child: _kv(
                'Total',
                formatPaise(invoice.grandTotalPaise),
                size: 13,
                bold: true,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

pw.Widget _a4TaxSummary(InvoiceDocument d) {
  final rows = buildTaxSummary(d.items);
  final interState = d.invoice.isInterState;

  pw.Widget cell(String value, {bool right = true, bool bold = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: pw.Align(
          alignment:
              right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
          child: _text(value, size: 8.5, bold: bold),
        ),
      );

  final headers = [
    'HSN/SAC',
    'Rate',
    'Taxable value',
    if (interState) 'IGST' else ...['CGST', 'SGST'],
    'Total tax',
  ];

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _text('TAX SUMMARY', size: 8, color: PdfColors.grey700, bold: true),
      pw.SizedBox(height: 4),
      pw.Table(
        border: const pw.TableBorder(
          top: pw.BorderSide(color: PdfColors.grey500, width: 0.6),
          bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.6),
          horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              for (var i = 0; i < headers.length; i++)
                cell(headers[i], right: i > 0, bold: true),
            ],
          ),
          for (final r in rows)
            pw.TableRow(
              children: [
                cell(r.hsnCode.isEmpty ? '-' : r.hsnCode, right: false),
                cell('${r.ratePercent}%'),
                cell(formatPaise(r.taxablePaise)),
                if (interState)
                  cell(formatPaise(r.igstPaise))
                else ...[
                  cell(formatPaise(r.cgstPaise)),
                  cell(formatPaise(r.sgstPaise)),
                ],
                cell(formatPaise(r.taxPaise), bold: true),
              ],
            ),
        ],
      ),
    ],
  );
}

pw.Widget _a4Notes(InvoiceDocument d, InvoiceTemplateOptions o) {
  final shop = d.shop;
  final payment = shop.paymentInstructions;
  final footer = shop.invoiceFooter;

  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (o.showPaymentInstructions && payment != null) ...[
              _text(
                'PAYMENT DETAILS',
                size: 8,
                color: PdfColors.grey700,
                bold: true,
              ),
              pw.SizedBox(height: 2),
              _text(payment),
              pw.SizedBox(height: 8),
            ],
            if (d.declaration != null) ...[
              _text(d.declaration!, size: 8, color: PdfColors.grey700),
              pw.SizedBox(height: 8),
            ],
            if (o.showFooter && footer != null) _text(footer, bold: true),
          ],
        ),
      ),
      if (o.showSignature)
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _text('For ${shop.name}', bold: true),
            pw.SizedBox(height: 38),
            _text('Authorised signatory', size: 8, color: PdfColors.grey700),
          ],
        ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Thermal receipt (80 mm / 58 mm)
// ---------------------------------------------------------------------------

void _addReceipt(
  pw.Document pdf,
  InvoiceDocument d,
  InvoiceTemplateOptions o,
  pw.MemoryImage? logo,
) {
  final narrow = o.paper == InvoicePaper.thermal58;
  final size = narrow ? 7.0 : 8.0;
  final invoice = d.invoice;
  final shop = d.shop;

  pw.Widget center(String value, {double? fontSize, bool bold = false}) =>
      _text(
        value,
        size: fontSize ?? size,
        bold: bold,
        align: pw.TextAlign.center,
      );

  pw.Widget rule() => pw.Divider(
        thickness: 0.6,
        height: 8,
        color: PdfColors.black,
      );

  final format = PdfPageFormat(
    o.paper.widthMm * PdfPageFormat.mm,
    double.infinity,
    marginAll: 3 * PdfPageFormat.mm,
  );

  final rows = _totalsRows(invoice);
  final taxRows = buildTaxSummary(d.items);
  final footer = shop.invoiceFooter;
  final payment = shop.paymentInstructions;

  pdf.addPage(
    pw.Page(
      pageFormat: format,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          if (logo != null)
            pw.Center(
              child: pw.Container(
                width: 36,
                height: 36,
                margin: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
            ),
          center(shop.name, fontSize: size + 3, bold: true),
          for (final line in d.sellerAddressLines) center(line),
          for (final line in _contactLines(d)) center(line),
          rule(),
          center(d.title.toUpperCase(), fontSize: size + 1, bold: true),
          pw.SizedBox(height: 3),
          _kv('No', invoice.invoiceNumber ?? '-', size: size, bold: true),
          _kv('Date', formatDateTime(d.date), size: size),
          if (invoice.customerName != null)
            _kv('Customer', invoice.customerName!, size: size),
          if (invoice.customerGstin != null)
            _kv('GSTIN', invoice.customerGstin!, size: size),
          rule(),
          for (final item in d.items)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _text(item.name, size: size, bold: true),
                  _kv(
                    '${_qty(item)} x ${formatPaise(item.unitPricePaise)}'
                    '${item.gstRatePercent > 0 ? '  GST ${item.gstRatePercent}%' : ''}',
                    formatPaise(item.totalPaise),
                    size: size,
                  ),
                  if (o.showHsn && item.hsnCode != null)
                    _text(
                      'HSN/SAC ${item.hsnCode}',
                      size: size - 1,
                      color: PdfColors.grey700,
                    ),
                ],
              ),
            ),
          rule(),
          for (final r in rows)
            _kv(r.label, formatPaise(r.paise), size: size),
          _kv(
            'TOTAL',
            formatPaise(invoice.grandTotalPaise),
            size: size + 3,
            bold: true,
          ),
          if (d.chargesTax && invoice.pricesIncludeTax)
            center('Rates are inclusive of GST.', fontSize: size - 1),
          if (o.showTaxSummary && d.chargesTax && invoice.taxPaise > 0) ...[
            rule(),
            for (final r in taxRows)
              _text(
                '${r.hsnCode.isEmpty ? 'GST' : r.hsnCode} @${r.ratePercent}%: '
                'taxable ${formatPaise(r.taxablePaise)}, tax ${formatPaise(r.taxPaise)}',
                size: size - 1,
              ),
          ],
          if (o.showAmountInWords) ...[
            rule(),
            _text(
              amountInWordsInr(invoice.grandTotalPaise),
              size: size - 0.5,
            ),
          ],
          if (d.payments.isNotEmpty || invoice.duePaise > 0) ...[
            rule(),
            ..._paymentLines(d, size: size),
          ],
          if (d.declaration != null) ...[
            rule(),
            center(d.declaration!, fontSize: size - 1),
          ],
          if (o.showPaymentInstructions && payment != null) ...[
            rule(),
            _text(payment, size: size - 0.5),
          ],
          if (o.showFooter && footer != null) ...[
            rule(),
            center(footer, bold: true),
          ],
          pw.SizedBox(height: 6),
        ],
      ),
    ),
  );
}