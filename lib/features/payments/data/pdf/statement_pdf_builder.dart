import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:billforge/core/utils/date_format.dart';
import 'package:billforge/core/utils/formatters.dart';
import 'package:billforge/features/billing/data/pdf/pdf_fonts.dart';
import 'package:billforge/features/customers/domain/customer.dart';
import 'package:billforge/features/payments/domain/statement.dart';
import 'package:billforge/features/shop/domain/shop_profile.dart';

/// A4 statement of account for one customer.
Future<Uint8List> buildStatementPdf({
  required ShopProfile shop,
  required Customer customer,
  required Statement statement,
  required PdfFonts fonts,
}) {
  final accent = PdfColor.fromInt(shop.primaryColorValue);
  final pdf = pw.Document(
    theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
    title: 'Statement - ${customer.name}',
    author: shop.name,
  );

  pw.Widget text(
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

  pw.Widget cell(String value, {bool right = false, bool bold = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: pw.Align(
          alignment: right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
          child: text(value, size: 8.5, bold: bold),
        ),
      );

  String money(int paise) => paise == 0 ? '-' : formatPaise(paise);

  final address = [
    shop.addressLine1,
    if (shop.addressLine2 != null) shop.addressLine2!,
    '${shop.city}, ${shop.state} - ${shop.pincode}',
  ];

  final header = pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            text(shop.name, size: 16, bold: true),
            pw.SizedBox(height: 3),
            for (final line in address) text(line),
            text('Phone: ${shop.phone}'),
            if (shop.gstin != null) text('GSTIN: ${shop.gstin}'),
          ],
        ),
      ),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          text('STATEMENT OF ACCOUNT', size: 14, bold: true, color: accent),
          pw.SizedBox(height: 4),
          text(statementPeriodLabel(statement)),
          text('Generated ${formatDate(DateTime.now())}'),
        ],
      ),
    ],
  );

  final party = pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      text('CUSTOMER', size: 8, color: PdfColors.grey700, bold: true),
      pw.SizedBox(height: 2),
      text(customer.name, bold: true),
      if (customer.phone != null) text(customer.phone!),
      if (customer.gstin != null) text('GSTIN: ${customer.gstin}'),
      if (customer.locationLabel.isNotEmpty) text(customer.locationLabel),
    ],
  );

  final table = pw.Table(
    columnWidths: const {
      0: pw.FixedColumnWidth(62),
      1: pw.FlexColumnWidth(4),
      2: pw.FixedColumnWidth(66),
      3: pw.FixedColumnWidth(66),
      4: pw.FixedColumnWidth(74),
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
          cell('Date', bold: true),
          cell('Particulars', bold: true),
          cell('Billed', right: true, bold: true),
          cell('Received', right: true, bold: true),
          cell('Balance', right: true, bold: true),
        ],
      ),
      pw.TableRow(
        children: [
          cell(''),
          cell('Opening balance', bold: true),
          cell(''),
          cell(''),
          cell(formatPaise(statement.openingPaise), right: true, bold: true),
        ],
      ),
      for (final e in statement.entries)
        pw.TableRow(
          children: [
            cell(formatDate(e.date)),
            cell(e.particulars),
            cell(money(e.debitPaise), right: true),
            cell(money(e.creditPaise), right: true),
            cell(formatPaise(e.balancePaise), right: true),
          ],
        ),
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          cell(''),
          cell('Closing balance (amount due)', bold: true),
          cell(formatPaise(statement.billedPaise), right: true, bold: true),
          cell(formatPaise(statement.receivedPaise), right: true, bold: true),
          cell(formatPaise(statement.closingPaise), right: true, bold: true),
        ],
      ),
    ],
  );

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
        child: text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          size: 8,
          color: PdfColors.grey600,
        ),
      ),
      build: (context) => [
        header,
        pw.SizedBox(height: 10),
        pw.Divider(color: accent, thickness: 1.2),
        pw.SizedBox(height: 6),
        party,
        pw.SizedBox(height: 14),
        table,
      ],
    ),
  );
  return pdf.save();
}