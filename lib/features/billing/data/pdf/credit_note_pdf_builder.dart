import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:billforge/core/utils/date_format.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/core/utils/quantity.dart';
import 'package:billforge/features/billing/data/pdf/pdf_fonts.dart';
import 'package:billforge/features/billing/domain/credit_note.dart';
import 'package:billforge/features/billing/domain/totals_rows.dart';
import 'package:billforge/features/shop/domain/shop_profile.dart';

/// A4 credit note.
Future<Uint8List> buildCreditNotePdf({
  required ShopProfile shop,
  required CreditNoteDetail detail,
  required PdfFonts fonts,
}) {
  final note = detail.creditNote;
  final accent = PdfColor.fromInt(shop.primaryColorValue);
  final pdf = pw.Document(
    theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
    title: 'Credit note ${note.creditNoteNumber}',
    author: shop.name,
  );

  pw.Widget text(
    String value, {
    double size = 9,
    bool bold = false,
    PdfColor? color,
  }) => pw.Text(
    value,
    style: pw.TextStyle(
      fontSize: size,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color,
    ),
  );

  pw.Widget cell(String value, {bool right = false, bool bold = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: pw.Align(
          alignment: right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
          child: text(value, size: 8.5, bold: bold),
        ),
      );

  pw.Widget kv(
    String label,
    String value, {
    bool bold = false,
    double size = 9,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        text(label, bold: bold, size: size),
        text(value, bold: bold, size: size),
      ],
    ),
  );

  final totals = buildTotalsRows(
    discountPaise: 0,
    taxablePaise: note.taxablePaise,
    cgstPaise: note.cgstPaise,
    sgstPaise: note.sgstPaise,
    igstPaise: note.igstPaise,
    roundOffPaise: note.roundOffPaise,
  );

  final address = [
    shop.addressLine1,
    if (shop.addressLine2 != null) shop.addressLine2!,
    '${shop.city}, ${shop.state} - ${shop.pincode}',
  ];

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.copyWith(
        marginTop: 32,
        marginBottom: 32,
        marginLeft: 32,
        marginRight: 32,
      ),
      build: (context) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  text(shop.name, size: 16, bold: true),
                  for (final line in address) text(line),
                  text('Phone: ${shop.phone}'),
                  if (shop.gstin != null) text('GSTIN: ${shop.gstin}'),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                text('CREDIT NOTE', size: 16, bold: true, color: accent),
                pw.SizedBox(height: 4),
                text('No: ${note.creditNoteNumber}', bold: true),
                text('Date: ${formatDate(note.issuedAt)}'),
                text('Against invoice: ${note.invoiceNumber}'),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: accent, thickness: 1.2),
        pw.SizedBox(height: 6),
        text('CUSTOMER', size: 8, color: PdfColors.grey700, bold: true),
        text(note.customerName ?? 'Walk-in customer', bold: true),
        if (note.customerPhone != null) text(note.customerPhone!),
        if (note.customerGstin != null) text('GSTIN: ${note.customerGstin}'),
        text('Place of supply: ${note.placeOfSupply}'),
        pw.SizedBox(height: 4),
        text(
          'Reason: ${note.reason.label}${note.note == null ? '' : ' (${note.note})'}',
        ),
        pw.SizedBox(height: 14),
        pw.Table(
          columnWidths: const {
            0: pw.FixedColumnWidth(22),
            1: pw.FlexColumnWidth(4),
            2: pw.FixedColumnWidth(60),
            3: pw.FixedColumnWidth(70),
            4: pw.FixedColumnWidth(36),
            5: pw.FixedColumnWidth(72),
          },
          border: const pw.TableBorder(
            top: pw.BorderSide(color: PdfColors.grey500, width: 0.6),
            bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.6),
            horizontalInside: pw.BorderSide(
              color: PdfColors.grey300,
              width: 0.5,
            ),
          ),
          children: [
            pw.TableRow(
              repeat: true,
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                cell('#', bold: true),
                cell('Item', bold: true),
                cell('Qty', right: true, bold: true),
                cell('Taxable', right: true, bold: true),
                cell('GST', right: true, bold: true),
                cell('Amount', right: true, bold: true),
              ],
            ),
            for (var i = 0; i < detail.items.length; i++)
              pw.TableRow(
                children: [
                  cell('${i + 1}'),
                  cell(
                    detail.items[i].hsnCode == null
                        ? detail.items[i].name
                        : '${detail.items[i].name} (HSN ${detail.items[i].hsnCode})',
                  ),
                  cell(
                    '${formatMilli(detail.items[i].qtyMilli)} ${detail.items[i].unit.symbol}',
                    right: true,
                  ),
                  cell(formatPaise(detail.items[i].taxablePaise), right: true),
                  cell('${detail.items[i].gstRatePercent}%', right: true),
                  cell(formatPaise(detail.items[i].totalPaise), right: true),
                ],
              ),
          ],
        ),
        pw.SizedBox(height: 14),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.SizedBox(
            width: 230,
            child: pw.Column(
              children: [
                for (final r in totals) kv(r.label, formatPaise(r.paise)),
                pw.Divider(color: accent),
                kv(
                  'Credit note total',
                  formatPaise(note.totalPaise),
                  bold: true,
                  size: 12,
                ),
                if (note.appliedPaise > 0)
                  kv(
                    'Adjusted against balance',
                    formatPaise(note.appliedPaise),
                  ),
                if (note.refundPaise > 0)
                  kv(
                    'Refunded (${note.refundMethod?.label ?? 'Cash'})',
                    formatPaise(note.refundPaise),
                  ),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 30),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              text('For ${shop.name}', bold: true),
              pw.SizedBox(height: 36),
              text('Authorised signatory', size: 8, color: PdfColors.grey700),
            ],
          ),
        ),
      ],
    ),
  );
  return pdf.save();
}
