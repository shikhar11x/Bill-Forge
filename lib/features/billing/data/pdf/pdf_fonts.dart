import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

class PdfFonts {
  const PdfFonts({required this.regular, required this.bold});

  /// Helvetica ships inside the PDF library. It lacks the ₹ glyph, so it is
  /// for tests only.
  factory PdfFonts.builtIn() => PdfFonts(
        regular: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      );

  final pw.Font regular;
  final pw.Font bold;
}

/// Embeds the bundled Inter font so ₹ prints correctly, even offline.
Future<PdfFonts> loadPdfFonts() async {
  final regular = await rootBundle.load('assets/fonts/Inter-Regular.ttf');
  final bold = await rootBundle.load('assets/fonts/Inter-Bold.ttf');
  return PdfFonts(regular: pw.Font.ttf(regular), bold: pw.Font.ttf(bold));
}