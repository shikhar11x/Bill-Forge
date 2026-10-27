import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:billforge/features/billing/data/pdf/pdf_fonts.dart';
import 'package:billforge/features/reports/domain/report_models.dart';
import 'package:billforge/features/shop/domain/shop_profile.dart';

/// A4 PDF of any report: summary, every table, and the notes.
Future<Uint8List> buildReportPdf({
  required ShopProfile shop,
  required ReportDocument document,
  required PdfFonts fonts,
}) {
  final accent = PdfColor.fromInt(shop.primaryColorValue);
  final pdf = pw.Document(
    theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
    title: '${document.title} - ${document.periodLabel}',
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

  pw.Widget tableOf(ReportTable t) {
    final columns = t.columns;
    final footer = t.footer;
    return pw.Table(
      columnWidths: {
        for (var i = 0; i < columns.length; i++)
          i: i == 0 ? const pw.FlexColumnWidth(3) : const pw.FlexColumnWidth(2),
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
              cell(c.label, right: c.numeric, bold: true),
          ],
        ),
        for (final row in t.rows)
          pw.TableRow(
            children: [
              for (var i = 0; i < columns.length; i++)
                cell(row[i].text, right: columns[i].numeric),
            ],
          ),
        if (footer != null)
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              for (var i = 0; i < columns.length; i++)
                cell(footer[i].text, right: columns[i].numeric, bold: true),
            ],
          ),
      ],
    );
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.copyWith(
        marginTop: 32,
        marginBottom: 32,
        marginLeft: 32,
        marginRight: 32,
      ),
      footer: (context) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          text(shop.name, size: 8, color: PdfColors.grey600),
          text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            size: 8,
            color: PdfColors.grey600,
          ),
        ],
      ),
      build: (context) => [
        text(shop.name, size: 14, bold: true),
        pw.SizedBox(height: 2),
        text(document.title.toUpperCase(), size: 12, bold: true, color: accent),
        text(document.periodLabel),
        pw.SizedBox(height: 8),
        pw.Divider(color: accent, thickness: 1.2),
        pw.SizedBox(height: 8),
        if (document.metrics.isNotEmpty)
          pw.Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              for (final m in document.metrics)
                pw.Container(
                  width: 120,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, width: 0.6),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      text(m.label, size: 8, color: PdfColors.grey700),
                      pw.SizedBox(height: 2),
                      text(m.value.text, size: 11, bold: true),
                    ],
                  ),
                ),
            ],
          ),
        for (final section in document.sections) ...[
          pw.SizedBox(height: 16),
          text(section.title, size: 11, bold: true),
          pw.SizedBox(height: 4),
          tableOf(section.table),
        ],
        if (document.notes.isNotEmpty) pw.SizedBox(height: 14),
        for (final note in document.notes)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: text(note, size: 8, color: PdfColors.grey700),
          ),
      ],
    ),
  );
  return pdf.save();
}
